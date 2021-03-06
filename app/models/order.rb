class Order < ActiveRecord::Base
  attr_accessible :status, :address, :address_id
  
  has_many :order_items, :dependent => :destroy
  belongs_to :user
  belongs_to :address
  
  def editable?
    self.status != "submitted"
  end
  
  def total
    #order_items.collect{|order_item| order_item.subtotal}.sum
    #order_items.inject(0){|total, item| total + item.subtotal}
    order_items.collect(&:subtotal).sum
  end
  
  def build_or_increment_order_item_by_product_id(product_id)
    order_item = order_items.find_or_initialize_by_product_id(product_id,
                      :quantity => OrderItem::DEFAULT_QUANTITY)    
    order_item.quantity += 1 unless order_item.new_record?
    return order_item
  end
  
  def create_or_increment_order_item_by_product_id(product_id)
    order_item = build_or_increment_order_item_by_product_id(product_id)
    order_item.save!
    return order_item
  end
  
  def user_logs_out
    self.user = nil
    save
  end
  
  def user_logs_in(user)
    self.user = user
    save    
  end
  
  def merge_items_from_order_id(target_id)
    target = self.user.orders.find(target_id)
    target.order_items.each do |item|
      existing_item = order_items.find_by_product_id(item.product_id)
      unless existing_item.nil?
        existing_item.quantity += item.quantity
        existing_item.save
      else
        item.order = self
        item.save
      end
    end
    target.reload.destroy
  end
  
end
