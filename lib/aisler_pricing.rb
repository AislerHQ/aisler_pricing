require 'csv'

require 'money'
require 'eu_central_bank'

require 'aisler_pricing/version'

module AislerPricing
  DEFAULT_CURRENCY = 'EUR'.freeze
  VAT_MULTIPLIERS = { de: 1.19 }.freeze
  VAT_RATES = { de: 19 }.freeze
  Money.default_currency = Money::Currency.new(DEFAULT_CURRENCY)
  Money.default_bank = EuCentralBank.new
  Money.default_bank.add_rate('EUR', 'USD', 1.25) # Fixed rate for our U.S. business

  def self.update_rates
    Money.default_bank.update_rates
  end

  def self.shipping_prices_data(country_code = nil)
    shipping_config ||= YAML.load(IO.read(File.expand_path('../aisler_pricing/shipping_prices.yml', __FILE__)), symbolize_names: true)

    if country_code
      country_code = country_code.downcase.to_sym

      default_config = shipping_config.dig(:global) || {}
      country_config = shipping_config.dig(country_code) || {}

      default_config.merge(country_config)
    else
      shipping_config.dig(:fallback_country_not_given)
    end
  end

  # All dimensions must be in mm2
  def self.board_price(args, currency = DEFAULT_CURRENCY)
    area = args[:area] ? args[:area] : (args[:width] * args[:height])
    area /= 100

    return Money.new(0) unless (105..155).include? args[:product_uid]

    base = case args[:product_uid]
    when 105
      12.00
    when 106
      10.20
    when 107
      12.30
    when 108
      12.30
    when 109
      6.0
    end
    price_per_cm2 = case args[:product_uid]
    when 105
      0.084
    when 106
      0.084
    when 107
      0.185
    when 108
      0.185
    when 109
      0.042
    end

    total = area * args[:quantity] * price_per_cm2
    total += base
    Money.new((total * 100).round).exchange_to(currency)
  end

  def self.stencil_price(args, currency = DEFAULT_CURRENCY)
    factor = (args[:smd_pad_count_top] || 0).zero? || (args[:smd_pad_count_bottom] || 0).zero? ? 1.0 : 2.0

    area = args[:area] ? args[:area] : (args[:width] * args[:height])
    area /= 100
    area *= factor

    base = 10.0
    price_per_cm2 = 0.095

    total = area * price_per_cm2
    total += base
    Money.new((total * 100).round).exchange_to(currency)
  end

  def self.registration_frame_price(currency = DEFAULT_CURRENCY)
    Money.new(840).exchange_to(currency)
  end

  def self.shipping(currency = DEFAULT_CURRENCY)
    Money.new(0).exchange_to(currency)
  end

  def self.tracked_shipping(args = {}, currency = DEFAULT_CURRENCY)
    country_code = args[:country_code]
    net_price = self.shipping_prices_data(country_code)[:tracked_net_price] * 100

    Money.new(net_price).exchange_to(currency)
  end

  def self.express_shipping(args = {}, currency = DEFAULT_CURRENCY)
    country_code = args[:country_code]
    net_price = self.shipping_prices_data(country_code)[:express_net_price] * 100

    Money.new(net_price).exchange_to(currency)
  end

  def self.precious_parts_price(args = {}, currency = DEFAULT_CURRENCY)
    bom_price_cents = args[:bom_price_cents] || 0

    base_fee_cents = 300
    service_charge = 1.20

    total = 0
    total += (bom_price_cents * service_charge).round
    total += base_fee_cents

    Money.new(total).exchange_to(currency)
  end

  def self.assembly_price(args, currency = DEFAULT_CURRENCY)
    q = args[:quantity]
    args[:bom_part_variance] ||= 0
    args[:bom_part_total] ||= 0

    return Money.new(0) unless q
    area = args[:area] ? args[:area] : (args[:width] * args[:height])
    area /= 100

    setup_fee = Money.new(7500 + 450 * args[:bom_part_variance])
    handling_fee = Money.new(area * q)
    placement_fee = Money.new(q * args[:bom_part_total] * 5)
    factor = args[:project_double_sided] ? 2 : 1
    smd_cost = factor * (setup_fee + handling_fee + placement_fee)

    thru_holes = args[:thru_holes]
    total_thru_holes_to_assemble = thru_holes * q
    time_per_hour_to_assemble_thru_hole = (7.0 / (60.0 * 60.0))
    tht_fee = if total_thru_holes_to_assemble > 0
      Money.new(3000 + time_per_hour_to_assemble_thru_hole * total_thru_holes_to_assemble * 4000)
    else
      Money.new(0)
    end
    smd_cost + tht_fee
  end

  def self.price(product_uid, args = {})
    currency = args[:currency] || DEFAULT_CURRENCY

    case product_uid
    when 102
      precious_parts_price(args, currency)
    when 103
      stencil_price(args, currency)
    when 104
      prices = [
        board_price(args, currency),
        precious_parts_price(args, currency),
        stencil_price(args, currency),
        assembly_price(args, currency)
      ]
      prices.sum
    when (105..155)
      board_price(args.merge(product_uid: product_uid), currency)
    when 202
      Money.new(0)
    when 203
      Money.new(6000)
    when 204
      Money.new(0)
    when 71
      Money.new(168)
    when 72
      Money.new(168)
    when 99
      express_shipping(args, currency)
    when 98
      tracked_shipping(args, currency)
    when 84
      registration_frame_price(currency)
    end
  end

end
