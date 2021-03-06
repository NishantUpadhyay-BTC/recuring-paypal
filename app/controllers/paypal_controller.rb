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

  def notifier
    # puts '==============='
    # puts "REQUEST_OBJ:::::#{request.raw_post}"
    # response = validate_IPN_notification(request.raw_post)
    # puts "RESPONSE INSIDE NOTIFIER::::::::::::::::::#{response.inspect}"
    # case response
    #   when "VERIFIED"
    #
    #     puts "INSPECT:#{response.inspect}"
    #     puts "BODY:::#{response.body}"
    #   # check that paymentStatus=Completed
    #   # check that txnId has not been previously processed
    #   # check that receiverEmail is your Primary PayPal email
    #   # check that paymentAmount/paymentCurrency are correct
    #   # process payment
    #   when "INVALID"
    #
    #     puts "INSPECT:#{response.inspect}"
    #     puts "BODY:::#{response.body}"
    #   # log for investigation
    #   else
    #     # error
    # end
    # render :nothing => true

    puts "________________#{params}_________________"
      # PaymentsNotification.create!(:params => params.to_json.gsub("\"", "'"), :status => params[:payment_status], :transaction_id => params[:txn_id])
    ppr = PayPal::Recurring::Notification.new(params)
    t = ppr.response #send back the response to confirm IPN, stops further IPN notifications from being sent out
    puts "#{t.inspect}"
    puts "#{t.body}"

    puts "IS verified?????#{ppr.verified?}"
    puts "IS completed?????#{ppr.completed?}"

    if ppr.verified? && ppr.completed?

      puts "IS EXPRESS CHECKOUT?????#{ppr.express_checkout?}"
      puts "IS RECCURING CHECKOUT?????#{ppr.recurring_payment?}"

      if ppr.express_checkout? || ppr.recurring_payment?
        puts "**************Inside verified****************"
        y = UserMailer.notify_me(params).deliver
        puts "!!!!!!!!!!#{y}!!!!!!!!"
      end
    else
      puts "^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^"
      raise response.errors
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
    render :nothing => true
  end

  private

  def validate_IPN_notification(raw)
    puts "INSIDE VALIDATE IPN METHOD"
    begin
    uri = URI.parse('https://www.sandbox.paypal.com/cgi-bin/webscr?cmd=_notify-validate')
    http = Net::HTTP.new(uri.host, uri.port)
    http.open_timeout = 60
    http.read_timeout = 60

    http.use_ssl = true
    response = http.post(uri.request_uri, raw,
                         'Content-Length' => "#{raw.size}"
    )
    rescue => e
      response = e
      puts "EXCEPTION::::#{e}"
    end
    puts "RESPONSE FROM PAYPAL:::#{response.body}"
    response
  end
end


