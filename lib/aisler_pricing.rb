require 'csv'

require 'money'
require 'eu_central_bank'

require "aisler_pricing/version"

module AislerPricing
  DEFAULT_CURRENCY = 'EUR'.freeze
  Money.default_currency = Money::Currency.new(DEFAULT_CURRENCY)
  Money.default_bank = EuCentralBank.new
  Money.default_bank.add_rate('EUR', 'USD', 1.15) # Fixed rate for our U.S. business

  def self.update_rates
    Money.default_bank.update_rates
  end

  # All dimensions must be in mm2
  def self.board_price(dimension, quantity, product, currency = DEFAULT_CURRENCY)
    area = case dimension
    when Hash
      dimension[:width] * dimension[:height]
    when Array
      dimension[0] * dimension[1]
    when Integer
      dimension
    else
      return Money.new(0)
    end
    area /= 100

    base = 8.4
    price_per_cm2 = case product
    when 105
      0.064
    when 106
      0.064
    when 107
      0.161
    else
      return Money.new(0)
    end

    total = area * quantity * price_per_cm2
    total += base
    total /= quantity
    Money.new((total * 100).round).exchange_to(currency)
  end

  def self.stencil_price(dimension, currency = DEFAULT_CURRENCY)
    area = case dimension
    when Hash
      dimension[:width] * dimension[:height]
    when Array
      dimension[0] * dimension[1]
    else
      dimension
    end
    
    price = 0.0
    segments = [60, 140, Float::MAX]
    slope = [0.2, 0.05, 0.2]

    dim = Math.sqrt(area.to_f)
    segments.each_with_index do |seg, ix|
      t_seg = [seg, dim].min
      price += t_seg * slope[ix]
      dim -= t_seg
    end
    
    Money.new([(price * 100).round, 600].max).exchange_to(currency)
  end

  def self.shipping(currency = DEFAULT_CURRENCY)
    Money.new(0).exchange_to(currency)
  end

  def self.express_shipping(currency = DEFAULT_CURRENCY)
    Money.new(1500).exchange_to(currency)
  end

  def self.panel_price(area, quantity, rows, cols, product)
    case product
    when 155
      fix = 70.0
      a = 0.111
      b = 0.332
    when 156
      fix = 100.0
      a = 0.111
      b = 0.329
    when 157
      fix = 130.0
      a = 0.355
      b = 0.454
    end

    pieces = rows * cols
    area /= 100
    area = area * quantity * rows * cols

    price_cents = ((a * 100 ** b) * ( area ** (1 - b)) + fix) * 100
    Money.new(price_cents / quantity)
  end

  def self.price(product_uid, args = {})
    currency = args[:currency] || DEFAULT_CURRENCY

    case product_uid
    when 103
      stencil_price(args[:area], currency)
    when (105..154)
      board_price(args[:area], args[:quantity], product_uid, currency)
    when (155..199)
      panel_price(args[:area], args[:quantity], args[:rows], args[:cols], product_uid)
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
    end
  end

end
