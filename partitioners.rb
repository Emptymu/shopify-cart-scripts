# Low two high with split and select based on @paid_item_count nad @discounted_item_count
class Partitioner
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
    discounted_items_remaining = Integer(total_applicable_quantity / (@paid_item_count + @discounted_item_count) * @discounted_item_count)
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
    #--- 
    # Return the items to be discounted
    discounted_items
  end
end

# Low to high without split and select based on @paid_item_count and discounte_item_count
class PartitionerNoSplit
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
    discounted_items_remaining = Integer(total_applicable_quantity / (@paid_item_count + @discounted_item_count) * @discounted_item_count)
    
    # Create an array of items to return
    discounted_items = []

    # Loop over all the items and find those to be discounted
    sorted_items.each do |line_item|
      # Exit the loop if all discounted items have been found
      break if discounted_items_remaining <= 0
      # The item will be discounted
      discounted_item = {
        'item' => line_item,
        'count' => 0
      }
      
      if line_item.quantity > discounted_items_remaining
        # If the item has more quantity than what must be discounted
        discounted_item['count'] = discounted_items_remaining;
      else
        discounted_item['count'] = line_item.quantity
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

# Low to high with split and select every two items
class EveryXPartitioner
  def initialize(paid_item_count)
    @paid_item_count = paid_item_count
  end
  
  def partition(cart, applicable_line_items)
    # Sort the items by price from low to high
    sorted_items = applicable_line_items.sort_by{|line_item| line_item.variant.price}
    # Find the total quantity of items
    total_applicable_quantity = sorted_items.map(&:quantity).reduce(0, :+)
    # Find the quantity of items that must be discounted
    discounted_items_remaining = total_applicable_quantity - total_applicable_quantity % @paid_item_count
    
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

class EveryXGetYPartitioner
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
