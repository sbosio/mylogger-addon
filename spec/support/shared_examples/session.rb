# frozen_string_literal: true

shared_examples "a forbidden endpoint" do
  it "returns a forbidden status code" do
    expect(response).to be_forbidden
  end

  it "doesn't creates a session" do
    expect(request.session[:resource_id]).to be_nil
  end
end

shared_examples "an endpoint that requires an authenticated session" do
end
