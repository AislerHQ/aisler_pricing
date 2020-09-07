require 'csv'

require 'money'
require 'eu_central_bank'

require 'aisler_pricing/version'

module AislerPricing
  DEFAULT_CURRENCY = 'EUR'.freeze
  VAT_MULTIPLIERS = { de: 1.16 }.freeze
  VAT_RATES = { de: 16 }.freeze
  Money.default_currency = Money::Currency.new(DEFAULT_CURRENCY)
  Money.default_bank = EuCentralBank.new
  Money.default_bank.add_rate('EUR', 'USD', 1.15) # Fixed rate for our U.S. business

  def self.update_rates
    Money.default_bank.update_rates
  end

  # All dimensions must be in mm2
  def self.board_price(args, currency = DEFAULT_CURRENCY)
    area = args[:area] ? args[:area] : (args[:width] * args[:height])
    area /= 100

    return Money.new(0) unless (105..155).include? args[:product_uid]

    base = case args[:product_uid]
    when 105
      10.20
    when 106
      10.20
    when 107
      12.30
    end
    price_per_cm2 = case args[:product_uid]
    when 105
      0.084
    when 106
      0.084
    when 107
      0.185
    end

    total = area * args[:quantity] * price_per_cm2
    total += base
    total /= args[:quantity]
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

  def self.express_shipping(currency = DEFAULT_CURRENCY)
    Money.new(1500).exchange_to(currency)
  end

  def self.precious_parts_price(args = {}, currency = DEFAULT_CURRENCY)
    total = 0

    bom_price = args[:bom_price_cents] || 0

    return Money.new(0, currency) unless bom_price.positive?

    precious_parts_base_fee_cents = 300
    total += precious_parts_base_fee_cents

    bom_price_cents = args[:bom_price_cents] || 0
    service_charge = 1.15

    total += (bom_price_cents * service_charge).round

    Money.new(total).exchange_to(currency)
  end

  def self.price(product_uid, args = {})
    currency = args[:currency] || DEFAULT_CURRENCY

    case product_uid
    when 102
      precious_parts_price(args, currency)
    when 103
      stencil_price(args.slice(:area, :smd_pad_count_top, :smd_pad_count_bottom), currency)
    when (105..154)
      board_price(args.slice(:area, :quantity).merge(product_uid: product_uid), currency)
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
      express_shipping(currency)
    when 84
      registration_frame_price(currency)
    end
  end

end
