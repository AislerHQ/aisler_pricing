require 'spec_helper'
require 'countries'

RSpec.describe AislerPricing do
  it "has a version number" do
    expect(AislerPricing::VERSION).not_to be nil
  end

  it "should receive 2 layer PCB price in euros" do
    price = AislerPricing.board_price(area: 1, quantity: 3, product_uid: 105)
    expect(price).to be_an_instance_of Money
    expect(price.cents).to eq(1200) # Lowest price point
  end

  it "should receive 4 layer PCB price in euros" do
    price = AislerPricing.board_price(area: 1, quantity: 3, product_uid: 107)
    expect(price).to be_an_instance_of Money

    price *= 1.19
    expect(price.cents).to eq(1428)

    price = AislerPricing.board_price(area: 2000, quantity: 3, product_uid: 107)
    expect(price).to be_an_instance_of Money

    price *= 1.19
    expect(price.cents).to eq(2263)

    price = AislerPricing.board_price(area: 60000, quantity: 3, product_uid: 107)
    expect(price).to be_an_instance_of Money

    price *= 1.19
    expect(price.cents).to eq(26489)
  end

  it 'should receive 6 layer PCB prices in euros' do
    price = AislerPricing.board_price(area: 3600, quantity: 3, product_uid: 108)
    expect(price).to be_an_instance_of Money

    price *= 1.19
    expect(price.cents).to eq(3773)
  end

  it 'should receive stencil price' do
    price = AislerPricing.stencil_price(width: 1, height: 1) # Really small stencil
    expect(price).to be_an_instance_of Money
    expect(price.cents).to eq(500) # Base price for stencils

    price = AislerPricing.stencil_price(width: 110, height: 70, smd_pad_count_top: 10, smd_pad_count_bottom: 10)
    expect(price).to be_an_instance_of Money
    expect(price.cents).to eq(1963)

    price = AislerPricing.stencil_price(width: 50, height: 60)
    expect(price).to be_an_instance_of Money
    expect(price.cents).to eq(785)

    price = AislerPricing.stencil_price(width: 160, height: 100)
    expect(price).to be_an_instance_of Money
    expect(price.cents).to eq(2020)

    price = AislerPricing.stencil_price(width: 200, height: 200)
    expect(price).to be_an_instance_of Money
    expect(price.cents).to eq(4300)

    price = AislerPricing.stencil_price(width: 300, height: 300)
    expect(price).to be_an_instance_of Money
    expect(price.cents).to eq(9050)
  end

  it 'should receive stencil price as US Dollars' do
    price = AislerPricing.stencil_price({ width: 10, height: 5 }, 'USD')
    expect(price.currency).to eq('USD')
    expect(price.cents).not_to eq(AislerPricing.stencil_price({ width: 10, height: 5 }).cents)
  end

  it 'should receive PCB price as US Dollars' do
    price = AislerPricing.board_price({ area: 100, quantity: 3, product_uid: 105 }, 'USD')

    expect(price.currency).to eq('USD')
  end

  it 'should support hash, array and area as input values for board price' do
    price_cents = 4320
    expect(AislerPricing.board_price(area: 10000, quantity: 3, product_uid: 105).cents).to eq(price_cents)
    expect(AislerPricing.board_price(area: 10000, quantity: 3, product_uid: 105).cents).to eq(price_cents)
    expect(AislerPricing.board_price( { width: 100, height: 100, quantity: 3, product_uid: 105} ).cents).to eq(price_cents)
  end

  it 'should return prices for AISLER product codes' do
    expect(AislerPricing.price(105, area: 1, quantity: 3).cents).to eq(1200)
    expect(AislerPricing.price(103, area: 1600, smd_pad_count_top: 10, smd_pad_count_bottom: 0).cents).to eq(652)
  end

  it 'output prices for uC net listing' do
    [
      { width: 160, height: 100, quantity: 3, product_uid: 105 },
      { width: 100, height: 80, quantity: 3, product_uid: 105 },
      { width: 160, height: 100, quantity: 3, product_uid: 109 },
      { width: 100, height: 80, quantity: 3, product_uid: 109 },
      { width: 20, height: 20, quantity: 3, product_uid: 107 },
      { width: 60, height: 50, quantity: 3, product_uid: 107 },
      { width: 160, height: 100, quantity: 3, product_uid: 107 },
      { width: 160, height: 100, quantity: 12, product_uid: 109 },
      { width: 20, height: 20, quantity: 3, product_uid: 108 },
      { width: 60, height: 60, quantity: 3, product_uid: 108 },
      { width: 50, height: 50, quantity: 3, product_uid: 109 },
    ].each { |args| puts args.to_s + ' / ' + AislerPricing.board_price(args).format + '/' + (AislerPricing.board_price(args) * 1.19).format }
  end

  it 'should return prices for electronic parts in EUR' do
    args = {
      bom_price_cents: 1337
    }
    expect(AislerPricing.parts_price(args).cents).to eq(2006)
  end

  it 'should return prices for electronic parts in other currency' do
    args = {
      bom_price_cents: 1337
    }
    currency = 'USD'

    result = AislerPricing.parts_price(args, currency)
    expect(result.currency).to eq(currency)
  end

  context 'should return assembly service price' do
    it 'for single side' do
      args = {
        width: 80.0,
        height: 57.0,
        quantity: 30,
        product_uid: 109,
        part_variance: 13,
        bom_price_cents: 1000,
        part_smt_count: 23,
        part_tht_count: 8,
        double_sided: false
      }

      expect(AislerPricing.assembly_price(args).cents).to eq(428_40)
    end

    it 'for double side' do
      args = {
        width: 80.0,
        height: 57.0,
        quantity: 30,
        product_uid: 109,
        part_variance: 13,
        bom_price_cents: 1000,
        part_smt_count: 23,
        part_tht_count: 8,
        double_sided: true
      }

      expect(AislerPricing.assembly_price(args).cents).to eq(458_40)
    end

    it 'without tht' do
      args = {
        width: 80.0,
        height: 57.0,
        quantity: 30,
        product_uid: 109,
        part_variance: 13,
        bom_price_cents: 1000,
        part_smt_count: 23,
        part_tht_count: 0,
        double_sided: true
      }

      expect(AislerPricing.assembly_price(args).cents).to eq(367_20)
    end

    it 'without smt' do
      args = {
        width: 80.0,
        height: 57.0,
        quantity: 30,
        product_uid: 109,
        part_variance: 13,
        bom_price_cents: 1000,
        part_smt_count: 0,
        part_tht_count: 24,
        double_sided: true
      }

      expect(AislerPricing.assembly_price(args).cents).to eq(378_60)
    end

    it 'with customer supplied part variance' do
      args = {
        width: 80.0,
        height: 57.0,
        quantity: 30,
        product_uid: 109,
        part_variance: 13,
        bom_price_cents: 1000,
        part_smt_count: 23,
        part_tht_count: 8,
        customer_supplied_part_variance: 3,
        double_sided: true
      }

      expect(AislerPricing.assembly_price(args).cents).to eq(503_40)
    end

    it 'without customer supplied part variance' do
      args = {
        width: 80.0,
        height: 57.0,
        quantity: 30,
        product_uid: 109,
        part_variance: 13,
        bom_price_cents: 1000,
        part_smt_count: 23,
        part_tht_count: 8,
        double_sided: true
      }

      expect(AislerPricing.assembly_price(args).cents).to eq(458_40)
    end

    it 'in different currency' do
      args = {
        width: 80.0,
        height: 57.0,
        quantity: 30,
        product_uid: 109,
        part_variance: 13,
        bom_price_cents: 1000,
        part_smt_count: 23,
        part_tht_count: 8,
        double_sided: true
      }

      expect(AislerPricing.assembly_price(args, 'USD').currency).to eq('USD')
    end

    it 'for machine assembly volume' do
      args = {
        width: 80.0,
        height: 57.0,
        quantity: 500,
        product_uid: 109,
        part_variance: 13,
        bom_price_cents: 1000,
        part_smt_count: 23,
        part_tht_count: 8,
        double_sided: false
      }

      expect(AislerPricing.assembly_price(args).cents).to eq(2276_25)
    end

    it 'with blitz sla' do
      args = {
        width: 80.0,
        height: 57.0,
        quantity: 30,
        product_uid: 109,
        part_variance: 13,
        bom_price_cents: 1000,
        part_smt_count: 23,
        part_tht_count: 8,
        double_sided: false,
        sla: :blitz
      }

      expect(AislerPricing.assembly_price(args).cents).to eq(856_80)
    end
  end

  context 'should return price for complete assembly' do
    it 'for simple designs' do
      args = {
        width: 80.0,
        height: 57.0,
        quantity: 30,
        product_uid: 109,
        part_variance: 13,
        bom_price_cents: 1000,
        part_smt_count: 23,
        part_tht_count: 8,
        double_sided: false
      }

      expect(AislerPricing.price(104, args).cents).to eq(534_55)
      expect(AislerPricing.price(201, args).cents).to eq(534_55)
    end

    it 'for complex designs' do
      args = {
        width: 80.0,
        height: 57.0,
        quantity: 30,
        product_uid: 106,
        part_variance: 13,
        bom_price_cents: 1000,
        part_smt_count: 23,
        part_tht_count: 8,
        double_sided: false
      }

      expect(AislerPricing.price(104, args).cents).to eq(579_64)
      expect(AislerPricing.price(202, args).cents).to eq(579_64)
    end

    it 'in different currency' do
      args = {
        width: 80.0,
        height: 57.0,
        quantity: 30,
        product_uid: 109,
        part_variance: 13,
        bom_price_cents: 1000,
        part_smt_count: 23,
        part_tht_count: 8,
        double_sided: true,
        currency: 'USD'
      }

      expect(AislerPricing.price(104, args).currency).to eq('USD')
    end

    it 'if parts are free' do
      args = {
        width: 80.0,
        height: 57.0,
        quantity: 30,
        product_uid: 109,
        part_variance: 13,
        bom_price_cents: 0,
        part_smt_count: 23,
        part_tht_count: 8,
        double_sided: false
      }

      expect(AislerPricing.price(104, args).cents).to eq(519_55)
    end

    it 'if quantity is just one' do
      args = {
        width: 100.0,
        height: 80.0,
        quantity: 1,
        product_uid: 109,
        part_variance: 0,
        bom_price_cents: 0,
        part_smt_count: 0,
        part_tht_count: 0,
        double_sided: false
      }

      expect(AislerPricing.price(104, args).cents).to eq(110_20)
    end

    it 'for blitz designs' do
      args = {
        width: 80.0,
        height: 57.0,
        quantity: 30,
        product_uid: 109,
        part_variance: 13,
        bom_price_cents: 1000,
        part_smt_count: 23,
        part_tht_count: 8,
        double_sided: false
      }

      expect(AislerPricing.price(203, args).cents).to eq(962_95)
    end
  end

  context 'regarding shipping prices' do
    it 'returns the standard tracked shipping if no country is given' do
      result = AislerPricing.tracked_shipping
      expect(result.cents).to eq(1500)
    end

    it 'returns the standard express shipping if no country is given' do
      result = AislerPricing.express_shipping
      expect(result.cents).to eq(2000)
    end

    it '.price calls the tracked_shipping method with the correct parameters' do
      args = {
        country_code: 'DE'
      }

      expect(AislerPricing).to receive(:tracked_shipping).with(args, 'EUR')

      AislerPricing.price(98, args)
    end

    it '.price calls the express_shipping method with the correct parameters' do
      args = {
        country_code: 'DE'
      }

      expect(AislerPricing).to receive(:express_shipping).with(args, 'EUR')

      AislerPricing.price(99, args)
    end

    context 'for Tier AA (Domestic Germany)' do
      it 'returns correct express price for Germany' do
        args = {
          country_code: 'DE'
        }

        result = AislerPricing.tracked_shipping(args)
        expect(result.cents).to eq(899)
      end

      it 'returns correct express price for Germany' do
        args = {
          country_code: 'DE'
        }

        result = AislerPricing.express_shipping(args)
        expect(result.cents).to eq(1699)
      end
    end

    context 'for Tier A countries' do
      tier_countries = %w[be lu nl at cz]

      tier_countries.map do |cc|
        it "returns correct tracked price for #{cc} (#{ISO3166::Country(cc).iso_short_name})" do
          args = {
            country_code: cc
          }

          result = AislerPricing.tracked_shipping(args).cents

          expect(result).to eq(1099)
        end

        it "returns correct express price for #{cc} (#{ISO3166::Country(cc).iso_short_name})" do
          args = {
            country_code: cc
          }

          result = AislerPricing.express_shipping(args).cents

          expect(result).to eq(1999)
        end
      end
    end

    context 'for Tier B countries' do
      tier_countries = %w[dk fr gb it cr ro sk si hu]

      tier_countries.map do |cc|
        it "returns correct tracked price for #{cc} (#{ISO3166::Country(cc).iso_short_name})" do
          args = {
            country_code: cc
          }

          result = AislerPricing.tracked_shipping(args).cents

          expect(result).to eq(1299)
        end

        it "returns correct express price for #{cc} (#{ISO3166::Country(cc).iso_short_name})" do
          args = {
            country_code: cc
          }

          result = AislerPricing.express_shipping(args).cents

          expect(result).to eq(3799)
        end
      end
    end

    context 'for Tier C countries' do
      tier_countries = %w[bg ee fi gr ir lt lv mt pt se es cy]

      tier_countries.map do |cc|
        it "returns correct tracked price for #{cc} (#{ISO3166::Country(cc).iso_short_name})" do
          args = {
            country_code: cc
          }

          result = AislerPricing.tracked_shipping(args).cents

          expect(result).to eq(1499)
        end

        it "returns correct express price for #{cc} (#{ISO3166::Country(cc).iso_short_name})" do
          args = {
            country_code: cc
          }

          result = AislerPricing.express_shipping(args).cents

          expect(result).to eq(4099)
        end
      end
    end

    context 'for Tier D countries' do
      tier_countries = %w[ad gg je no sm ch]

      tier_countries.map do |cc|
        it "returns correct tracked price for #{cc} (#{ISO3166::Country(cc).iso_short_name})" do
          args = {
            country_code: cc
          }

          result = AislerPricing.tracked_shipping(args).cents

          expect(result).to eq(2299)
        end

        it "returns correct express price for #{cc} (#{ISO3166::Country(cc).iso_short_name})" do
          args = {
            country_code: cc
          }

          result = AislerPricing.express_shipping(args).cents

          expect(result).to eq(4699)
        end
      end
    end

    context 'for Tier E countries' do
      tier_countries = %w[hk in ca mx tr ua ru ae cn]

      tier_countries.map do |cc|
        it "returns correct tracked price for #{cc} (#{ISO3166::Country(cc).iso_short_name})" do
          args = {
            country_code: cc
          }

          result = AislerPricing.tracked_shipping(args).cents

          expect(result).to eq(2699)
        end

        it "returns correct express price for #{cc} (#{ISO3166::Country(cc).iso_short_name})" do
          args = {
            country_code: cc
          }

          result = AislerPricing.express_shipping(args).cents

          expect(result).to eq(5399)
        end
      end
    end

    context 'for Tier F (Rest of the World) countries' do
      tier_countries =  %w[jp au]

      tier_countries.map do |cc|
        it "returns correct tracked price for #{cc} (#{ISO3166::Country(cc).iso_short_name})" do
          args = {
            country_code: cc
          }

          result = AislerPricing.tracked_shipping(args).cents

          expect(result).to eq(3699)
        end

        it "returns correct express price for #{cc} (#{ISO3166::Country(cc).iso_short_name})" do
          args = {
            country_code: cc
          }

          result = AislerPricing.express_shipping(args).cents

          expect(result).to eq(6199)
        end
      end
    end

    it 'return US tracked shipping price' do
      result = AislerPricing.tracked_shipping(country_code: 'US').cents
      expect(result).to eq(1499)
    end

    it 'returns PPP discount price' do
      result = AislerPricing.price(88).cents
      expect(result).to eq(-1000)
    end
  end
end
