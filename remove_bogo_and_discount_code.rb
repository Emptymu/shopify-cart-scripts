# Example
  # ------- Check to see if additional discount code is used. If used, add customer discount code and remove BOGO. Same applies if discount code is removed. Apply BOGO instead.
  # ------- insert this into partationers before returning discounted_items
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
