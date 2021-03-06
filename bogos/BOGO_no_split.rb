# BOGO campaign without spliting line item
# Apply discount to individual products in a line item

class TagSelector
  def initialize(tag)
    @tag = tag
  end

  def match?(line_item)
    line_item.variant.product.tags.include?(@tag)
  end
end

class PlaceholderSelector
  def match?(line_item)
    return true
  end
end

class PercentageDiscountPerProduct
  def initialize(percent, message)
    # Calculate the percentage, while ensuring that Decimal values are used in
    # order to maintain precision.
    @percent = Decimal.new(percent) / 100.0
    @message = message
  end

  def apply(item_info)
    # line item to apply discount
    line_item = item_info[:item];
    # how many products to apply discount in this line item
    count = item_info[:count];
    
    # Calculate the discount for this line item
    line_discount = line_item.line_price * (1.0/line_item.quantity) * @percent * count

    # Calculated the discounted line price
    new_line_price = line_item.line_price - line_discount

    # Apply the new line price to this line item with a given message
    # describing the discount, which may be displayed in cart pages and
    # confirmation emails to describe the applied discount.
    line_item.change_line_price(new_line_price, message: @message)

    # Print a debugging line to the console
    puts "#{line_discount} off for #{count} products!"
  end
end


# - Select Y every X (not including X)
# - Low to high without split
class EveryXGetYNoSplit
  def initialize(paid_item_count, discounted_item_count)
    @paid_item_count = paid_item_count
    @discounted_item_count = discounted_item_count
  end

  def partition(cart, applicable_line_items)
    # Sort the items by price from low to high
    sorted_items = applicable_line_items.sort_by{|line_item| line_item.variant.price}
    # Find the total quantity of items
    total_applicable_quantity = sorted_items.map(&:quantity).reduce(0, :+)
    # Find the quantity of items that must be discounted
    discounted_items_remaining = Integer(total_applicable_quantity / (@paid_item_count + @discounted_item_count)) * @discounted_item_count +
                                  (total_applicable_quantity % (@paid_item_count + @discounted_item_count) > @paid_item_count ? total_applicable_quantity % (@paid_item_count + @discounted_item_count) - @paid_item_count : 0);
    
    # Create an array of items to return
    discounted_items = []

    # Loop over all the items and find those to be discounted
    sorted_items.each do |line_item|
      # Exit the loop if all discounted items have been found
      break if discounted_items_remaining <= 0
      # The item will be discounted
      discounted_item = {
        item: line_item,
        count: 0
      }
      
      if line_item.quantity > discounted_items_remaining
        # If the item has more quantity than what must be discounted
        discounted_item[:count] = discounted_items_remaining;
      else
        discounted_item[:count] = line_item.quantity
      end

      # Decrement the items left to be discounted
      discounted_items_remaining -= line_item.quantity
      
      # Add the item to be returned
      discounted_items.push(discounted_item)
    end
    #--- 
    # Return the items to be discounted
    discounted_items
  end
end

class BogoNoSplit
  def initialize(selector, discount, partitioner)
    @selector = selector
    @discount = discount
    @partitioner = partitioner
  end

  def run(cart)
    applicable_items = cart.line_items.select do |line_item|
      puts line_item.variant.product.tags
      @selector.match?(line_item)
    end
    
    discounted_items = @partitioner.partition(cart, applicable_items)

    discounted_items.each do |line_item|
      @discount.apply(line_item)
    end
  end
end

CAMPAIGNS = [
  BogoNoSplit.new(
    PlaceholderSelector.new(),
    PercentageDiscountPerProduct.new(100, "Buy 1 Get 1 Free"),
    EveryXGetYNoSplit.new(1,1)
  )
]

# Iterate through each of the discount campaigns.
CAMPAIGNS.each do |campaign|
  # Apply the campaign onto the cart.
  campaign.run(Input.cart)
end

Output.cart = Input.cart
