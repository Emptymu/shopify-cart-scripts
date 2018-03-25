# Buy [x, y, z, ...] products, get discounted [a, b, c, ...] products

class ListHasItemSelector
  # Check if an list has an item

  def initialize(list)
    @list = list
  end

  def match?(item)
    return @list.include?(item)
  end
end

class BuyOneGetAnotherPartitioner
  def initialize(paid_item_count, discounted_item_count)
    @paid_item_count = paid_item_count
    @discounted_item_count = discounted_item_count
  end

  def partition(cart, paid_items, applicable_line_items)
    # Sort the items by price from low to high
    sorted_items = applicable_line_items.sort_by{|line_item| line_item.variant.price}
    # Find the total quantity of items
    total_applicable_quantity = sorted_items.map(&:quantity).reduce(0, :+)
    # Find the quantity of items that must be discounted
    discounted_items_remaining = @paid_item_count == 'any' ? @discounted_item_count : Integer(@discounted_item_count * (total_applicable_quantity - total_applicable_quantity%@paid_item_count)/@paid_item_count)

    # Create an array of items to return
    discounted_items = []

    # Loop over all the items and find those to be discounted
    sorted_items.each do |line_item|
      # Exit the loop if all discounted items have been found
      break if discounted_items_remaining == 0
      # The item will be discounted
      discounted_item = line_item
      if line_item.quantity > discounted_items_remaining
        # If the item has more quantity than what must be discounted, split it
        discounted_item = line_item.split(take: discounted_items_remaining)

        # Insert the newly-created item in the cart, right after the original item
        position = cart.line_items.find_index(line_item)
        cart.line_items.insert(position + 1, discounted_item)
      end

      # Decrement the items left to be discounted
      discounted_items_remaining -= discounted_item.quantity
      # Add the item to be returned
      discounted_items.push(discounted_item)
    end
  # Example
  # ------- Check to see if additional discount code is used. If used, add customer discount code and remove BOGO. Same applies if discount code is removed. Apply BOGO instead.
        cart_discounted_subtotal =
      case cart.discount_code
      when CartDiscount::Percentage
        if cart.subtotal_price >= cart.discount_code.minimum_order_amount
          cart.subtotal_price * ((Decimal.new(100) - cart.discount_code.percentage) / 100)
        else
          cart.subtotal_price
        end
      when CartDiscount::FixedAmount
        if cart.subtotal_price >= cart.discount_code.minimum_order_amount
          [cart.subtotal_price - cart.discount_code.amount, Money.new(0)].max
        else
          cart.subtotal_price
        end
      else
        cart.subtotal_price
      end
    #--- 
    # Return the items to be discounted
    discounted_items
  end
end

class BuyOneGetAnotherCampaign
  def initialize(paid_selector, applicable_selector, discount, partitioner)
    @paid_selector = paid_selector
    @applicable_selector = applicable_selector
    @discount = discount
    @partitioner = partitioner
  end
  
  def run(cart)
    paid_items = cart.line_items.select do |line_item|
      @paid_selector.match?(line_item.variant.product.id)
    end
    
    applicable_items = cart.line_items.select do |line_item|
      @applicable_selector.match?(line_item.variant.product.id)
    end
    
    discounted_items = @partitioner.partition(cart, paid_items, applicable_items)

    discounted_items.each do |line_item|
      @discount.apply(line_item)
    end
  end
end

CAMPAIGNS = [
  BuyOneGetAnotherCampaign.new(
    # product to buy id list
    ListHasItemSelector.new([9053469705, 9330752777, 8561828233]),
    # product to get id list
    ListHasItemSelector.new([8559595081]),
    PercentageDiscount.new(100, "Free Item!"),
    BuyOneGetAnotherPartitioner.new('any',1)
  )
]

# Iterate through each of the discount campaigns.
CAMPAIGNS.each do |campaign|
  # Apply the campaign onto the cart.
  campaign.run(Input.cart)
end

Output.cart = Input.cart
