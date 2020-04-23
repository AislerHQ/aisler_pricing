RSpec.describe AislerPricing do
  it "has a version number" do
    expect(AislerPricing::VERSION).not_to be nil
  end

  it "should receive 2 layer PCB price in euros" do
    price = AislerPricing.board_price([1, 1], 3, 105)
    expect(price).to be_an_instance_of Money
    expect(price.cents).to eq(280) # Lowest price point

  end

  it "should receive 4 layer PCB price in euros", focus: true do
    price = AislerPricing.board_price(1, 3, 107)
    expect(price).to be_an_instance_of Money

    price *= 1.19
    expect(price.cents).to eq(333)

    price = AislerPricing.board_price(2000, 3, 107)
    expect(price).to be_an_instance_of Money

    price *= 1.19
    expect(price.cents).to eq(845)

    price = AislerPricing.board_price([300, 200], 3, 107)
    expect(price).to be_an_instance_of Money

    price *= 1.19
    expect(price.cents).to eq(15684)
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
    price = AislerPricing.board_price(100, 3, 105, 'USD')
    expect(price.currency).to eq('USD')
  end

  it 'should support hash, array and area as input values for board price' do
    price_cents = 1060
    expect(AislerPricing.board_price([100, 100], 3, 105).cents).to eq(price_cents)
    expect(AislerPricing.board_price(10000, 3, 105).cents).to eq(price_cents)
    expect(AislerPricing.board_price({ width: 100, height: 100 }, 3, 105).cents).to eq(price_cents)
  end

  it 'should require EU Central Bank rates if prices are requested in different currencies than Euros or U.S. dollars' do
    expect { price = AislerPricing.stencil_price(10, 'CAD') }.to raise_error(Money::Bank::UnknownRate)

    AislerPricing.update_rates
    expect { price = AislerPricing.stencil_price(10, 'CAD') }.not_to raise_error
  end

  it 'should return prices for AISLER product codes' do
    expect(AislerPricing.price(105, area: 1, quantity: 3).cents).to eq(280)
    expect(AislerPricing.price(155, area: 1600, cols: 4, rows: 4, quantity: 6).cents).to eq(2314)
  end

  it 'should calculate Perfect Panel prices' do
    expect(AislerPricing.panel_price(1600, 6, 4, 4, 155).cents).to eq(2314)
  end
end
