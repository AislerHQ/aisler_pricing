RSpec.describe AislerPricing do
  it "has a version number" do
    expect(AislerPricing::VERSION).not_to be nil
  end

  it "should receive 2 layer PCB price in euros" do
    price = AislerPricing.board_price(1, 2)
    expect(price).to be_an_instance_of Money
    expect(price.cents).to eq(235) # Lowest price point

  end

  it "should receive 4 layer PCB price in euros" do
    # 1st price tier
    price = AislerPricing.board_price(1, 4)
    expect(price).to be_an_instance_of Money

    price *= 1.19
    expect(price.cents).to eq(559)

    # 2nd price tier
    price = AislerPricing.board_price(2000, 4)
    expect(price).to be_an_instance_of Money

    price *= 1.19
    expect(price.cents).to eq(1774)

    # 3rd price tier
    price = AislerPricing.board_price(10000, 4)
    expect(price).to be_an_instance_of Money

    price *= 1.19
    expect(price.cents).to eq(3225)
  end

  it 'should receive stencil price' do
    price = AislerPricing.stencil_price(width: 1, height: 1) # Really small stencil
    expect(price).to be_an_instance_of Money
    expect(price.cents).to eq(600) # Base price for stencils
    
    price = AislerPricing.stencil_price(width: 110, height: 70)
    expect(price).to be_an_instance_of Money
    expect(price.cents).to eq(1339)
    
    price = AislerPricing.stencil_price(width: 50, height: 60)
    expect(price).to be_an_instance_of Money
    expect(price.cents).to eq(1095)

    price = AislerPricing.stencil_price(width: 160, height: 100)
    expect(price).to be_an_instance_of Money
    expect(price.cents).to eq(1532)
    
    price = AislerPricing.stencil_price(width: 200, height: 200)
    expect(price).to be_an_instance_of Money
    expect(price.cents).to eq(1900)
    
    price = AislerPricing.stencil_price(width: 300, height: 300)
    expect(price).to be_an_instance_of Money
    expect(price.cents).to eq(3900)
  end

  it 'should receive stencil price as US Dollars' do
    price = AislerPricing.stencil_price(10, 'USD')
    expect(price.currency).to eq('USD')
    expect(price.cents).not_to eq(AislerPricing.stencil_price(10).cents)
  end

  it 'should receive PCB price as US Dollars' do
    price = AislerPricing.board_price(100, 2, 'USD')
    expect(price.currency).to eq('USD')
  end

  it 'should return 0 cents if layer count is not supported' do
    expect(AislerPricing.board_price(100, 6).cents).to eq(0)
  end

  it 'should support hash, array and area as input values for board price' do
    price_cents = 910
    expect(AislerPricing.board_price([100, 100], 2).cents).to eq(price_cents)
    expect(AislerPricing.board_price(10000, 2).cents).to eq(price_cents)
    expect(AislerPricing.board_price({ width: 100, height: 100 }, 2).cents).to eq(price_cents)
  end

  it 'should require EU Central Bank rates if prices are requested in different currencies than Euros or U.S. dollars' do
    expect { price = AislerPricing.stencil_price(10, 'CAD') }.to raise_error(Money::Bank::UnknownRate)

    AislerPricing.update_rates
    expect { price = AislerPricing.stencil_price(10, 'CAD') }.not_to raise_error
  end

  it 'should return prices for AISLER product codes' do
    expect(AislerPricing.price(105, area: 1).cents).to eq(235)
    expect(AislerPricing.price(155, area: 1600, cols: 4, rows: 4, quantity: 6).cents).to eq(2314)
  end

  it 'should calculate Perfect Panel prices' do
    expect(AislerPricing.panel_price(1600, 6, 4, 4, 155).cents).to eq(2314)
  end
end
