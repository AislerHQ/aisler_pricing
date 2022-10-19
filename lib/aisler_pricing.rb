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
      6.0
    when 107
      6.0
    when 108
      6.0
    when 109
      6.0
    end
    price_per_cm2 = case args[:product_uid]
    when 105
      0.084
    when 106
      0.084
    when 107
      0.117
    when 108
      0.117
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

    base = 5.0
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

  def self.parts_price(args = {}, currency = DEFAULT_CURRENCY)
    bom_price_cents = args[:bom_price_cents] || 0

    base_fee_cents = 0.0
    service_charge = 1.25

    total = 0
    total += (bom_price_cents * service_charge).round
    total += base_fee_cents

    Money.new(total).exchange_to(currency)
  end

  def self.series_assembly_price(args, currency = DEFAULT_CURRENCY)
    qty = args[:quantity]
    smt_count = args[:part_smt_count]
    tht_count = args[:part_tht_count]

    return Money.new(0).exchange_to(currency) unless qty

    area = args[:area] ? args[:area] : (args[:width] * args[:height])
    area /= 100

    factor = args[:double_sided] ? 2 : 1
    customer_supplied_part_variance = args[:customer_supplied_part_variance] || 0
    customer_supplied_part_fee = 15_00 * customer_supplied_part_variance
    part_setup_fee = 10_00 * args[:part_variance]
    handling_fee = area * qty * factor * 0_01
    double_side_fee = (factor - 1) * 80_00
    tht_setup_fee = tht_count.positive? ? 40_00 : 0
    setup_fee = handling_fee + tht_setup_fee + part_setup_fee + customer_supplied_part_fee + double_side_fee

    smt_placement_fee = qty * smt_count * 0_04
    tht_placement_fee = qty * tht_count * 0_50

    Money.new(setup_fee + smt_placement_fee + tht_placement_fee).exchange_to(currency)
  end

  def self.prototyping_assembly_price(args, currency = DEFAULT_CURRENCY)
    return Money.new(0).exchange_to(currency) unless args[:quantity]

    setup_fee = 25_00
    placement_fee = (args[:part_smt_count] + args[:part_tht_count]) * args[:quantity] * 0_25

    Money.new(setup_fee + placement_fee).exchange_to(currency)
  end

  def self.price(product_uid, args = {})
    currency = args[:currency] || DEFAULT_CURRENCY

    case product_uid
    when 103
      stencil_price(args, currency)
    when (105..155)
      board_price(args.merge(product_uid: product_uid), currency)
    when 164
      # Always calculate at least 3 PCBs
      min_pcb_qty = 3
      board_args = args.merge(quantity: (args[:quantity].to_f / min_pcb_qty).ceil * min_pcb_qty)
      prices = [
        board_price(board_args, currency),
        parts_price(args, currency),
        stencil_price(args, currency),
        series_assembly_price(args, currency)
      ]
      prices.sum
    when 165
      # Always calculate at least 3 PCBs
      min_pcb_qty = 3
      board_args = args.merge(
        quantity: (args[:quantity].to_f / min_pcb_qty).ceil * min_pcb_qty,
        product_uid: 109
      )
      prices = [
        board_price(board_args, currency),
        parts_price(args, currency),
        stencil_price(args, currency),
        prototyping_assembly_price(args, currency)
      ]
      prices.sum
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
    when 73
      Money.new(42)
    when 99
      express_shipping(args, currency)
    when 98
      tracked_shipping(args, currency)
    when 84
      registration_frame_price(currency)
    end
  end

end
