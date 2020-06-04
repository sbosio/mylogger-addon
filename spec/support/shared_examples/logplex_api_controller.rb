# frozen_string_literal: true

shared_examples "a Logplex::ApiController endpoint" do
  it "responds with an empty body" do
    expect(response.body).not_to be_present
  end

  it "responds with a content length of zero" do
    expect(response.headers["Content-Length"].to_i).to be_zero
  end
end
