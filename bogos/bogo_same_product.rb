# BOGO for same products

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

# - Every X select Y (not including X)
# - Low to high with split
class EveryXGetY
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
    #--- 
    # Return the items to be discounted
    discounted_items
  end
end

class BogoSameProduct
  def initialize(selector, discount, partitioner)
    @selector = selector
    @discount = discount
    @partitioner = partitioner
  end
  
  def build_items_map(eligible_items)
    sorted_items_map = {}
    
    eligible_items.each do |line_item|
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
    eligible_items = cart.line_items.select do |line_item|
      @selector.match?(line_item)
    end
    
    applicable_items_map =  build_items_map(eligible_items)
    
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
  BogoSameProduct.new(
    PlaceholderSelector.new(),
    PercentageDiscount.new(100, "Buy 1 Get 1 free"),
    EveryXGetY.new(1, 1)
  )
]

# Iterate through each of the discount campaigns.
CAMPAIGNS.each do |campaign|
  # Apply the campaign onto the cart.
  campaign.run(Input.cart)
end

Output.cart = Input.cart