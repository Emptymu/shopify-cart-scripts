# Buy one product get this one and another one discounted

class PercentageDiscount

  def initialize(percent, message)
    @percent = Decimal.new(percent) / 100.0
    @message = message
  end

  def apply(line_item)
    line_discount = line_item.line_price * @percent

    new_line_price = line_item.line_price - line_discount

    line_item.change_line_price(new_line_price, message: @message)

    puts "Discounted line item with variant #{line_item.variant.id} by #{line_discount}."
  end
end

class LowToHighPartitioner
  def partition(cart, applicable_line_items)
    # Sort the items by price from low to high
    sorted_items = applicable_line_items.sort_by{|line_item| line_item.variant.price}
    # Find the total quantity of items
    total_applicable_quantity = sorted_items.map(&:quantity).reduce(0, :+)
    # Find the quantity of items that must be discounted
    if total_applicable_quantity > 1
      discounted_items_remaining = total_applicable_quantity % 2 == 0 ? total_applicable_quantity : total_applicable_quantity - 1
    else
      discounted_items_remaining = 0
    end
    
    puts discounted_items_remaining
    
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

class BogoCampaign
  def initialize(discount, partitioner)
    @discount = discount
    @partitioner = partitioner
  end
  
  def build_items_map(cart)
    sorted_items_map = {}
    
    cart.line_items.each do |line_item|
      id = line_item.variant.product.id
      item_to_add = line_item
      
      new_item = nil
      
      # add the first line_item
      if sorted_items_map.size == 0
        sorted_items_map[id] = Array.new(1, item_to_add);
      else
        #puts '-----'
        #puts "id: #{id}"
        #puts "old_map: #{sorted_items_map}"
        
        sorted_items_map.each do |key, sorted_items|
          #puts "items: #{sorted_items}"
          # loop through all items to see if we need to expand any
          if key == id
            #puts "will expand #{sorted_items}"
            sorted_items.push(item_to_add)
            # only expand once  
            item_to_add = nil
          
          elsif !sorted_items_map.include?(id) and item_to_add
            #puts "will add [#{id}] to map"
            # only add to map once
            new_item = {
              id => Array.new(1, item_to_add)
            };
            
            item_to_add = nil
          end
        end
        
        # We have to update the map out site the above loop
        if new_item
          #puts new_item
          sorted_items_map = sorted_items_map.merge(new_item)
        end
        
        #puts "new_map: #{sorted_items_map}"
        #puts '-----'
      end
    end
    
    return sorted_items_map
  end

  def run(cart)
    applicable_items_map =  build_items_map(cart)
    
    applicable_items_map.each do |key, value|
      applicable_items = value
      discount_items = @partitioner.partition(cart, applicable_items)
      
      discount_items.each do |item|
        @discount.apply(item)
      end
    end
  end
end

CAMPAIGNS = [
  BogoCampaign.new(
    PercentageDiscount.new(50, "Buy two Get two 50% off"),
    LowToHighPartitioner.new()
  )
]

# Iterate through each of the discount campaigns.
CAMPAIGNS.each do |campaign|
  # Apply the campaign onto the cart.
  campaign.run(Input.cart)
end

Output.cart = Input.cart
