require "bundler/setup"
require "aisler_pricing"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

Money.locale_backend = :currency
Money.default_currency = Money::Currency.new('EUR')
Money.default_bank.add_rate('EUR', 'USD', 1.25)
