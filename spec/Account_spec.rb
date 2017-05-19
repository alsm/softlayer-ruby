#--
# Copyright (c) 2014 SoftLayer Technologies, Inc. All rights reserved.
#
# For licensing information see the LICENSE.md file in the project root.
#++

$LOAD_PATH << File.expand_path(File.join(File.dirname(__FILE__), "../lib"))

require 'rubygems'
require 'softlayer_api'
require 'rspec'

require 'spec_helper'

describe SoftLayer::Account do
	it "should exist" do
		expect(SoftLayer::Account).to_not be_nil
	end

  it "knows its id" do
    mock_client = SoftLayer::Client.new(:username => "fake_user", :api_key => "BADKEY")
    test_account = SoftLayer::Account.new(mock_client, "id" => 232279, "firstName" => "kangaroo")
    expect(test_account.id).to eq(232279)
  end

  it "identifies itself with the Account service" do
    mock_client = SoftLayer::Client.new(:username => "fake_user", :api_key => "BADKEY")
    allow(mock_client).to receive(:[]) do |service_name|
      expect(service_name).to eq :Account
      mock_service = SoftLayer::Service.new("SoftLayer_Account", :client => mock_client)

      # mock out call_softlayer_api_with_params so the service doesn't actually try to
      # communicate with the api endpoint
      allow(mock_service).to receive(:call_softlayer_api_with_params)

      mock_service
    end

    fake_account = SoftLayer::Account.new(mock_client, "id" => 12345)
    expect(fake_account.service.server_object_id).to eq(12345)
    expect(fake_account.service.target.service_name).to eq "SoftLayer_Account"
  end

  it "should allow the user to get the default account for a service" do
    test_client = double("mockClient")
    allow(test_client).to receive(:[]) do |service_name|
      expect(service_name).to eq :Account

      test_service = double("mockService")
      allow(test_service).to receive(:getObject) do
        { "id" => "232279", "firstName" => "kangaroo" }
      end

      test_service
    end

    test_account = SoftLayer::Account.account_for_client(test_client)
    expect(test_account.softlayer_client).to eq(test_client)
    expect(test_account.id).to eq("232279")
    expect(test_account.firstName).to eq("kangaroo")
  end

  describe "softlayer attributes" do
    let (:test_account) {
      mock_client = SoftLayer::Client.new(:username => "fakeuser", :api_key => "fake_api_key")
      SoftLayer::Account.new(mock_client, fixture_from_json("test_account"))
    }

    it "exposes a great many softlayer attributes" do
      expect(test_account.companyName).to eq "UpAndComing Software"
      expect(test_account.firstName).to eq "Don "
      expect(test_account.lastName).to eq "Joe"
      expect(test_account.address1).to eq "123 Main Street"
      expect(test_account.address2).to eq nil
      expect(test_account.city).to eq "Anytown"
      expect(test_account.state).to eq "TX"
      expect(test_account.country).to eq "US"
      expect(test_account.postalCode).to eq "778899"
      expect(test_account.officePhone).to eq "555.123.4567"
    end
  end

  it "fetches a list of open tickets" do
    mock_client = SoftLayer::Client.new(:username => "fakeuser", :api_key => "fake_api_key")
    account_service = mock_client[:Account]

    expect(account_service).to receive(:call_softlayer_api_with_params).with(:getOpenTickets, instance_of(SoftLayer::APIParameterFilter),[]) do
      fixture_from_json("test_tickets")
    end

    test_account = SoftLayer::Account.new(mock_client, fixture_from_json("test_account"))
    open_tickets = nil
    expect { open_tickets = test_account.open_tickets }.to_not raise_error
    ticket_ids = open_tickets.collect { |ticket| ticket.id }
    expect(ticket_ids.sort).to eq [12345, 12346, 12347, 12348, 12349].sort
  end

  describe "relationship to servers" do
    it "should respond to a request for servers" do
      mock_client = SoftLayer::Client.new(:username => "fakeuser", :api_key => "fake_api_key")
      account_service = mock_client[:Account]
      allow(account_service).to receive(:getObject).and_return(fixture_from_json("test_account"))
      allow(account_service).to receive(:call_softlayer_api_with_params) do |api_method, api_filter, arguments|
        case api_method
        when :getHardware
          fixture_bare_metal_data = fixture_from_json("test_bare_metal")
        when :getVirtualGuests
          fixture_from_json("test_virtual_servers")
        when :getObject
          fixture_from_json("test_account")
        end
      end

      test_account = SoftLayer::Account.account_for_client(mock_client)

      expect(test_account).to respond_to(:servers)
      expect(test_account).to_not respond_to(:servers=)

      servers = test_account.servers
      expect(servers.length).to eq(6)
    end
  end

  describe "Account.account_for_client" do
    it "raises an error if there is no client available" do
      SoftLayer::Client.default_client = nil
      expect {SoftLayer::Account.account_for_client}.to raise_error(RuntimeError)
    end

    it "uses the default client if one is available" do
      mock_client = SoftLayer::Client.new(:username => "fakeuser", :api_key => "fake_api_key")
      allow(mock_client).to receive(:[]) do |service_name|
        mock_service = Object.new()
        allow(mock_service).to receive(:getObject).and_return({"id" => 12345})
        mock_service
      end

      SoftLayer::Client.default_client = mock_client
      mock_account = SoftLayer::Account.account_for_client
      expect(mock_account).to be_instance_of(SoftLayer::Account)
      expect(mock_account.id).to be(12345)
    end
  end
end
