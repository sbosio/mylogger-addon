# frozen_string_literal: true

shared_examples "a Heroku::ApiController endpoint" do
  it "responds with valid JSON" do
    expect { response.body.present? && JSON.parse(response.body) }.not_to raise_error
  end

  it "responds with valid content type" do
    expect(response.no_content? || response.headers["Content-Type"].include?(Heroku::MimeType::ADDON_PARTNER_API)).to be(true)
  end
end
