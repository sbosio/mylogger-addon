# frozen_string_literal: true

shared_examples 'an endpoint that requires basic auth' do
  context 'with the expected ACCEPT header' do
    context 'without credentials' do
      let(:headers) { { 'ACCEPT' => content_type } }

      it 'returns an unauthorized status code' do
        expect(response).to be_unauthorized
      end
    end

    context 'with wrong credentials' do
      let(:user_name) { FFaker::Internet.user_name }
      let(:password) { FFaker::Internet.password(16) }

      it 'returns an unauthorized status code' do
        expect(response).to be_unauthorized
      end
    end
  end

  context 'without the expected ACCEPT header' do
    let(:content_type) { 'application/json' }

    it 'returns a not found status code' do
      expect(response).to be_not_found
    end
  end
end
