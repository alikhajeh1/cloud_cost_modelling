module FactorySpecHelper

  def given_resources_for(models, options={})
    resources = options.dup

    resources[:cloud_provider] ||= CloudProvider.make!
    resources[:cloud] ||= Cloud.make(:cloud_provider => resources[:cloud_provider])
    resources[:cloud].save!
    resources[:server_type]   ||= ServerType.make!
    resources[:storage_type]  ||= StorageType.make!
    resources[:database_type] ||= DatabaseType.make!

    resources[:user] ||= User.make!
    resources[:deployment] ||= Deployment.make!(:user => resources[:user])
    resources[:pattern] ||= Pattern.make!(:user => resources[:user])

    if models.include?(:deployment)
      2.times do
        server = Server.make(:user => resources[:user], :deployment => resources[:deployment],
                             :server_type => resources[:server_type], :cloud => resources[:cloud])
        server.save!
        storage = Storage.make(:user => resources[:user], :deployment => resources[:deployment],
                               :storage_type => resources[:storage_type], :cloud => resources[:cloud])
        storage.save!
        DatabaseResource.make(:user => resources[:user], :deployment => resources[:deployment],
                              :database_type => resources[:database_type], :cloud => resources[:cloud]).save
        Application.make(:user => resources[:user], :deployment => resources[:deployment], :server => server).save
        DataChunk.make(:user => resources[:user], :deployment => resources[:deployment], :storage => storage).save
        RemoteNode.make(:user => resources[:user], :deployment => resources[:deployment]).save
      end
      DataLink.make(:user => resources[:user], :deployment => resources[:deployment],
                    :sourcable => resources[:deployment].storages.first, :targetable => resources[:deployment].servers.first).save
      resources[:deployment].applications.first.add_patterns('instance_hour_monthly_baseline', [resources[:pattern]])
    end

    if models.include?(:server)
      resources[:server] = Server.make(:user => resources[:user], :deployment => resources[:deployment],
                                       :server_type => resources[:server_type], :cloud => resources[:cloud])
      resources[:server].save
    end

    if models.include?(:application)
      server = Server.make(:user => resources[:user], :deployment => resources[:deployment],
                           :server_type => resources[:server_type], :cloud => resources[:cloud])
      server.save
      resources[:application] = Application.make(:user => resources[:user], :deployment => resources[:deployment], :server => server)
      resources[:application].save

      resources[:application].add_patterns('instance_hour_monthly_baseline', [resources[:pattern]])
    end

    if models.include?(:storage)
      resources[:storage] = Storage.make(:user => resources[:user], :deployment => resources[:deployment],
                                         :storage_type => resources[:storage_type], :cloud => resources[:cloud])
      resources[:storage].save
    end

    if models.include?(:data_chunk)
      storage = Storage.make(:user => resources[:user], :deployment => resources[:deployment],
                             :storage_type => resources[:storage_type], :cloud => resources[:cloud])
      storage.save
      resources[:data_chunk] = DataChunk.make(:user => resources[:user], :deployment => resources[:deployment], :storage => storage)
      resources[:data_chunk].save

      resources[:data_chunk].add_patterns('storage_size_monthly_baseline', [resources[:pattern]])
    end

    if models.include?(:pattern)
      2.times do
        Rule.make(:user => resources[:user], :pattern => resources[:pattern]).save
      end
    end

    if models.include?(:report)
      resources[:report] = Report.make(:user => resources[:user], :reportable => resources[:deployment])
      resources[:report].save
    end

    resources
  end
end
