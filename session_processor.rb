class SessionProcessor
  attr_accessor :session
  attr_accessor :params
  #Naveen: Holds unique token
  attr_accessor :unique_token

  def initialize(session,params)
    @session ||= session
    @session[:store_supplier_basis_tax] = session[:store_supplier_basis_tax]
    @session[:store_supplier_basis_tax] ||= []
    @params ||= params
    @unique_token||=[]

  end

  #TODO process order_sessions accordingly

  def hold_order_summary_data
    final_orders = []
    if session[:orders].blank?

      params[:orders].each{|current_order|
        is_commercial = current_order["is_commercial"] == "Yes"
        is_loading =  current_order["loading_dock"] == "Yes"
        weight_factor = current_order["order_weight"].to_i >= 100
        final_orders << current_order.merge(get_origin_data(is_loading,is_commercial,weight_factor))
      }
      return session[:orders] = final_orders
    else
      return session[:orders]
    end
  end

  def clear_ordersummary_data
    session.delete(:orders)
  end

  #Naveen: retrieving the order related information from session
  def get_order_data
    session[:orders]
  end

  #### SAVING CART #############
  def saving_order_summary(order_summary_details, groupid)
    order_summary_details.each do |save_cart|
      ShoppingCartItem.where(:group_id=>groupid.split.join(',')).each{ |ss|
       case
         when (!save_cart[:until_ship_date].blank? && !save_cart[:need_by_date].blank?)
           ss.update_attributes!(buyer_po:save_cart[:buyer_po], special_instruction: save_cart[:special_instruction], loading_dock:save_cart[:loading_dock], is_commercial:save_cart[:is_commercial], project_name:save_cart[:project_name], need_by_date: Date.strptime(save_cart[:need_by_date].to_s, "%m/%d/%Y"), until_ship_date: Date.strptime(save_cart[:until_ship_date].to_s, "%m/%d/%Y"))
         when (save_cart[:until_ship_date].blank? && !save_cart[:need_by_date].blank?)
          ss.update_attributes!(buyer_po:save_cart[:buyer_po], special_instruction: save_cart[:special_instruction], loading_dock:save_cart[:loading_dock], is_commercial:save_cart[:is_commercial], project_name:save_cart[:project_name], need_by_date: Date.strptime(save_cart[:need_by_date].to_s, "%m/%d/%Y"))
         when (!save_cart[:until_ship_date].blank? && save_cart[:need_by_date].blank?)
           ss.update_attributes!(buyer_po:save_cart[:buyer_po], special_instruction: save_cart[:special_instruction], loading_dock:save_cart[:loading_dock], is_commercial:save_cart[:is_commercial], project_name:save_cart[:project_name], until_ship_date: Date.strptime(save_cart[:until_ship_date].to_s, "%m/%d/%Y"))
         when (save_cart[:until_ship_date].blank? && save_cart[:need_by_date].blank?)
          ss.update_attributes!(buyer_po:save_cart[:buyer_po], special_instruction: save_cart[:special_instruction], loading_dock:save_cart[:loading_dock], is_commercial:save_cart[:is_commercial], project_name:save_cart[:project_name])
       end
     }

   end
  end
 #Naveen: method to generate unique tokens and store them in session
  def create_unique_tokens(supplier_ids,client_name)
    supplier_ids.each{|sid|
      session["order_no_#{sid}"] = Order.get_unique_token(client_name)
    }
  end

  #Naveen: combine cart orders with orders from parameters
  def merge_cart_params_with_session
    final_orders = []
    session[:orders].each{|order|
    supplier_id= order["supplier_id"]
    final_orders <<  order.merge(params[:orders].select{|order_data| order_data["supplier_id"].to_i == supplier_id.to_i}.first)
    }
    session[:orders] = final_orders
    final_orders
  end

  #Naveen: Storing credit card details
  def store_card_number
    session[:cvv] = params[:cvv]
    session[:cardNumber] = params[:cardNumber]
    session[:cardMonth] = params[:month]
    session[:cardYear] = params[:year]
  end

  def get_card_details
    [session[:cardNumber],session[:cvv],session[:cardMonth],session[:cardYear]]
  end

  def response_payment_token(transaction_id,id)
    current_order = session[:orders].select{|order_data| order_data["supplier_id"].to_i == id.to_i}.first
    current_order["payment_transaction_id"] = transaction_id
  end
  def response_tax_token(authorization,id)
    current_order = session[:orders].select{|order_data| order_data["supplier_id"].to_i == id.to_i}.first
    current_order["tax_transaction_id"] = authorization
  end

  def get_order_freight_details(id)
    current_order = session[:orders].select{|order_data| order_data["supplier_id"].to_i == id.to_i}.first
    is_commercial = current_order["is_commercial"] == "Yes"
    is_loading =  current_order["loading_dock"] == "Yes"
    weight_factor = current_order["order_weight"].to_i >= 80
    return get_origin_data(is_loading,is_commercial,weight_factor)
  end

    def heavy_freight_quote_amount(id)
    current_order = session[:orders].select{|order_data| order_data["supplier_id"].to_i == id.to_i}.first
    return current_order["order_weight"].to_i >= 70
  end

  def get_token(id)
    session["order_no_#{id}"]
  end
  #Naveen: Storing supplier based values in session
  def store_supplier_basis_tax=(id,val)
    session[:store_supplier_basis_tax][id] = val
  end
  def get_supplier_basis_tax(id)
    session[:store_supplier_basis_tax][id]
  end

  def clear_card_details
    session.delete(:cardNumber)
    session.delete(:cvv)
    session.delete(:cardMonth)
    session.delete(:cardYear)
  end

  #Naveen: getting order related date information
  def get_origin_data is_loading,is_commercial,weight_factor
    case
      when !weight_factor && !is_commercial && !is_loading
        return {loading_dock:"false", lift_gate:"false", is_residential: "true", is_construction: "false"}
      when !weight_factor && !is_commercial && is_loading
        return {loading_dock:"true", lift_gate:"false", is_residential: "true", is_construction: "false"}
      when !weight_factor && is_commercial && !is_loading
        return {loading_dock:"false", lift_gate:"false", is_residential: "false", is_construction: "false"}
      when !weight_factor && is_commercial && is_loading
        return {loading_dock:"true", lift_gate:"false", is_residential: "false", is_construction: "false"}
      when weight_factor && !is_commercial && !is_loading
        return {loading_dock:"false", lift_gate:"true", is_residential: "true", is_construction: "false"}
      when weight_factor && !is_commercial && is_loading
        return {loading_dock:"true", lift_gate:"false", is_residential: "true", is_construction: "false"}
      when weight_factor && is_commercial && !is_loading
        return {loading_dock:"false", lift_gate:"true", is_residential: "false", is_construction: "false"}
      when weight_factor && is_commercial && is_loading
        return {loading_dock:"true", lift_gate:"false", is_residential: "false", is_construction: "false"}
    end
  end

end