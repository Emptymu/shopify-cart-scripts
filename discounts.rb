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

class PercentageDiscountPerProduct
  def initialize(percent, message)
    # Calculate the percentage, while ensuring that Decimal values are used in
    # order to maintain precision.
    @percent = Decimal.new(percent) / 100.0
    @message = message
  end

  def apply(item_info)
    # line item to apply discount
    line_item = item_info['item'];
    # how many products to apply discount in this line item
    count = item_info['count'];
    
    # Calculate the discount for this line item
    line_discount = line_item.line_price * (1/line_item.quantity) * @percent * count

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

class FixAmountDiscountPerProduct
  def initialize(amount, message)
    # Calculate the percentage, while ensuring that Decimal values are used in
    # order to maintain precision.
    @amount = Money.new(cents: amount)
    @message = message
  end

  def apply(item_info)
    # line item to apply discount
    line_item = item_info['item'];
    # how many products to apply discount in this line item
    count = item_info['count'];
    
    # Calculate the discount for this line item
    line_discount = @amount * count

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
