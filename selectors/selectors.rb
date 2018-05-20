class ListHasItemSelector
  # Check if an item is in a list
  # e.g. product tag, sku, line_item
  def initialize(item)
    @item = item
  end

  def match?(list)
    return list.include?(@item)
  end
end

class ListHasItemSelector
  # Check if an list has an item
  # e.g. check if line item ID in an ID list

  def initialize(list)
    @list = list
  end

  def match?(item)
    return @list.include?(item)
  end
end
