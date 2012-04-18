if Rails.env.development? || Rails.env.test?
  require 'ruby-debug'
  Itslog.configure do |config|
    config.namespace_colors = {
      'action_controller' => "\e[32m",
      'active_record'     => "\e[94m",
      'action_view'       => "\e[36m"
    }
    config.format = "%t [%n]: %m"
    config.message_color = "\e[37m"
    config.timestamp_format = "%Y-%m-%d %H:%M:%S%z"
  end
end

require 'money'
require 'money/bank/google_currency'
Money.default_bank = Money::Bank::GoogleCurrency.new