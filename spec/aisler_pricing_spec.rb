RSpec.describe AislerPricing do
  it "has a version number" do
    expect(AislerPricing::VERSION).not_to be nil
  end

  it "should receive 2 layer PCB price in euros" do
    price = AislerPricing.board_price(area: 1, quantity: 3, product_uid: 105)
    expect(price).to be_an_instance_of Money
    expect(price.cents).to eq(1020) # Lowest price point
  end

  it "should receive 4 layer PCB price in euros", focus: true do
    price = AislerPricing.board_price(area: 1, quantity: 3, product_uid: 107)
    expect(price).to be_an_instance_of Money

    price *= 1.19
    expect(price.cents).to eq(1464)

    price = AislerPricing.board_price(area: 2000, quantity: 3, product_uid: 107)
    expect(price).to be_an_instance_of Money

    price *= 1.19
    expect(price.cents).to eq(2785)

    price = AislerPricing.board_price(area: 60000, quantity: 3, product_uid: 107)
    expect(price).to be_an_instance_of Money

    price *= 1.19
    expect(price.cents).to eq(41091)
  end

  it 'should receive stencil price' do
    price = AislerPricing.stencil_price(width: 1, height: 1) # Really small stencil
    expect(price).to be_an_instance_of Money
    expect(price.cents).to eq(1000) # Base price for stencils

    price = AislerPricing.stencil_price(width: 110, height: 70, smd_pad_count_top: 10, smd_pad_count_bottom: 10)
    expect(price).to be_an_instance_of Money
    expect(price.cents).to eq(2463)

    price = AislerPricing.stencil_price(width: 50, height: 60)
    expect(price).to be_an_instance_of Money
    expect(price.cents).to eq(1285)

    price = AislerPricing.stencil_price(width: 160, height: 100)
    expect(price).to be_an_instance_of Money
    expect(price.cents).to eq(2520)

    price = AislerPricing.stencil_price(width: 200, height: 200)
    expect(price).to be_an_instance_of Money
    expect(price.cents).to eq(4800)

    price = AislerPricing.stencil_price(width: 300, height: 300)
    expect(price).to be_an_instance_of Money
    expect(price.cents).to eq(9550)
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
    price_cents = 3540
    expect(AislerPricing.board_price(area: 10000, quantity: 3, product_uid: 105).cents).to eq(price_cents)
    expect(AislerPricing.board_price(area: 10000, quantity: 3, product_uid: 105).cents).to eq(price_cents)
    expect(AislerPricing.board_price( { width: 100, height: 100, quantity: 3, product_uid: 105} ).cents).to eq(price_cents)
  end

  it 'should require EU Central Bank rates if prices are requested in different currencies than Euros or U.S. dollars' do
    expect { price = AislerPricing.stencil_price({ area: 10 }, 'CAD') }.to raise_error(Money::Bank::UnknownRate)

    AislerPricing.update_rates
    expect { price = AislerPricing.stencil_price({ area: 10 }, 'CAD') }.not_to raise_error
  end

  it 'should return prices for AISLER product codes' do
    expect(AislerPricing.price(105, area: 1, quantity: 3).cents).to eq(1020)
    expect(AislerPricing.price(103, area: 1600, smd_pad_count_top: 10, smd_pad_count_bottom: 0).cents).to eq(1152)
  end

  it 'output prices for uC net listing' do
    [
      { width: 160, height: 100, quantity: 3, product_uid: 105 },
      { width: 20, height: 20, quantity: 3, product_uid: 107 },
      { width: 60, height: 50, quantity: 3, product_uid: 107 },
      { width: 160, height: 100, quantity: 3, product_uid: 107 },
      { width: 20, height: 20, quantity: 100, product_uid: 106 },
    ].each { |args| puts (AislerPricing.board_price(args) * 1.19).format }
  end

  it 'should return prices for Precious Parts in EUR' do
    args = {
      bom_price_cents: 1337
    }
    expect(AislerPricing.price(102, args).cents).to eq(1838)
  end

  it 'should return prices for Precious Parts in other currency' do
    args = {
      bom_price_cents: 1337,
      currency: 'USD'
    }

    result = AislerPricing.price(102, args)
    expect(result.currency).to eq(args[:currency])
  end

  it 'should return zero value for Precious Parts if no parts are included' do
    args = {
      bom_price_cents: 0
    }
    expect(AislerPricing.price(102, args).cents).to eq(0)
  end

  context 'regarding shipping prices' do
    it 'should return the standard express shipping' do
      result = AislerPricing.price(99)
      expect(result.cents).to eq(1500)
    end

    it 'should return correct express price for Germany' do
      args = {
        country_code: 'DE'
      }

      result = AislerPricing.price(99, args)
      expect(result.cents).to eq(799)
    end

    it 'should return correct express price for Tier A countries' do
      tier_countries = %w[be lu nl at cz]

      results = tier_countries.map do |cc|
        args = {
          country_code: cc
        }

        AislerPricing.price(99, args).cents
      end

      expect(results).to all(eq(899))
    end

    it 'should return correct express price for Tier B countries' do
      tier_countries = %w[dk fr gb it cr ro sk si hu]

      results = tier_countries.map do |cc|
        args = {
          country_code: cc
        }

        AislerPricing.price(99, args).cents
      end

      expect(results).to all(eq(1099))
    end

    it 'should return correct express price for Tier C countries' do
      tier_countries = %w[bg ee fi gr ir lt lv mt pt se es cy]

      results = tier_countries.map do |cc|
        args = {
          country_code: cc
        }

        AislerPricing.price(99, args).cents
      end

      expect(results).to all(eq(1299))
    end

    it 'should return correct express price for Tier D countries' do
      tier_countries = %w[ad gg je no sm ch]

      results = tier_countries.map do |cc|
        args = {
          country_code: cc
        }

        AislerPricing.price(99, args).cents
      end

      expect(results).to all(eq(1999))
    end

    it 'should return correct express price for Tier E countries' do
      tier_countries = %w[hk in ca mx tr ua ru ae us cn]

      results = tier_countries.map do |cc|
        args = {
          country_code: cc
        }

        AislerPricing.price(99, args).cents
      end

      expect(results).to all(eq(2399))
    end

    it 'should return correct express price for Tier F (RotW) countries' do
      tier_countries = %w[jp au]

      results = tier_countries.map do |cc|
        args = {
          country_code: cc
        }

        AislerPricing.price(99, args).cents
      end

      expect(results).to all(eq(3299))
    end
  end
end
