class PaypalController < ApplicationController

  def new
    if params[:PayerID]
      session[:payer_id]= params[:PayerID]
    end
  end

  def checkout
    ppr = PayPal::Recurring.new({
                           :return_url   => 'https://morning-castle-2674.herokuapp.com/paypal/new',
                           :cancel_url   => "https://morning-castle-2674.herokuapp.com/",
                           :ipn_url     => "https://morning-castle-2674.herokuapp.com/paypal/notifier",
                           :description  => "Awesome - Monthly Subscription",
                           :amount       => "9.00",
                           :currency     => "USD"
                                 })
    response = ppr.checkout
    if response.valid?
      session[:token] = response.params[:TOKEN]
      redirect_to response.checkout_url
    else
      raise response.errors.inspect
    end
  end

  def subscribe
    prr = PayPal::Recurring.new({
                              :return_url   => 'https://morning-castle-2674.herokuapp.com/paypal/new',
                              :cancel_url   => "https://morning-castle-2674.herokuapp.com/",
                              :ipn_url     => "https://morning-castle-2674.herokuapp.com/paypal/notifier",
                              :description  => "Awesome - Monthly Subscription",
                              :amount       => "9.00",
                              :currency     => "USD",
                              :period       => "monthly",
                              :frequency    => "1",
                              :start_at => Time.zone.now,
                              :token => session[:token]
                          })
    @response = prr.create_recurring_profile
    redirect_to req_payment_path
  end

  def req_payment
    ppr = PayPal::Recurring.new({
                                    :token       => session[:token],
                                    :ipn_url     => "https://morning-castle-2674.herokuapp.com/paypal/notifier",
                                    :payer_id    => session[:payer_id],
                                    :amount      => "9.00",
                                    :description => "Awesome - Monthly Subscription"
                                })
    response = ppr.request_payment
  end

  def ipn
    puts "--------------------------------------------"
    ppr = PayPal::Recurring::Notification.new(params)
    puts "_________#{ppr.response}__________________"
  end
end


