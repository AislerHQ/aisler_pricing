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
      Money.new([(price / 3 * 100).round, 280].max)

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

end
