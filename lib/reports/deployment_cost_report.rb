module Reports
  class DeploymentCostReport
    attr_reader :costs, :clouds
    def initialize(report)
      @report        = report
      @user_currency = @report.user.currency
      Time.zone = @report.user.timezone
      @deployment    = @report.reportable
      @costs         = []
      # Cache all clouds to avoid individual DB calls during calculations
      @clouds        = {}
      Cloud.all.each{|c| @clouds[c.id] = c}

      current_date = @report.start_date
      while current_date <= @report.end_date
        @costs << {:timestamp       => current_date,
                   :year            => current_date.strftime("%Y"),
                   :month           => current_date.strftime("%b-%Y"),
                   :instance_hour   => 0.0,
                   :storage_size    => 0.0,
                   :read_request    => 0.0,
                   :write_request   => 0.0,
                   :transaction     => 0.0,
                   :data_in         => 0.0,
                   :data_out        => 0.0,
                   :additional_cost => 0.0}
        current_date += 1.months
      end
    end

    def xml
      do_servers_storages_database_resources
      do_data_transfers
      do_additional_costs
      cost = 0.0
      deployment = ""
      @costs.each do |month|
        monthly_cost = (month[:instance_hour] + month[:storage_size] + month[:read_request] + month[:write_request] +
                month[:transaction] + month[:data_in] + month[:data_out] + month[:additional_cost]).round(2)
        cost += monthly_cost
        deployment << "<row>" +
            "<year>#{month[:year]}</year>" +
            "<month>#{month[:month]}</month>" +
            "<instance_hour>#{month[:instance_hour].round(2)}</instance_hour>" +
            "<storage_size>#{month[:storage_size].round(2)}</storage_size>" +
            "<read_request>#{month[:read_request].round(2)}</read_request>" +
            "<write_request>#{month[:write_request].round(2)}</write_request>" +
            "<transaction>#{month[:transaction].round(2)}</transaction>" +
            "<data_in>#{month[:data_in].round(2)}</data_in>" +
            "<data_out>#{month[:data_out].round(2)}</data_out>" +
            "<additional_cost>#{month[:additional_cost].round(2)}</additional_cost>" +
            "<total>#{monthly_cost}</total>" +
            "</row>"
      end

      @deployment.cost = cost.round(2)
      @deployment.save
      xml = "<deployment>"
      xml << "<user_currency>#{Money::Currency::TABLE.select{|k,v| v[:iso_code] == @user_currency}.values.first[:name]} (#{@user_currency})</user_currency>"
      xml << "<cost>#{@deployment.cost}</cost>"
      xml << "#{deployment}</deployment>"
      xml
    end

    def do_additional_costs
      @deployment.additional_costs.all(:include => :patterns).each do |additional_cost|
        # Get the values from the patterns
        additional_cost_values = get_monthly_values(additional_cost, 'cost')
        @costs.each_with_index do |month, i|
          month[:additional_cost] += additional_cost_values[i].to_f
        end
      end
    end

    # Algorithm:
    #data_in_for_clouds = {}
    #data_out_for_clouds = {}
    #Go through all data links
    #  get_source/dest_clouds
    #  if source and target are on diff clouds or either are a remote_node
    #    add source_to_dest data to source-clouds data_out unless source is remote_node
    #    add source_to_dest data to desti-clouds data_in unless desti is remote_node
    #
    #    add dest_to_source data to dest-clouds data_out unless desti is remote_node
    #    add dest_to_source data to source-clouds data_in unless source is remote_node
    #  end
    #
    # Get the CCS with cloud_id and cloud_resource_type_id nil
    # Go through it and find the data_in/out struct.
    # Calculate data_in/data_out costs for each cloud based on tiers
    def do_data_transfers
      data_transfer = { 'data_in' => {}, 'data_out' => {}}
      @deployment.data_links.all(:include => [:sourcable, :targetable, :patterns]).each do |data_link|
        src        = data_link.sourcable
        src_cloud  = src.is_a?(RemoteNode) ? 'remote' : data_link.sourcable.cloud_id
        dest       = data_link.targetable
        dest_cloud = dest.is_a?(RemoteNode) ? 'remote' : data_link.targetable.cloud_id

        if src_cloud != dest_cloud
          src_to_dest_values = get_monthly_values(data_link, 'source_to_target')
          dest_to_src_values = get_monthly_values(data_link, 'target_to_source')

          # Protect users from creating stupid patterns that set values to less than 0
          @costs.each_with_index do |month, i|
            src_to_dest_values[i] = 0 if src_to_dest_values[i] < 0
            dest_to_src_values[i] = 0 if dest_to_src_values[i] < 0
          end

          data_transfer['data_in'][src_cloud] ||= Array.new(@costs.length){0}
          data_transfer['data_out'][src_cloud] ||= Array.new(@costs.length){0}
          data_transfer['data_in'][dest_cloud] ||= Array.new(@costs.length){0}
          data_transfer['data_out'][dest_cloud] ||= Array.new(@costs.length){0}

          # add src_to_dest data to source-clouds data_out
          data_transfer['data_out'][src_cloud]  = data_transfer['data_out'][src_cloud].zip(src_to_dest_values).map{|pair| pair.sum}
          # add src_to_dest data to dest-clouds data_in
          data_transfer['data_in'][dest_cloud]  = data_transfer['data_in'][dest_cloud].zip(src_to_dest_values).map{|pair| pair.sum}

          # add dest_to_source data to dest-clouds data_out
          data_transfer['data_out'][dest_cloud] = data_transfer['data_out'][dest_cloud].zip(dest_to_src_values).map{|pair| pair.sum}
          # add dest_to_source data to source-clouds data_in
          data_transfer['data_in'][src_cloud]   = data_transfer['data_in'][src_cloud].zip(dest_to_src_values).map{|pair| pair.sum}
        end
      end

      # Delete RemoteNode placeholders from hash as they are not clouds
      data_transfer.each{|k, v| v.delete('remote')}

      data_transfer.each do |k, v|
        v.each do |cloud_id, values|
          cloud = @clouds[cloud_id]
          first_server_type = ServerType.first(:include => [:clouds], :conditions => ["clouds.id = ?", cloud_id])
          if first_server_type
            price_details = get_price_details(cloud.id, first_server_type.id, k)

            unless price_details.empty?
              @costs.each_with_index do |month, i|
                cost = get_tiered_cost(values[i], price_details[:units], price_details[:tiers])
                cost += price_details[:recurring_cost_values][i]
                month[k.to_sym] += cost.to_money(cloud.billing_currency).exchange_to(@user_currency).to_f
              end
            end
          end
        end
      end
    end

    # Algorithm:
    # Calculate the monthly_total usages (value * quantity) of each CloudResourceType in the deployment
    # This is the structure of depl_resource_types hash:
    #   [CloudResourceType.id][Cloud.id][CloudCostStructure.name][:values] = array_of_monthly_totals
    #   [CloudResourceType.id][Cloud.id][CloudCostStructure.name][:quantity_values] = array_of_monthly_quantity
    # Go through all CloudResourceTypes
    #   Go through all of the Clouds
    #     Go through all of the CloudCostStructures
    #       Go through all of the monthly_totals
    #         Calculate the tiered cost of that month including any recurring_costs for that CloudCostStructure
    #         Convert the cost from Cloud billing_currency to user_currency and add it to the @costs array for that month
    def do_servers_storages_database_resources
      depl_resource_types = {}
      (@deployment.servers.all(:include => :patterns) + @deployment.storages.all(:include => :patterns) +
          @deployment.database_resources.all(:include => :patterns)).each do |resource|
        cloud = @clouds[resource.cloud_id]
        depl_resource_type_id = case resource.class.to_s
                                  when 'Server'
                                    resource.server_type_id
                                  when 'Storage'
                                    resource.storage_type_id
                                  when 'DatabaseResource'
                                    resource.database_type_id
                                end
        depl_resource_types[depl_resource_type_id] ||= {}
        depl_resource_types[depl_resource_type_id][cloud.id] ||= {}

        ['instance_hour', 'transaction', 'storage_size', 'read_request', 'write_request'].each do |ccs_name|
          # Skip this ccs_name if the resource doesn't have it
          next unless resource.respond_to?("#{ccs_name}_monthly_baseline")

          values = get_monthly_values(resource, ccs_name)
          quantity_values = get_monthly_values(resource, 'quantity')

          depl_resource_types[depl_resource_type_id][cloud.id][ccs_name] ||= {}
          depl_resource_types[depl_resource_type_id][cloud.id][ccs_name][:values] ||= Array.new(@costs.length){0}
          depl_resource_types[depl_resource_type_id][cloud.id][ccs_name][:quantity_values] ||= Array.new(@costs.length){0}
          @costs.each_with_index do |month, i|
            # A month has max number of hours, enforce this in case user patterns accidentally make it go over this value
            if ccs_name == 'instance_hour'
              hours_in_month = 24 * Time.days_in_month(month[:timestamp].month, month[:timestamp].year)
              values[i] = hours_in_month if values[i] > hours_in_month
            end
            # Protect users from creating stupid patterns that set values to less than 0
            values[i] = 0 if values[i] < 0
            quantity_values[i] = 0 if quantity_values[i] < 0

            depl_resource_types[depl_resource_type_id][cloud.id][ccs_name][:values][i]          += (values[i] * quantity_values[i])
            depl_resource_types[depl_resource_type_id][cloud.id][ccs_name][:quantity_values][i] += quantity_values[i]
          end
        end
      end

      depl_resource_types.each do |depl_resource_type_id, cloud_ids|
        cloud_ids.each do |cloud_id, ccs_names|
          cloud = @clouds[cloud_id]
          ccs_names.each do |ccs_name, values_hash|
            price_details = get_price_details(cloud_id, depl_resource_type_id, ccs_name)

            unless price_details.empty?
              if price_details[:custom_algorithm]
                self.send("do_#{price_details[:custom_algorithm]}")
              else
                @costs.each_with_index do |month, i|
                  # No need to multiply the quantity again as values[i] already has the total usage
                  usage = values_hash[:values][i]
                  cost = get_tiered_cost(usage, price_details[:units], price_details[:tiers])
                  recurring_cost = price_details[:recurring_cost_values][i] * values_hash[:quantity_values][i]
                  total_cost = cost + recurring_cost
                  month[ccs_name.to_sym] += total_cost.to_money(cloud.billing_currency).exchange_to(@user_currency).to_f
                end
              end
            end
          end
        end
      end
    end

    # Custom algorithm for SQL Azure costs:
    # Go though all database_resources in deployment
    #   Get storage_size, instance_hour and quantity values
    #   Go through all monthly_values
    #     Validate values
    #     Calculate tiered cost
    #     Calculate recurring cost
    #     Add total_cost to monthly cost
    def do_sql_azure
      @deployment.database_resources.all(:include => :patterns).each do |resource|
        cloud = @clouds[resource.cloud_id]
        price_details = get_price_details(resource.cloud_id, resource.database_type_id, 'storage_size')

        storage_size_values = get_monthly_values(resource, 'storage_size')
        instance_hour_values = get_monthly_values(resource, 'instance_hour')
        quantity_values = get_monthly_values(resource, 'quantity')

        @costs.each_with_index do |month, i|
          # Protect users from creating stupid patterns that set invalid values
          days_in_month = Time.days_in_month(month[:timestamp].month, month[:timestamp].year)
          hours_in_month = 24 * days_in_month
          instance_hour_values[i] = hours_in_month if instance_hour_values[i] > hours_in_month
          instance_hour_values[i] = 0 if instance_hour_values[i] < 0
          storage_size_values[i] = 0 if storage_size_values[i] < 0
          quantity_values[i] = 0 if quantity_values[i] < 0

          if instance_hour_values[i] == 0
            cost = 0
          else
            # Amortize storage_size cost over the days that storage was used in that month
            cost = get_tiered_cost(storage_size_values[i], price_details[:units], price_details[:tiers]) *
                ((instance_hour_values[i] / 24).ceil / days_in_month.to_f)
          end
          cost *= quantity_values[i]
          recurring_cost = price_details[:recurring_cost_values][i] * quantity_values[i]
          total_cost = cost + recurring_cost
          month[:instance_hour] += total_cost.to_money(cloud.billing_currency).exchange_to(@user_currency).to_f
        end
      end
    end

    # Returns a hash that has the custom_algorithm, tiers, units, recurring_costs of the cloud_cost_structure name
    # for the specified resource_type in the specified cloud
    def get_price_details(cloud_id, cloud_resource_type_id, ccs_name)
      results = {}

      # Find all CloudCostSchemes in the cloud
      ccs = CloudCostScheme.all(
          :conditions => ["cloud_id = ? AND cloud_resource_type_id = ?", cloud_id, cloud_resource_type_id],
          :include => :cloud_cost_structure) # Don't include tiers as we need to order them and we can't do it here

      # Find relevant CloudCostStructures (i.e. they match the name and are still valid)
      price_type_ccs = ccs.select{|c| c.cloud_cost_structure.name == ccs_name && c.cloud_cost_structure.valid_until.nil?}.first
      if price_type_ccs
        price_type_ccs = price_type_ccs.cloud_cost_structure
        results[:custom_algorithm] = price_type_ccs.custom_algorithm
        results[:tiers] = price_type_ccs.cloud_cost_tiers.order("upto ASC") # Get all the tiers, we'll process them later

        price_type_ccs.units =~ /\Aper\.(\d+)\..*\z/i
        results[:units] = $1.to_f

        results[:recurring_cost_values] = get_monthly_values(price_type_ccs, 'recurring_costs')
      end

      results
    end

    # The cost_units is the value of X in the units field, e.g. per.X.requests
    def get_tiered_cost(total_usage, cost_units, ordered_tiers)
      raise AppExceptions::InvalidParameter.new("ordered_tiers cannot be empty") if ordered_tiers && ordered_tiers.empty?
      total_usage = total_usage.to_f # force into float to make sure .ceil works as expected
      cost = 0.0
      i = 0
      while total_usage > 0
        usage = total_usage
        if ordered_tiers[i].upto
          # If total_usage is less than upto then use that, otherwise calculate
          # the diff between this tier and the last tier (if there is one)
          usage = [total_usage, ordered_tiers[i].upto - (i > 0 ? ordered_tiers[i-1].upto : 0)].min
        end
        total_usage -= usage
        cost += (usage / cost_units).ceil * ordered_tiers[i].cost
        i += 1
        # Deal with special case when there is no catch-all tier (upto nil), shouldn't happen in practice
        return cost if i == ordered_tiers.length
      end
      cost
    end

    # Since the resource includes its patterns, this method of getting the patterns is more efficient that
    # going through the resource.get_patterns method
    def get_sorted_patterns(resource, attribute)
      patterns = resource.pattern_maps.select{|pm| pm.patternable_attribute == attribute}
      patterns.sort_by{|pm| pm.position}
      patterns = patterns.collect{|pm| pm.pattern}
      patterns
    end

    # Helper method to get monthly values for an attribute of resource
    def get_monthly_values(resource, attribute)
      PatternsEngine.get_monthly_results(resource.send("#{attribute}_monthly_baseline"),
                                         get_sorted_patterns(resource, "#{attribute}_monthly_baseline"),
                                         @report.start_date, @report.end_date)
    end
  end
end
