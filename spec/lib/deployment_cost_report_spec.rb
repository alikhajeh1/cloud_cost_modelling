require 'spec_helper'

describe Reports::DeploymentCostReport do
  before(:all) do
    @user = User.make!(:currency => 'USD', :timezone => 'Edinburgh')
    # The timezone is set in the application_controller during user requests, we do the same thing here
    Time.zone = @user.timezone
  end

  context "basic methods" do
    before(:all) do
      @deployment = Deployment.make!(:user => @user)
      @report = Report.make!(:user => @user, :reportable => @deployment,
                             :start_date => '2012-01-01', :end_date => '2012-03-01')
      @cost_report = Reports::DeploymentCostReport.new(@report)
    end

    it "should initialize correctly" do
      @cost_report.costs.length.should == 3
      @cost_report.clouds.length.should == Cloud.count
      @cost_report.costs[0][:month].should == 'Jan-2012'
      @cost_report.costs[1][:month].should == 'Feb-2012'
      @cost_report.costs[2][:month].should == 'Mar-2012'
    end

    it "should do_additional_costs and xml correctly" do
      pattern = @user.patterns.create!(:name => 'additional cost pattern')
      rule = @user.rules.new(:rule_type => 'permanent', :year => 'every.1.year', :month => 'every.1.month', :variation => '+', :value => 2)
      rule.pattern = pattern
      rule.save!
      additional_cost = AdditionalCost.make!(:user => @user, :cost_monthly_baseline => 10)
      additional_cost.add_patterns('cost_monthly_baseline', [pattern])
      @deployment.additional_costs << additional_cost

      @cost_report.xml.should == "<deployment><user_currency>United States Dollar (USD)</user_currency><cost>42.0</cost><row><year>2012</year><month>Jan-2012</month><instance_hour>0.0</instance_hour><storage_size>0.0</storage_size><read_request>0.0</read_request><write_request>0.0</write_request><transaction>0.0</transaction><data_in>0.0</data_in><data_out>0.0</data_out><additional_cost>12.0</additional_cost><total>12.0</total></row><row><year>2012</year><month>Feb-2012</month><instance_hour>0.0</instance_hour><storage_size>0.0</storage_size><read_request>0.0</read_request><write_request>0.0</write_request><transaction>0.0</transaction><data_in>0.0</data_in><data_out>0.0</data_out><additional_cost>14.0</additional_cost><total>14.0</total></row><row><year>2012</year><month>Mar-2012</month><instance_hour>0.0</instance_hour><storage_size>0.0</storage_size><read_request>0.0</read_request><write_request>0.0</write_request><transaction>0.0</transaction><data_in>0.0</data_in><data_out>0.0</data_out><additional_cost>16.0</additional_cost><total>16.0</total></row></deployment>"
      @deployment.reload.cost.should == 42.0
    end

    context "get_price_details" do
      before(:all) do
        @cloud = Cloud.find_by_name('Test Cloud 1')
        @storage_type = StorageType.find_by_name('Test StorageType 1')
      end

      it "should return the correct details if there is no CCS name" do
        @cost_report.get_price_details(@cloud.id, @storage_type.id, 'non_existent_name').should == {}
      end

      it "should return the correct details for a resource with no recurring costs" do
        details = @cost_report.get_price_details(@cloud.id, @storage_type.id, 'storage_size')

        details[:tiers].count.should == 1
        details[:tiers].first.cost.should == 0.3
        details[:units].should == 1.0
        details[:recurring_cost_values].should == [0.0, 0.0, 0.0]
      end

      it "should return the correct details for a resource with multiple tiers (ordered correctly)" do
        report = Report.make!(:user => @user, :reportable => @deployment,
                              :start_date => '2012-01-01', :end_date => '2014-12-01')
        cost_report = Reports::DeploymentCostReport.new(report)
        details = cost_report.get_price_details(Cloud.find_by_name('Test Cloud 2').id,
                                                StorageType.find_by_name('Test StorageType 2').id,
                                                'storage_size')

        details[:tiers].count.should == 4
        details[:tiers][0].upto.should == 30
        details[:tiers][0].cost.should == 0.5
        details[:tiers][1].upto.should == 45
        details[:tiers][1].cost.should == 0.6
        details[:tiers][2].upto.should == 70
        details[:tiers][2].cost.should == 0.7
        details[:tiers][3].upto.should == nil
        details[:tiers][3].cost.should == 0.01
        details[:units].should == 1.0
        details[:recurring_cost_values].should == Array.new(36){0.0}
      end

      it "should return the correct details for a resource with recurring costs" do
        report = Report.make!(:user => @user, :reportable => @deployment,
                              :start_date => '2012-01-01', :end_date => '2014-12-01')
        cost_report = Reports::DeploymentCostReport.new(report)
        details = cost_report.get_price_details(Cloud.find_by_name('Test Cloud 2').id,
                                                ServerType.find_by_name('Test ServerType 2').id,
                                                'instance_hour')

        details[:tiers].count.should == 1
        details[:tiers][0].upto.should == nil
        details[:tiers][0].cost.should == 0
        details[:units].should == 1.0
        details[:recurring_cost_values].should == [110.0] + Array.new(11){10.0} +
            [110.0] + Array.new(11){10.0} +
            [110.0] + Array.new(11){10.0}
      end

    end

    it 'get_sorted_patterns should return patterns in the same order as resource.get_patterns method' do
      p1 = @user.patterns.create!(:name => 'p1')
      p2 = @user.patterns.create!(:name => 'p2')
      p3 = @user.patterns.create!(:name => 'p3')
      p4 = @user.patterns.create!(:name => 'p4')
      additional_cost = AdditionalCost.make!(:user => @user, :cost_monthly_baseline => 10)

      @cost_report.get_sorted_patterns(additional_cost, 'cost_monthly_baseline').should == []

      additional_cost.add_patterns('cost_monthly_baseline', [p3, p2, p1, p4])
      additional_cost.reload
      @cost_report.get_sorted_patterns(additional_cost, 'cost_monthly_baseline').should == additional_cost.get_patterns('cost_monthly_baseline')
    end

    context 'get_tiered_cost' do
      it 'should raise exception if called with no tiers' do
        lambda {@cost_report.get_tiered_cost(0, 1, [])}.should raise_error
      end

      it 'should return the correct cost if there is only 1 tier and it has a cost of 0' do
        t1 = CloudCostTier.new(:cost => 0)
        @cost_report.get_tiered_cost(0, 1, [t1]).should == 0
        @cost_report.get_tiered_cost(10, 1, [t1]).should == 0
      end

      it 'should return the correct cost if there is only 1 tier' do
        t1 = CloudCostTier.new(:cost => 0.1)
        @cost_report.get_tiered_cost(10, 1, [t1]).should == 10 * 0.1
      end

      it 'should return the correct cost if there is only 1 tier with upto' do
        t1 = CloudCostTier.new(:upto => 100, :cost => 0.1)
        @cost_report.get_tiered_cost(10, 1, [t1]).should == 1
      end

      it 'should return the correct cost if there is only 1 tier with upto but total_usage is bigger than upto' do
        t1 = CloudCostTier.new(:upto => 100, :cost => 0.1)
        @cost_report.get_tiered_cost(200, 1, [t1]).should == (100 * 0.1)
      end

      it 'should return the correct cost if there are multiple tier with upto but total_usage is bigger than upto' do
        tiers = [CloudCostTier.new(:upto => 100, :cost => 0.1),
                 CloudCostTier.new(:upto => 200, :cost => 0.2),
                 CloudCostTier.new(:upto => 300, :cost => 0.3)]
        @cost_report.get_tiered_cost(500, 1, tiers).should == (100 * 0.1 + 100 * 0.2 + 100 * 0.3)
      end

      it 'should return the correct cost if there are multiple tiers and the total_usage only uses the first tier' do
        tiers = [CloudCostTier.new(:upto => 100, :cost => 0.1),
                 CloudCostTier.new(:upto => 200, :cost => 0.2),
                 CloudCostTier.new(:cost => 0.3)]
        @cost_report.get_tiered_cost(10, 1, tiers).should == 1
      end

      it 'should return the correct cost if there are multiple tiers and the total usage is rounded up (.ciel)' do
        tiers = [CloudCostTier.new(:upto => 100, :cost => 0.1),
                 CloudCostTier.new(:cost => 0.2)]
        @cost_report.get_tiered_cost(50, 60, tiers).should == 0.1
      end

      it 'should return the correct cost if there are multiple tiers with a max last tier' do
        tiers = [CloudCostTier.new(:upto => 100, :cost => 0.1),
                 CloudCostTier.new(:upto => 200, :cost => 0.2),
                 CloudCostTier.new(:cost => 0)]
        @cost_report.get_tiered_cost(300, 1, tiers).should == (100 * 0.1 + 100 * 0.2)
      end

      it 'should return the correct cost if there are multiple tiers' do
        tiers = [CloudCostTier.new(:upto => 100, :cost => 0.1),
                 CloudCostTier.new(:upto => 250, :cost => 0.2),
                 CloudCostTier.new(:upto => 500, :cost => 0.3),
                 CloudCostTier.new(:cost => 0.4)]
        @cost_report.get_tiered_cost(1000, 1, tiers).should == (100 * 0.1 + 150 * 0.2 + 250 * 0.3 + 500 * 0.4)
      end
    end

  end

  context "do_data_transfers" do
    before(:each) do
      @deployment = Deployment.make!(:user => @user)
      @report = Report.make!(:user => @user, :reportable => @deployment,
                             :start_date => '2012-01-01', :end_date => '2012-03-01')
      @cost_report = Reports::DeploymentCostReport.new(@report)
      @params = {:user => @user, :deployment => @deployment}
    end

    it "should set the correct cost for cloud-remote node data transfer if pattern makes value less than 0" do
      server1 = Server.make!(@params.merge(:server_type => ServerType.find_by_name('Test ServerType 1'),
                                           :cloud => Cloud.find_by_name('Test Cloud 1')))
      remote_node = RemoteNode.make!(@params)
      pattern = Pattern.make!(:user => @user)
      rule = Rule.new(:rule_type => 'Temporary', :year => 'every.1.year', :month => 'mar', :variation => '-', :value => 100)
      rule.pattern = pattern
      rule.save!
      dl = DataLink.make!(@params.merge(:sourcable => remote_node, :targetable => server1,
                                        :source_to_target_monthly_baseline => 5,:target_to_source_monthly_baseline => 10))
      dl.add_patterns('source_to_target_monthly_baseline', [pattern])
      dl.add_patterns('target_to_source_monthly_baseline', [pattern])

      @cost_report.xml.should_not be_nil
      @cost_report.costs.length.should == 3
      # Prices are taken from cloud_maker
      data_in_cost = 5 * 0.2
      data_out_cost = 10 * 0.1
      @cost_report.costs.collect{|c| c[:data_in]}.should == [data_in_cost, data_in_cost, 0.0]
      @cost_report.costs.collect{|c| c[:data_out]}.should == [data_out_cost, data_out_cost, 0.0]
    end

    it "should set the correct cost for same cloud data transfer" do
      server1 = Server.make!(@params.merge(:server_type => ServerType.find_by_name('Test ServerType 1'),
                                           :cloud => Cloud.find_by_name('Test Cloud 1')))
      server2 = Server.make!(@params.merge(:server_type => ServerType.find_by_name('Test ServerType 1'),
                                           :cloud => Cloud.find_by_name('Test Cloud 1')))
      DataLink.make!(@params.merge(:sourcable => server1, :targetable => server2))

      @cost_report.xml.should_not be_nil
      @cost_report.costs.length.should == 3
      @cost_report.costs.collect{|c| c[:data_in]}.should == [0.0, 0.0, 0.0]
      @cost_report.costs.collect{|c| c[:data_out]}.should == [0.0, 0.0, 0.0]
    end

    it "should set the correct cost for different cloud data transfer" do
      server1 = Server.make!(@params.merge(:server_type => ServerType.find_by_name('Test ServerType 1'),
                                           :cloud => Cloud.find_by_name('Test Cloud 1')))
      server2 = Server.make!(@params.merge(:server_type => ServerType.find_by_name('Test ServerType 2'),
                                           :cloud => Cloud.find_by_name('Test Cloud 2')))
      DataLink.make!(@params.merge(:sourcable => server1, :targetable => server2,
                                   :source_to_target_monthly_baseline => 5,
                                   :target_to_source_monthly_baseline => 10))

      @cost_report.xml.should_not be_nil
      @cost_report.costs.length.should == 3
      # Prices are taken from cloud_maker
      data_in_cost = (10 * 0.2 + 5 * 0)
      data_out_cost = (5 * 0.1 + 10 * 0.01)
      @cost_report.costs.collect{|c| c[:data_in]}.should == Array.new(3){data_in_cost}
      @cost_report.costs.collect{|c| c[:data_out]}.should == Array.new(3){data_out_cost}
    end

    it "should set the correct cost for different cloud data transfer with patterns and tiers" do
      server1 = Server.make!(@params.merge(:server_type => ServerType.find_by_name('Test ServerType 1'),
                                           :cloud => Cloud.find_by_name('Test Cloud 1')))
      server2 = Server.make!(@params.merge(:server_type => ServerType.find_by_name('Test ServerType 2'),
                                           :cloud => Cloud.find_by_name('Test Cloud 2')))
      pattern = Pattern.make!(:user => @user)
      rule = Rule.new(:rule_type => 'permanent', :year => 'every.1.year', :month => 'every.1.month',
                      :variation => '*', :value => 2)
      rule.pattern = pattern
      rule.save!
      dl = DataLink.make!(@params.merge(:sourcable => server1, :targetable => server2,
                                        :source_to_target_monthly_baseline => 50,
                                        :target_to_source_monthly_baseline => 100))
      dl.add_patterns('source_to_target_monthly_baseline', [pattern])
      dl.add_patterns('target_to_source_monthly_baseline', [pattern])

      @cost_report.xml.should_not be_nil
      @cost_report.costs.length.should == 3
      # Prices are taken from cloud_maker
      data_in_costs = [200 * 0.2 + 50 * 0 + 25 * 0.03 + 25 * 0.04,
                       400 * 0.2 + 50 * 0 + 25 * 0.03 + 125 * 0.04,
                       800 * 0.2 + 50 * 0 + 25 * 0.03 + 325 * 0.04]
      data_out_costs = [100 * 0.1 + 100 * 0.01 + 100 * 0.02,
                        200 * 0.1 + 100 * 0.01 + 100 * 0.02 + 200 * 0.3,
                        400 * 0.1 + 100 * 0.01 + 100 * 0.02 + 600 * 0.3]
      @cost_report.costs.collect{|c| c[:data_in]}.should == data_in_costs
      @cost_report.costs.collect{|c| c[:data_out]}.should == data_out_costs
    end

    it "should set the correct cost for cloud-remote node data transfer" do
      server1 = Server.make!(@params.merge(:server_type => ServerType.find_by_name('Test ServerType 1'),
                                           :cloud => Cloud.find_by_name('Test Cloud 1')))
      remote_node = RemoteNode.make!(@params)
      DataLink.make!(@params.merge(:sourcable => remote_node, :targetable => server1,
                                   :source_to_target_monthly_baseline => 5,
                                   :target_to_source_monthly_baseline => 10))

      @cost_report.xml.should_not be_nil
      @cost_report.costs.length.should == 3
      # Prices are taken from cloud_maker
      data_in_cost = 5 * 0.2
      data_out_cost = 10 * 0.1
      @cost_report.costs.collect{|c| c[:data_in]}.should == Array.new(3){data_in_cost}
      @cost_report.costs.collect{|c| c[:data_out]}.should == Array.new(3){data_out_cost}
    end

    it "should set the correct cost for cloud-remote node data transfer when cloud has no data_transfer costs" do
      server1 = Server.make!(@params.merge(:server_type => ServerType.make!, :cloud => Cloud.find_by_name('Empty Cloud')))
      remote_node = RemoteNode.make!(@params)
      DataLink.make!(@params.merge(:sourcable => remote_node, :targetable => server1,
                                   :source_to_target_monthly_baseline => 5,
                                   :target_to_source_monthly_baseline => 10))

      @cost_report.xml.should_not be_nil
      @cost_report.costs.length.should == 3
      @cost_report.costs.collect{|c| c[:data_in]}.should == Array.new(3){0.0}
      @cost_report.costs.collect{|c| c[:data_out]}.should == Array.new(3){0.0}
    end

    it "should set the correct cost for remote node to remote node data transfer" do
      remote_node1 = RemoteNode.make!(@params)
      remote_node2 = RemoteNode.make!(@params)
      DataLink.make!(@params.merge(:sourcable => remote_node1, :targetable => remote_node2,
                                   :source_to_target_monthly_baseline => 5,
                                   :target_to_source_monthly_baseline => 10))

      @cost_report.xml.should_not be_nil
      @cost_report.costs.length.should == 3
      @cost_report.costs.collect{|c| c[:data_in]}.should == Array.new(3){0.0}
      @cost_report.costs.collect{|c| c[:data_out]}.should == Array.new(3){0.0}
    end

    it "should set the correct cost for complicated scenario" do
      c1_server1 = Server.make!(@params.merge(:server_type => ServerType.find_by_name('Test ServerType 1'),
                                              :cloud => Cloud.find_by_name('Test Cloud 1')))
      c2_server2 = Server.make!(@params.merge(:server_type => ServerType.find_by_name('Test ServerType 2'),
                                              :cloud => Cloud.find_by_name('Test Cloud 2')))
      DataLink.make!(@params.merge(:sourcable => c1_server1, :targetable => c2_server2,
                                   :source_to_target_monthly_baseline => 5,
                                   :target_to_source_monthly_baseline => 10))

      c1_server1 = Server.make!(@params.merge(:server_type => ServerType.find_by_name('Test ServerType 1'),
                                              :cloud => Cloud.find_by_name('Test Cloud 1')))
      c2_server2 = Server.make!(@params.merge(:server_type => ServerType.find_by_name('Test ServerType 2'),
                                              :cloud => Cloud.find_by_name('Test Cloud 2')))
      DataLink.make!(@params.merge(:sourcable => c1_server1, :targetable => c2_server2,
                                   :source_to_target_monthly_baseline => 4,
                                   :target_to_source_monthly_baseline => 8))

      remote_node1 = RemoteNode.make!(@params)
      remote_node2 = RemoteNode.make!(@params)
      DataLink.make!(@params.merge(:sourcable => c1_server1, :targetable => remote_node1,
                                   :source_to_target_monthly_baseline => 3,
                                   :target_to_source_monthly_baseline => 7))
      DataLink.make!(@params.merge(:sourcable => c2_server2, :targetable => remote_node2,
                                   :source_to_target_monthly_baseline => 2,
                                   :target_to_source_monthly_baseline => 1))

      @cost_report.xml.should_not be_nil
      @cost_report.costs.length.should == 3
      # Prices are taken from cloud_maker
      c1_data_out = (9 + 3) * 0.1
      c1_data_in = (18 + 7) * 0.2
      c2_data_in = (9 + 1) * 0
      c2_data_out = (18 + 2) * 0.01
      @cost_report.costs.collect{|c| c[:data_in].round(2)}.should == Array.new(3){(c1_data_in + c2_data_in).round(2)}
      @cost_report.costs.collect{|c| c[:data_out].round(2)}.should == Array.new(3){(c1_data_out + c2_data_out).round(2)}
    end
  end

  context "do_servers_storages_database_resources" do
    before(:each) do
      @deployment = Deployment.make!(:user => @user)
      @report = Report.make!(:user => @user, :reportable => @deployment,
                             :start_date => '2012-01-01', :end_date => '2014-12-01')
      @cost_report = Reports::DeploymentCostReport.new(@report)
      @params = {:user => @user, :deployment => @deployment}
    end

    it "should set the correct cost for servers/storages/databases" do
      Server.make!(@params.merge(:server_type => ServerType.find_by_name('Test ServerType 1'),
                                           :cloud => Cloud.find_by_name('Test Cloud 1'),
                                           :instance_hour_monthly_baseline => 500,
                                           :quantity_monthly_baseline => 2))
      Storage.make!(@params.merge(:storage_type => StorageType.find_by_name('Test StorageType 1'),
                                           :cloud => Cloud.find_by_name('Test Cloud 1'),
                                           :storage_size_monthly_baseline => 200,
                                           :read_request_monthly_baseline => 1000,
                                           :write_request_monthly_baseline => 2000,
                                           :quantity_monthly_baseline => 3))
      DatabaseResource.make!(@params.merge(:database_type => DatabaseType.find_by_name('Test DatabaseType 1'),
                                           :cloud => Cloud.find_by_name('Test Cloud 1'),
                                           :instance_hour_monthly_baseline => 24,
                                           :storage_size_monthly_baseline => 200,
                                           :transaction_monthly_baseline => 2000,
                                           :quantity_monthly_baseline => 4))

      @cost_report.xml.should_not be_nil
      @cost_report.costs.length.should == 36
      # Prices are taken from cloud_maker
      instance_hour_cost = (500 * 2 * 0.6) + (24 * 4 * 0.7)
      storage_size_cost = (200 * 3 * 0.3) + (200 * 4 * 0.8)
      read_request_cost = (1000 / 10) * 3 * 0.4
      write_request_cost = (2000 / 100) * 3 * 0.5
      transaction_cost = (2000 / 1000) * 4 * 0.9
      @cost_report.costs.collect{|c| c[:instance_hour]}.should == Array.new(36){instance_hour_cost}
      @cost_report.costs.collect{|c| c[:storage_size]}.should == Array.new(36){storage_size_cost}
      @cost_report.costs.collect{|c| c[:read_request]}.should == Array.new(36){read_request_cost}
      @cost_report.costs.collect{|c| c[:write_request]}.should == Array.new(36){write_request_cost}
      @cost_report.costs.collect{|c| c[:transaction]}.should == Array.new(36){transaction_cost}
      @cost_report.costs.collect{|c| c[:data_in]}.should == Array.new(36){0.0}
      @cost_report.costs.collect{|c| c[:data_out]}.should == Array.new(36){0.0}
      @cost_report.costs.collect{|c| c[:additional_cost]}.should == Array.new(36){0.0}
    end

    it "should set the correct cost for servers with patterns for hours and quantity" do
      @report.update_attributes(:end_date => '2012-12-01')
      @cost_report = Reports::DeploymentCostReport.new(@report)
      server1 = Server.make!(@params.merge(:server_type => ServerType.find_by_name('Test ServerType 1'),
                                           :cloud => Cloud.find_by_name('Test Cloud 1'),
                                           :instance_hour_monthly_baseline => 640,
                                           :quantity_monthly_baseline => 1))
      pattern = Pattern.make!(:user => @user)
      Rule.make!(:pattern => pattern, :rule_type => 'Permanent', :year => 'every.1.year', :month => 'every.1.month', :variation => '+', :value => 10)
      server1.add_patterns('instance_hour_monthly_baseline', [pattern])
      server1.add_patterns('quantity_monthly_baseline', [pattern])

      @cost_report.xml.should_not be_nil
      @cost_report.costs.length.should == 12
      # Prices are taken from cloud_maker
      @cost_report.costs.collect{|c| c[:instance_hour].round(2)}.should == [(650 * 11 * 0.6), (660 * 21 * 0.6), (670 * 31 * 0.6),
                                                                            (680 * 41 * 0.6), (690 * 51 * 0.6), (700 * 61 * 0.6),
                                                                            (710 * 71 * 0.6), (720 * 81 * 0.6), (720 * 91 * 0.6),
                                                                            (740 * 101 * 0.6), (720 * 111 * 0.6), (744 * 121 * 0.6)]
      @cost_report.costs.collect{|c| c[:storage_size]}.should == Array.new(12){0.0}
      @cost_report.costs.collect{|c| c[:read_request]}.should == Array.new(12){0.0}
      @cost_report.costs.collect{|c| c[:write_request]}.should == Array.new(12){0.0}
      @cost_report.costs.collect{|c| c[:transaction]}.should == Array.new(12){0.0}
      @cost_report.costs.collect{|c| c[:data_in]}.should == Array.new(12){0.0}
      @cost_report.costs.collect{|c| c[:data_out]}.should == Array.new(12){0.0}
      @cost_report.costs.collect{|c| c[:additional_cost]}.should == Array.new(12){0.0}
    end

    it "should set the correct cost for servers with stupid patterns for hours and quantity" do
      @report.update_attributes(:end_date => '2012-03-01')
      @cost_report = Reports::DeploymentCostReport.new(@report)
      server1 = Server.make!(@params.merge(:server_type => ServerType.find_by_name('Test ServerType 1'),
                                           :cloud => Cloud.find_by_name('Test Cloud 1'),
                                           :instance_hour_monthly_baseline => 20,
                                           :quantity_monthly_baseline => 20))
      pattern = Pattern.make!(:user => @user)
      Rule.make!(:pattern => pattern, :rule_type => 'Permanent', :year => 'every.1.year', :month => 'every.1.month', :variation => '-', :value => 10)
      server1.add_patterns('instance_hour_monthly_baseline', [pattern])
      server1.add_patterns('quantity_monthly_baseline', [pattern])

      @cost_report.xml.should_not be_nil
      @cost_report.costs.length.should == 3
      # Prices are taken from cloud_maker
      @cost_report.costs.collect{|c| c[:instance_hour].round(2)}.should == [(10 * 10 * 0.6), 0.0, 0.0]
      @cost_report.costs.collect{|c| c[:storage_size]}.should == Array.new(3){0.0}
      @cost_report.costs.collect{|c| c[:read_request]}.should == Array.new(3){0.0}
      @cost_report.costs.collect{|c| c[:write_request]}.should == Array.new(3){0.0}
      @cost_report.costs.collect{|c| c[:transaction]}.should == Array.new(3){0.0}
      @cost_report.costs.collect{|c| c[:data_in]}.should == Array.new(3){0.0}
      @cost_report.costs.collect{|c| c[:data_out]}.should == Array.new(3){0.0}
      @cost_report.costs.collect{|c| c[:additional_cost]}.should == Array.new(3){0.0}
    end

    it "should set the correct cost for servers/storages/databases" do
      Server.make!(@params.merge(:server_type => ServerType.find_by_name('Test ServerType 1'),
                                           :cloud => Cloud.find_by_name('Test Cloud 1'),
                                           :instance_hour_monthly_baseline => 500,
                                           :quantity_monthly_baseline => 2))
      Server.make!(@params.merge(:server_type => ServerType.find_by_name('Test ServerType 1'),
                                           :cloud => Cloud.find_by_name('Test Cloud 1'),
                                           :instance_hour_monthly_baseline => 400,
                                           :quantity_monthly_baseline => 3))
      Storage.make!(@params.merge(:storage_type => StorageType.find_by_name('Test StorageType 2'),
                                           :cloud => Cloud.find_by_name('Test Cloud 2'),
                                           :storage_size_monthly_baseline => 2,
                                           :quantity_monthly_baseline => 4))
      Storage.make!(@params.merge(:storage_type => StorageType.find_by_name('Test StorageType 2'),
                                           :cloud => Cloud.find_by_name('Test Cloud 2'),
                                           :storage_size_monthly_baseline => 10,
                                           :quantity_monthly_baseline => 5))

      @cost_report.xml.should_not be_nil
      @cost_report.costs.length.should == 36
      # Prices are taken from cloud_maker
      instance_hour_cost = (500 * 2 * 0.6) + (400 * 3 * 0.6)
      storage_size_cost = (30 * 0.5) + (15 * 0.6) + ((58 - 45) * 0.7)
      @cost_report.costs.collect{|c| c[:instance_hour]}.should == Array.new(36){instance_hour_cost}
      @cost_report.costs.collect{|c| c[:storage_size]}.should == Array.new(36){storage_size_cost}
      @cost_report.costs.collect{|c| c[:read_request]}.should == Array.new(36){0.0}
      @cost_report.costs.collect{|c| c[:write_request]}.should == Array.new(36){0.0}
      @cost_report.costs.collect{|c| c[:transaction]}.should == Array.new(36){0.0}
      @cost_report.costs.collect{|c| c[:data_in]}.should == Array.new(36){0.0}
      @cost_report.costs.collect{|c| c[:data_out]}.should == Array.new(36){0.0}
      @cost_report.costs.collect{|c| c[:additional_cost]}.should == Array.new(36){0.0}
    end

    it "should set the correct cost for servers with reservation costs" do
      Server.make!(@params.merge(:server_type => ServerType.find_by_name('Test ServerType 2'),
                                           :cloud => Cloud.find_by_name('Test Cloud 2'),
                                           :instance_hour_monthly_baseline => 500,
                                           :quantity_monthly_baseline => 2))
      Server.make!(@params.merge(:server_type => ServerType.find_by_name('Test ServerType 3'),
                                           :cloud => Cloud.find_by_name('Test Cloud 2'),
                                           :instance_hour_monthly_baseline => 400,
                                           :quantity_monthly_baseline => 3))

      @cost_report.xml.should_not be_nil
      @cost_report.costs.length.should == 36
      # Prices are taken from cloud_maker
      instance_hour_cost = (10 * 2) + (400 * 3 * 0.05)
      @cost_report.costs.collect{|c| c[:instance_hour]}.should == [(2 * 100.0) + (3 * 80.0) + instance_hour_cost] + Array.new(11){instance_hour_cost} +
                                                                  [2 * 100.0 + instance_hour_cost] + Array.new(11){instance_hour_cost} +
                                                                  [2 * 100.0 + instance_hour_cost] + Array.new(11){instance_hour_cost}
      @cost_report.costs.collect{|c| c[:storage_size]}.should == Array.new(36){0.0}
      @cost_report.costs.collect{|c| c[:read_request]}.should == Array.new(36){0.0}
      @cost_report.costs.collect{|c| c[:write_request]}.should == Array.new(36){0.0}
      @cost_report.costs.collect{|c| c[:transaction]}.should == Array.new(36){0.0}
      @cost_report.costs.collect{|c| c[:data_in]}.should == Array.new(36){0.0}
      @cost_report.costs.collect{|c| c[:data_out]}.should == Array.new(36){0.0}
      @cost_report.costs.collect{|c| c[:additional_cost]}.should == Array.new(36){0.0}
    end

    it "should set the correct cost for server when cloud has costs" do
      Server.make!(@params.merge(:server_type => ServerType.make!, :cloud => Cloud.find_by_name('Empty Cloud')))
      @cost_report.xml.should_not be_nil
      @cost_report.costs.length.should == 36
      @cost_report.costs.collect{|c| c[:instance_hour]}.should == Array.new(36){0.0}
      @cost_report.costs.collect{|c| c[:storage_size]}.should == Array.new(36){0.0}
      @cost_report.costs.collect{|c| c[:read_request]}.should == Array.new(36){0.0}
      @cost_report.costs.collect{|c| c[:write_request]}.should == Array.new(36){0.0}
      @cost_report.costs.collect{|c| c[:transaction]}.should == Array.new(36){0.0}
      @cost_report.costs.collect{|c| c[:data_in]}.should == Array.new(36){0.0}
      @cost_report.costs.collect{|c| c[:data_out]}.should == Array.new(36){0.0}
      @cost_report.costs.collect{|c| c[:additional_cost]}.should == Array.new(36){0.0}
    end
  end
end