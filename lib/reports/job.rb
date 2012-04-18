module Reports
  class Job < Struct.new(:report)

    def perform
      # The logic about how the report XML is generated and what XSLT is used goes here.
      report_generator = nil
      case report.reportable.class.to_s
        when 'Deployment'
          report_generator = DeploymentCostReport.new(report)
          report_xslt_file = 'deployment_cost_report.xslt'
      end

      #  if the generator has a html method, call it directly
      if report_generator.respond_to?(:html)
        report_html = report_generator.html
      else # call xml and use associated xslt to generate html
        report_xml = report_generator.xml
        xslt = XML::XSLT.new
        xslt.xml = report_xml
        xslt.xsl = Rails.root.join('lib', 'reports', 'xslt', report_xslt_file).to_s
        report.xml  = report_xml
        report.xslt_file = report_xslt_file
        report_html = xslt.serve
      end
      report.html =  report_html
      report.save!
    end

    def enqueue(job)
      report.status = 'Pending'
      report.completed_at = nil
      report.save
    end

    def before(job)
      report.status = 'Processing'
      report.save
    end

    def success(job)
      report.status = 'Completed'
      report.completed_at = Time.now
      report.save
    end

    def error(job, exception)
      Airbrake.notify(exception)
      Rails.logger.warn("DelayedJob error: Report #{report.id}, Job: #{job.id}, Exception:\n#{exception}")
    end

    def failure
      report.status = 'Failed'
      report.save
      Rails.logger.error("DelayedJob failed: Report #{report.id}")
    end
  end
end