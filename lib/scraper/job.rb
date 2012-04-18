module Scraper
  class Job < Struct.new(:cloud_provider)

    def perform
      Scraper::Aws.scrape       if ['aws', 'all'].include? cloud_provider
      Scraper::Rackspace.scrape if ['rackspace', 'all'].include? cloud_provider
      Scraper::Microsoft.scrape if ['microsoft', 'all'].include? cloud_provider
    end

    def enqueue(job)
      Rails.logger.warn("DelayedJob pending: Job: #{job.id}, Cloud provider: #{cloud_provider}")
    end

    def before(job)
      Rails.logger.warn("DelayedJob starting: Job: #{job.id}, Cloud provider: #{cloud_provider}")
    end

    def error(job, exception)
      Airbrake.notify(exception)
      Rails.logger.warn("DelayedJob error: Job: #{job.id}, Cloud provider: #{cloud_provider}, Exception:\n#{exception}")
    end

    def success(job)
      Rails.logger.error("DelayedJob succeeded: Job: #{job.id}, Scraping #{cloud_provider} succeeded.")
    end

    def failure
      Rails.logger.error("DelayedJob failed: Scraping #{cloud_provider} failed.")
    end
  end
end