module SessionHelper
  def sign_in(resource)
    @external_id = resource.external_id
    post "/sso/login", params: login_params
  end

  private

  attr_reader :external_id, :timestamp

  def login_params
    @timestamp = Time.current.to_i.to_s
    {
      resource_id: resource.external_id,
      timestamp: timestamp,
      resource_token: token
    }
  end

  def token
    Digest::SHA1.hexdigest external_id + ":" + Rails.application.credentials.sso_salt + ":" + timestamp
  end
end
