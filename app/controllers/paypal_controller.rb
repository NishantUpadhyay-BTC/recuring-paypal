class PaypalController < ApplicationController
  protect_from_forgery :except => [:notifier] #Otherwise the request from PayPal wouldn't make it to the controller
  def new
    if params[:PayerID]
      session[:payer_id]= params[:PayerID]
    end
  end

  def checkout
    ppr = PayPal::Recurring.new({
                           :return_url   => 'https://morning-castle-2674.herokuapp.com/paypal/new',
                           :cancel_url   => "https://morning-castle-2674.herokuapp.com/",
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

  def notifier
    puts '==============='
    response = validate_IPN_notification(request.raw_post)
    puts "response.inspect"
    case response
      when "VERIFIED"
        puts response.inspect
      # check that paymentStatus=Completed
      # check that txnId has not been previously processed
      # check that receiverEmail is your Primary PayPal email
      # check that paymentAmount/paymentCurrency are correct
      # process payment
      when "INVALID"
        puts response.inspect
      # log for investigation
      else
        # error
    end
    render :nothing => true
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

  private
  def validate_IPN_notification(raw)
    puts "INSIDE VALIDATE IPN METHOD"
    begin
    uri = URI.parse('https://www.paypal.com/cgi-bin/webscr?cmd=_notify-validate')
    http = Net::HTTP.new(uri.host, uri.port)
    http.open_timeout = 60
    http.read_timeout = 60

    http.use_ssl = true
    response = http.post(uri.request_uri, raw,
                         'Content-Length' => "#{raw.size}"
    )
    rescue => e
      response = e
    end
    puts "RESPONSE FROM PAYPAL:::#{response.body}"
    response
  end
end


