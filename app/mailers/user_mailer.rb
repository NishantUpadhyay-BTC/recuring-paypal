class UserMailer < ActionMailer::Base
  default from: "demo4582@gmail.com"

  def notify_me(params)
    @original_response  = OpenStruct.new(params)
    open_struct_instance_mathods = OpenStruct.instance_methods
    @response = (@original_response.methods - open_struct_instance_mathods).reject{|m|m =~ /=$/}
    mail(to: 'nishantupadhyay26@gmail.com', from: "demo4582@gmail.com", subject: "TRANSACTION OF  is completed")
  end
end
