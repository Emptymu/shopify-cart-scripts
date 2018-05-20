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
  def initialize(selector, thresholds, discount)
    @selector = selector
    @thresholds = thresholds
    @discount = discount
  end

  def run(cart)
    discount = nil

    # Loop through all the threshold and generate applicable discount
    @thresholds.each do |threshold|
      next unless cart.subtotal_price_was.cents >= threshold[:spend]

      percentage = threshold[:percentage]
      message = "You've earned #{percentage}% off for spending more than $#{threshold[:spend]/100}."       
      discount = @discount.new(percentage, message)
    end

    applicable_items = cart.line_items.select do |line_item|
      @selector.match?(line_item)
    end
    
    if discount
      applicable_items.each do |line_item|
          discount.apply(line_item)
      end
    end
  end
end

# Define spending thresholds, from lowest spend to highest spend.
SPENDING_THRESHOLDS = [
  {
    spend: 100000,
    percentage: 10
  },
  {
    spend: 150000,
    percentage: 15
  },
  {
    spend: 300000,   # spend amount (in cents)
    percentage: 20   # percentage discount
  }
    
]

CAMPAIGNS = [
  TeiredCampaign.new(
    PlaceholderSelector.new(),
    SPENDING_THRESHOLDS,
    PercentageDiscountPerLineItem # a discount class
  )
]

# Iterate through each of the discount campaigns.
CAMPAIGNS.each do |campaign|
  # Apply the campaign onto the cart.
  campaign.run(Input.cart)
end

Output.cart = Input.cart