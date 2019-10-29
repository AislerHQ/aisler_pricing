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
  def self.board_price(dimension, layer_count, currency = DEFAULT_CURRENCY)
    area = case dimension
    when Hash
      dimension[:width] * dimension[:height]
    when Array
      dimension[0] * dimension[1]
    else
      dimension
    end

    price = if layer_count == 2
      price = 0.0
      segments = [75, 117, Float::MAX]
      slope = [0.4, 0.1, 0.6]

      dim = Math.sqrt(area.to_f)
      segments.each_with_index do |seg, ix|
        t_seg = [seg, dim].min
        price += t_seg * slope[ix]
        dim -= t_seg
      end
      Money.new([(price / 3 * 100).round, 235].max)

    elsif layer_count == 4
      price = if area <= 1369
        Money.new(496)
      elsif area > 1369 && area <= 5776
        Money.new(1168)
      else
        Money.new(1681)
      end
      price

    else
      Money.new(0)
    end

    price.exchange_to(currency)
  end

  def self.stencil_price(currency = DEFAULT_CURRENCY)
    Money.new(1084).exchange_to(currency)
  end

  def self.shipping(currency = DEFAULT_CURRENCY)
    Money.new(0).exchange_to(currency)
  end

  def self.express_shipping(currency = DEFAULT_CURRENCY)
    Money.new(1500).exchange_to(currency)
  end

  def self.panel_price(area, quantity, rows, cols, config)
    case config
    when 'pp-2l'
      fix = 70.0
      a = 0.111
      b = 0.332
    when 'pp-hd-2l'
      fix = 100.0
      a = 0.111
      b = 0.329
    when 'pp-hd-4l'
      fix = 130.0
      a = 0.355
      b = 0.454
    end

    pieces = rows * cols
    area /= 100
    area = area * quantity * rows * cols

    price_cents = ((a * 100 ** b) * ( area ** (1 - b)) + fix) * 100
    price_cents / quantity
  end

  def self.price(product_uid, args = {})
    currency = args[:currency] || DEFAULT_CURRENCY

    case product_uid
    when 103
      stencil_price(currency)
    when 105
      board_price(args[:dimension], 2, currency)
    when 106
      board_price(args[:dimension], 2, currency)
    when 107
      board_price(args[:dimension], 4, currency)
    when 201
      panel_price(args[:area], args[:quantity], args[:rows], args[:cols, args[:config]])
    when 202
      Money.new(0)
    when 203
      Money.new(6000)
    when 204
      Money.new(0)
    when 71
      Money.new(200)
    when 72
      Money.new(200)
    when 81
      Money.new(1000)
    when 99
      express_shipping(currency)
    end
  end

end
