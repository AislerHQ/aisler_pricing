require 'csv'

require 'money'
require 'eu_central_bank'

require 'aisler_pricing/version'

module AislerPricing
  DEFAULT_CURRENCY = 'EUR'.freeze
  VAT_MULTIPLIERS = { de: 1.19 }.freeze
  VAT_RATES = { de: 19 }.freeze

  def self.shipping_prices_data(country_code = nil)
    shipping_config ||= YAML.safe_load(IO.read(File.expand_path('../aisler_pricing/shipping_prices.yml', __FILE__)), symbolize_names: true, aliases: true)

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

    return Money.new(0, currency) unless (105..155).include? args[:product_uid]

    base = case args[:product_uid]
    when 105
      12.00
    when 106
      12.0
    when 107
      12.0
    when 108
      12.0
    when 109
      10.0
    end
    price_per_cm2 = case args[:product_uid]
    when 105
      0.104
    when 106
      0.084
    when 107
      0.117
    when 108
      0.1825
    when 109
      0.0525
    end

    total = area * args[:quantity] * price_per_cm2
    total += base
    Money.from_amount(total, DEFAULT_CURRENCY).exchange_to(currency)
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
    Money.from_amount(total, DEFAULT_CURRENCY).exchange_to(currency)
  end

  def self.registration_frame_price(currency = DEFAULT_CURRENCY)
    Money.new(8_40, DEFAULT_CURRENCY).exchange_to(currency)
  end

  def self.shipping(currency = DEFAULT_CURRENCY)
    Money.new(0, currency)
  end

  def self.tracked_shipping(args = {}, currency = DEFAULT_CURRENCY)
    country_code = args[:country_code]
    net_price = self.shipping_prices_data(country_code)[:tracked_net_price]

    Money.from_amount(net_price, DEFAULT_CURRENCY).exchange_to(currency)
  end

  def self.express_shipping(args = {}, currency = DEFAULT_CURRENCY)
    country_code = args[:country_code]
    net_price = self.shipping_prices_data(country_code)[:express_net_price]

    Money.from_amount(net_price, DEFAULT_CURRENCY).exchange_to(currency)
  end

  def self.parts_price(args = {}, currency = DEFAULT_CURRENCY)
    bom_price_cents = args[:bom_price_cents] || 0

    base_fee_cents = 0.0
    service_charge = 1.50

    total = 0
    total += (bom_price_cents * service_charge).round
    total += base_fee_cents

    Money.new(total, DEFAULT_CURRENCY).exchange_to(currency)
  end

  def self.assembly_price(args, currency = DEFAULT_CURRENCY)
    customer_supplied_part_variance = args[:customer_supplied_part_variance] || 0
    qty = args[:quantity]
    smt_count = args[:part_smt_count]
    tht_count = args[:part_tht_count]

    manual_fees = []
    manual_fees << qty * tht_count * 38
    manual_fees << qty * smt_count * 38

    manual_fees << 75_00
    manual_fees << 30_00 if args[:double_sided]
    manual_fees << 15_00 * customer_supplied_part_variance

    automatic_fees = []
    automatic_fees << 332_50
    automatic_fees << 332_50 if args[:double_sided]
    automatic_fees << 3_75 * args[:part_variance]
    automatic_fees << qty * smt_count * 3
    automatic_fees << 30_00 unless tht_count.zero?
    automatic_fees << qty * tht_count * 38
    automatic_fees << 15_00 * customer_supplied_part_variance

    price = [manual_fees.sum, automatic_fees.sum].min
    Money.new(price, DEFAULT_CURRENCY).exchange_to(currency)
  end

  def self.price(product_uid, args = {})
    currency = args[:currency] || DEFAULT_CURRENCY

    case product_uid
    when 103
      stencil_price(args, currency)
    when 104, 201, 202
      # Always calculate at least 3 PCBs
      min_pcb_qty = 3
      board_args = args.merge(quantity: (args[:quantity].to_f / min_pcb_qty).ceil * min_pcb_qty)
      prices = [
        board_price(board_args, currency),
        parts_price(args, currency),
        stencil_price(args, currency),
        assembly_price(args, currency)
      ]
      prices.sum
    when (105..155)
      board_price(args.merge(product_uid: product_uid), currency)
    when 202
      Money.new(0, currency)
    when 203
      Money.new(60_00, DEFAULT_CURRENCY).exchange_to(currency)
    when 204
      Money.new(0, currency)
    when 71
      Money.new(1_68, DEFAULT_CURRENCY).exchange_to(currency)
    when 72
      Money.new(1_68, DEFAULT_CURRENCY).exchange_to(currency)
    when 73
      Money.new(42, DEFAULT_CURRENCY).exchange_to(currency)
    when 99
      express_shipping(args, currency)
    when 98
      tracked_shipping(args, currency)
    when 84
      registration_frame_price(currency)
    when 88
      Money.new(-1000, DEFAULT_CURRENCY).exchange_to(currency)
    end
  end

end
