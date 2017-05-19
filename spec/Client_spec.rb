#--
# Copyright (c) 2014 SoftLayer Technologies, Inc. All rights reserved.
#
# For licensing information see the LICENSE.md file in the project root.
#++

$LOAD_PATH << File.expand_path(File.join(File.dirname(__FILE__), '../lib'))

require 'rubygems'
require 'softlayer_api'
require 'rspec'

describe SoftLayer::Client do
  before do
    $SL_API_USERNAME = nil
    $SL_API_KEY = nil
    $SL_API_BASE_URL = nil
  end

  it 'accepts a user name from the global variable' do
    $SL_API_USERNAME = 'sample'
    client = SoftLayer::Client.new(:api_key => 'fake_key', :endpoint_url => 'http://fakeurl.org/')
    expect(client.username).to eq 'sample'
  end

  it 'accepts a username in options' do
    $SL_API_USERNAME = 'sample'
    client = SoftLayer::Client.new(:username => 'fake_user', :api_key => 'fake_key', :endpoint_url => 'http://fakeurl.org/')
    expect(client.username).to eq 'fake_user'
  end

  it 'accepts an api key from the global variable' do
    $SL_API_KEY = 'sample'
    client = SoftLayer::Client.new(:username => 'fake_user', :endpoint_url => 'http://fakeurl.org/')
    expect(client.api_key).to eq 'sample'
  end

  it 'accepts an api key in options' do
    $SL_API_KEY = 'sample'
    client = SoftLayer::Client.new(:username => 'fake_user', :api_key => 'fake_key', :endpoint_url => 'http://fakeurl.org/')
    expect(client.api_key).to eq 'fake_key'
  end

  it 'produces empty auth headers if the username is empty' do

    $SL_API_USERNAME = ''
    client = SoftLayer::Client.new(:api_key => 'fake_key', :endpoint_url => 'http://fakeurl.org/')

    expect(client.authentication_headers.empty?).to be true

    $SL_API_USERNAME = 'good_username'
    $SL_API_KEY = 'sample'
    client = SoftLayer::Client.new(:username => '', :api_key => 'fake_key', :endpoint_url => 'http://fakeurl.org/')

    expect(client.authentication_headers.empty?).to be true
  end

  it 'produces empty auth headers if the username is nil' do
    $SL_API_USERNAME = nil
    client = SoftLayer::Client.new(:username => nil, :api_key => 'fake_key', :endpoint_url => 'http://fakeurl.org/')

    expect(client.authentication_headers.empty?).to be true
  end

  it 'produces empty auth headers if the api_key is empty' do
    $SL_API_KEY = ''
    client = SoftLayer::Client.new(:username => 'fake_user', :endpoint_url => 'http://fakeurl.org/')

    expect(client.authentication_headers.empty?).to be true

    client = SoftLayer::Client.new(:username => 'fake_user', :api_key => '', :endpoint_url => 'http://fakeurl.org/')

    expect(client.authentication_headers.empty?).to be true
  end

  it 'produces empty auth headers if the api_key is nil' do
    $SL_API_KEY = nil
    client = SoftLayer::Client.new(:username => 'fake_user', :endpoint_url => 'http://fakeurl.org/', :api_key => nil)

    expect(client.authentication_headers.empty?).to be true
  end

  it 'initializes by default with nil as the timeout' do
    client = SoftLayer::Client.new(:username => 'fake_user', :api_key => 'fake_key', :endpoint_url => 'http://fakeurl.org/')
    expect(client.network_timeout).to be_nil
  end

  it 'Accepts a timeout given as a config parameter' do
    client = SoftLayer::Client.new(:username => 'fake_user', :api_key => 'fake_key', :endpoint_url => 'http://fakeurl.org/', :timeout => 60)
    expect(client.network_timeout).to eq 60
  end

  it 'gets the default endpoint even if none is provided' do
    $SL_API_BASE_URL = nil
    client = SoftLayer::Client.new(:username => 'fake_user', :api_key => 'fake_key')
    expect(client.endpoint_url).to eq SoftLayer::API_PUBLIC_ENDPOINT
  end

  it 'allows the default endpoint to be overridden by globals' do
    $SL_API_BASE_URL = 'http://someendpoint.softlayer.com/from/globals'
    client = SoftLayer::Client.new(:username => 'fake_user', :api_key => 'fake_key')
    expect(client.endpoint_url).to eq 'http://someendpoint.softlayer.com/from/globals'
  end

  it 'allows the default endpoint to be overriden by options' do
    $SL_API_BASE_URL = 'http://this/wont/be/used'
    client = SoftLayer::Client.new(:username => 'fake_user', :api_key => 'fake_key', :endpoint_url => 'http://fakeurl.org/')
    expect(client.endpoint_url).to eq 'http://fakeurl.org/'
  end

  it 'has a read/write user_agent property' do
    client = SoftLayer::Client.new(:username => 'fake_user', :api_key => 'fake_key', :endpoint_url => 'http://fakeurl.org/')
    expect(client).to respond_to(:user_agent)
    expect(client).to respond_to(:user_agent=)
  end

  it 'has a reasonable default user agent string' do
    client = SoftLayer::Client.new(:username => 'fake_user', :api_key => 'fake_key', :endpoint_url => 'http://fakeurl.org/')
    expect(client.user_agent).to eq "softlayer_api gem/#{SoftLayer::VERSION} (Ruby #{RUBY_PLATFORM}/#{RUBY_VERSION})"
  end

  it 'should allow the user agent to change' do
    client = SoftLayer::Client.new(:username => 'fake_user', :api_key => 'fake_key', :endpoint_url => 'http://fakeurl.org/')
    client.user_agent = "Some Random User Agent"
    expect(client.user_agent).to eq "Some Random User Agent"
  end

  describe "obtaining services" do
    let(:test_client) {
      SoftLayer::Client.new(:username => 'fake_user', :api_key => 'fake_key', :endpoint_url => 'http://fakeurl.org/')
    }

    it "should have a service_named method" do
      expect(test_client).to respond_to(:service_named)
    end

    it "should reject empty or nil service names" do
      expect { test_client.service_named('') }.to raise_error(ArgumentError)
      expect { test_client.service_named(nil) }.to raise_error(ArgumentError)
    end

    it "should be able to construct a service" do
      test_service = test_client.service_named('Account')
      expect(test_service).to_not be_nil
      expect(test_service.service_name).to eq "SoftLayer_Account"
      expect(test_service.client).to be(test_client)
    end

    it "allows bracket dereferences as an alternate service syntax" do
      test_service = test_client[:Account]
      expect(test_service).to_not be_nil
      expect(test_service.service_name).to eq "SoftLayer_Account"
      expect(test_service.client).to be(test_client)
    end

    it "returns the same service repeatedly when asked more than once" do
      first_account_service = test_client[:Account]
      second_account_service = test_client.service_named('Account')

      expect(first_account_service).to be(second_account_service)
    end

    it "recognizes a symbol as an acceptable service name" do
      account_service = test_client[:Account]
      expect(account_service).to_not be_nil

      trying_again = test_client[:Account]
      expect(trying_again).to be(account_service)

      yet_again = test_client[:SoftLayer_Account]
      expect(yet_again).to be(account_service)

      once_more = test_client[:SoftLayer_Account]
      expect(once_more).to be(account_service)
    end

  end
end
