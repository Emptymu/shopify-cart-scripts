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

# Discount tier shuld follow the follwoing pattern
# [price_1_in_cents, price_2_in_cents] => percentage
TIERS = {
  [10000, 15000]  => 10,
  [15000, 25000] => 15,
  [25000, Float::INFINITY] => 20
}

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

def runCampaign(discount_code, tiers)
  if Input.cart.discount_code.code == discount_code
    # Stop campaign if the cart doesn't meet our requirement
    unless isApplicable?(tiers)
      Input.cart.discount_code.reject({ message: "Your cart does not meet the requirements for the #{Input.cart.discount_code.code} discount code!" })
      return
    end
    
    # Loop through all the discount info and apply discount to applicable items
    tiers.each do |tier|
      min_price = Money.new(cents: tier[0][0])
      max_price = Money.new(cents: tier[0][1])
      percentage = tier[1]
      message = "You've earned #{percentage}% off for spending more than $#{tier[0][0]/100}."
      
      next unless Input.cart.subtotal_price_was >= min_price and Input.cart.subtotal_price_was < max_price
      discount = PercentageDiscountPerLineItem.new(percentage, message)
        
      Input.cart.line_items.each do |line_item|
         discount.apply(line_item)
      end
    end
  end
end

runCampaign('TEST', TIERS)

Output.cart = Input.cart
