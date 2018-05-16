# Tiered discount based on total spent before discount

class TagSelector
  def initialize(item)
    @item = item
  end

  def match?(line_item)
    return line_item.variant.product.tags.include?(@item)
  end
end

class PlaceholderSelector
  def match?(line_item)
    return true
  end
end

class PercentageDiscountPerLineItem
  def initialize(percent, message)
    # Calculate the percentage, while ensuring that Decimal values are used in
    # order to maintain precision.
    @percent = Decimal.new(percent) / 100.0
    @message = message
  end

  def apply(line_item)
    # Calculate the discount for this line item
    line_discount = line_item.line_price * @percent

    # Calculated the discounted line price
    new_line_price = line_item.line_price - line_discount

    # Apply the new line price to this line item with a given message
    # describing the discount, which may be displayed in cart pages and
    # confirmation emails to describe the applied discount.
    line_item.change_line_price(new_line_price, message: @message)

    # Print a debugging line to the console
    puts "Discounted line item with variant #{line_item.variant.id} by #{line_discount}."
  end
end

class TeiredCampaign
  def initialize(selector, tiers, discount)
    @selector = selector
    @tiers = tiers
    @discount = discount
  end
  
  def isApplicable?(tiers)
    # Min price to apply discount
    min_price = Float::INFINITY
  
    tiers.each do |tier|
      if tier[0][0] < min_price
        min_price = tier[0][0]
      end
    end
  
    return Input.cart.subtotal_price_was >= Money.new(cents: min_price)
  end
  
  def run(cart)
    unless isApplicable?(@tiers)
      return
    end
    
    # Loop through all the discount info and apply discount to applicable items
    @tiers.each do |tier|
      min_price = Money.new(cents: tier[0][0])
      max_price = Money.new(cents: tier[0][1])
      percentage = tier[1]
      message = "You've earned #{percentage}% off for spending more than $#{tier[0][0]/100}."
        
      next unless cart.subtotal_price_was >= min_price and cart.subtotal_price_was < max_price
      discount = @discount.new(percentage, message)
      
      applicable_items = cart.line_items.select do |line_item|
        @selector.match?(line_item)
      end
      
      applicable_items.each do |line_item|
          discount.apply(line_item)
      end
    end
  end
end

# Discount tier shuld follow the follwoing pattern
# [price_1_in_cents, price_2_in_cents] => percentage
TIERS = {
  [10000, 15000]           => 10,
  [15000, 25000]           => 15,
  [25000, Float::INFINITY] => 20
}

CAMPAIGNS = [
  TeiredCampaign.new(
    PlaceholderSelector.new(), # select all products
    TIERS,
    PercentageDiscountPerLineItem # a discount class
  )
]

# Iterate through each of the discount campaigns.
CAMPAIGNS.each do |campaign|
  # Apply the campaign onto the cart.
  campaign.run(Input.cart)
end

Output.cart = Input.cart
