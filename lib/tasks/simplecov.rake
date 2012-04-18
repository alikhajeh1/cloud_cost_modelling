begin
  require 'rspec/core/rake_task'

  desc "Run Rspec with code coverage report"
  task :simplecov do
    ENV['COVERAGE'] = 'true'
    Rake::Task["spec"].execute
    `open coverage/index.html`
  end
rescue LoadError
end