# encoding: ascii-8bit

# Copyright 2021 Ball Aerospace & Technologies Corp.
# All Rights Reserved.
#
# This program is free software; you can modify and/or redistribute it
# under the terms of the GNU Affero General Public License
# as published by the Free Software Foundation; version 3 with
# attribution addendums as found in the LICENSE.txt
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# This program may also be used under the terms of a commercial or
# enterprise edition license of COSMOS if purchased from the
# copyright holder

require 'rails_helper'
require 'cosmos/models/timeline_model'

RSpec.describe ActivityController, :type => :controller do
  before(:each) do
    mock_redis()
  end

  def generate_activity(start)
      dt = DateTime.now.new_offset(0)
      start_time = dt + (start/24.0)
      stop_time = dt + ((start+1.0)/24.0)
      post_hash = {
        "start" => start_time.to_s,
        "stop" => stop_time.to_s,
        "kind" => "cmd",
        "data" => {"test"=>"test"}
      }
      json = JSON.generate(post_hash)
  end

  describe "GET index" do
    it "returns an empty array and status code 200" do
      request.headers["Authorization"] = "foobar"
      json = generate_activity(200.0)
      post :create, params: {"scope"=>"DEFAULT", "name"=>"test", "json"=>json}
      expect(response).to have_http_status(:created)
      get :index, params: {"scope"=>"DEFAULT", "name"=>"test"}
      json = JSON.parse(response.body)
      expect(json).to eql([])
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET index" do
    it "returns an array and status code 200" do
      request.headers["Authorization"] = "foobar"
      json = generate_activity(50.0)
      post :create, params: {"scope"=>"DEFAULT", "name"=>"test", "json"=>json}
      expect(response).to have_http_status(:created)
      start = DateTime.now.new_offset(0) + 2.0 # add two days
      stop = start + (4.0/24.0) # add four hours to the start time
      get :index, params: {"scope"=>"DEFAULT", "name"=>"test", "start"=>start.to_s, "stop"=>stop.to_s}
      json = JSON.parse(response.body)
      expect(response).to have_http_status(:ok)
      expect(json.empty?).to eql(false)
      expect(json.length).to eql(1)
    end
  end

  describe "GET count" do
    it "returns a json hash of name and count and status code 200" do
      request.headers["Authorization"] = "foobar"
      get :count, params: {"scope"=>"DEFAULT", "name"=>"test"}
      json = JSON.parse(response.body)
      expect(json["name"]).to eql("test")
      expect(json["count"]).to eql(0)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST create" do
    it "returns a hash and status code 201" do
      request.headers["Authorization"] = "foobar"
      json = generate_activity(1.0)
      post :create, params: {"scope"=>"DEFAULT", "name"=>"test", "json"=>json}
      ret = JSON.parse(response.body)
      expect(ret["updated_at"]).not_to be_nil
      expect(ret["duration"]).to eql(3600)
      expect(ret["start"]).not_to be_nil
      expect(ret["stop"]).not_to be_nil
      expect(response).to have_http_status(:created)
    end
  end

  describe "POST create bad json" do
    it "returns a hash and status code 400" do
      request.headers["Authorization"] = "foobar"
      post :create, params: {"scope"=>"DEFAULT", "name"=>"test", "json"=>"TEST"}
      ret = JSON.parse(response.body)
      expect(ret["status"]).to eql("error")
      expect(ret["message"]).not_to be_nil
      expect(response).to have_http_status(400)
    end
  end

  describe "POST create negative" do
    it "returns a hash and status code 400" do
      request.headers["Authorization"] = "foobar"
      json = generate_activity(-1.0)
      post :create, params: {"scope"=>"DEFAULT", "name"=>"test", "json"=>json}
      ret = JSON.parse(response.body)
      expect(ret["status"]).to eql("error")
      expect(ret["message"]).not_to be_nil
      expect(response).to have_http_status(400)
    end
  end

  describe "POST create longer than a day" do
    it "returns a hash and status code 400" do
      request.headers["Authorization"] = "foobar"
      dt = DateTime.now.new_offset(0)
      dt_start = dt + (1.0/24.0)
      dt_stop = dt + 2.0
      post_hash = {
        "start" => dt_start.to_s,
        "stop" => dt_stop.to_s,
        "kind" => "cmd",
        "data" => {"test"=>"test"}
      }
      json = JSON.generate(post_hash)
      post :create, params: {"scope"=>"DEFAULT", "name"=>"test", "json"=>json}
      ret = JSON.parse(response.body)
      expect(ret["status"]).to eql("error")
      expect(ret["message"]).not_to be_nil
      expect(response).to have_http_status(400)
    end
  end

  describe "POST create missing values" do
    it "returns a hash and status code 400" do
      request.headers["Authorization"] = "foobar"
      post :create, params: {"scope"=>"DEFAULT", "name"=>"test", "json"=>"{}"}
      ret = JSON.parse(response.body)
      expect(ret["status"]).to eql("error")
      expect(ret["message"]).not_to be_nil
      expect(response).to have_http_status(400)
    end
  end

  describe "POST overwrite another" do
    it "returns a hash and status code 409" do
      request.headers["Authorization"] = "foobar"
      json = generate_activity(1.0)
      post :create, params: {"scope"=>"DEFAULT", "name"=>"test", "json"=>json}
      expect(response).to have_http_status(:created)
      post :create, params: {"scope"=>"DEFAULT", "name"=>"test", "json"=>json}
      ret = JSON.parse(response.body)
      expect(ret["status"]).to eql("error")
      expect(ret["message"]).not_to be_nil
      expect(response).to have_http_status(409)
    end
  end

  describe "POST event" do
    it "returns a hash and status code 200" do
      request.headers["Authorization"] = "foobar"
      json = generate_activity(1.0)
      post :create, params: {"scope"=>"DEFAULT", "name"=>"test", "json"=>json}
      expect(response).to have_http_status(:created)
      created = JSON.parse(response.body)
      expect(created["start"]).not_to be_nil
      json = JSON.generate({"status"=>"valid", "message"=>"external event update"})
      post :event, params: {"scope"=>"DEFAULT", "name"=>"test", "id"=>created["start"], "json"=>json}
      ret = JSON.parse(response.body)
      expect(ret["events"].empty?).to eql(false)
      expect(ret["events"].length).to eql(2)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET show" do
    it "returns a hash and status code 200" do
      request.headers["Authorization"] = "foobar"
      json = generate_activity(1.0)
      post :create, params: {"scope"=>"DEFAULT", "name"=>"test", "json"=>json}
      expect(response).to have_http_status(:created)
      created = JSON.parse(response.body)
      expect(created["start"]).not_to be_nil
      get :show, params: {"scope"=>"DEFAULT", "name"=>"test", "id"=>created["start"]}
      ret = JSON.parse(response.body)
      expect(ret["start"]).to eql(created["start"])
      expect(ret["stop"]).not_to be_nil
      expect(ret["updated_at"]).not_to be_nil
      expect(ret["duration"]).to eql(3600)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET show invalid start" do
    it "returns a hash and status code 404" do
      request.headers["Authorization"] = "foobar"
      get :show, params: {"scope"=>"DEFAULT", "name"=>"test", "id"=>"200"}
      ret = JSON.parse(response.body)
      expect(ret["status"]).to eql("error")
      expect(ret["message"]).not_to be_nil
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "PUT update invalid start" do
    it "returns a hash and status code 404" do
      request.headers["Authorization"] = "foobar"
      put :update, params: {"scope"=>"DEFAULT", "name"=>"test", "id"=>"200"}
      ret = JSON.parse(response.body)
      expect(ret["status"]).to eql("error")
      expect(ret["message"]).not_to be_nil
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "PUT update not json" do
    it "returns a hash and status code 400" do
      request.headers["Authorization"] = "foobar"
      json = generate_activity(1.0)
      post :create, params: {"scope"=>"DEFAULT", "name"=>"test", "json"=>json}
      created = JSON.parse(response.body)
      expect(created["start"]).not_to be_nil
      put :update, params: {"scope"=>"DEFAULT", "name"=>"test", "id"=>created["start"], "json"=>"test"}
      ret = JSON.parse(response.body)
      expect(ret["status"]).to eql("error")
      expect(ret["message"]).not_to be_nil
      expect(response).to have_http_status(400)
    end
  end

  describe "PUT update" do
    it "returns a hash and status code 200" do
      request.headers["Authorization"] = "foobar"
      json = generate_activity(1.0)
      post :create, params: {"scope"=>"DEFAULT", "name"=>"test", "json"=>json}
      created = JSON.parse(response.body)
      expect(created["start"]).not_to be_nil
      json = generate_activity(2.0)
      put :update, params: {"scope"=>"DEFAULT", "name"=>"test", "id"=>created["start"], "json"=>json}
      ret = JSON.parse(response.body)
      expect(ret["start"]).not_to eql(created["start"])
      expect(response).to have_http_status(:ok)
    end
  end

  describe "PUT update negative time" do
    it "returns a hash and status code 400" do
      request.headers["Authorization"] = "foobar"
      json = generate_activity(1.0)
      post :create, params: {"scope"=>"DEFAULT", "name"=>"test", "json"=>json}
      expect(response).to have_http_status(:created)
      created = JSON.parse(response.body)
      expect(created["start"]).not_to be_nil
      json = generate_activity(-2.0)
      put :update, params: {"scope"=>"DEFAULT", "name"=>"test", "id"=>created["start"], "json"=>json}
      ret = JSON.parse(response.body)
      expect(ret["status"]).to eql("error")
      expect(ret["message"]).not_to be_nil
      expect(response).to have_http_status(400)
    end
  end

  describe "PUT update invalid json" do
    it "returns a hash and status code 400" do
      request.headers["Authorization"] = "foobar"
      json = generate_activity(1.0)
      post :create, params: {"scope"=>"DEFAULT", "name"=>"test", "json"=>json}
      expect(response).to have_http_status(:created)
      created = JSON.parse(response.body)
      expect(created["start"]).not_to be_nil
      put :update, params: {"scope"=>"DEFAULT", "name"=>"test", "id"=>created["start"], "json"=>"{}"}
      ret = JSON.parse(response.body)
      expect(ret["status"]).to eql("error")
      expect(ret["message"]).not_to be_nil
      expect(response).to have_http_status(400)
    end
  end


  describe "PUT update" do
    it "returns a hash and status code 409" do
      request.headers["Authorization"] = "foobar"
      json = generate_activity(1.0)
      post :create, params: {"scope"=>"DEFAULT", "name"=>"test", "json"=>json}
      expect(response).to have_http_status(:created)
      created = JSON.parse(response.body)
      expect(created["start"]).not_to be_nil
      json = generate_activity(2.0)
      post :create, params: {"scope"=>"DEFAULT", "name"=>"test", "json"=>json}
      expect(response).to have_http_status(:created)
      json = generate_activity(2.0)
      put :update, params: {"scope"=>"DEFAULT", "name"=>"test", "id"=>created["start"], "json"=>json}
      ret = JSON.parse(response.body)
      expect(ret["status"]).to eql("error")
      expect(ret["message"]).not_to be_nil
      expect(response).to have_http_status(409)
    end
  end

  describe "DELETE destroy" do
    it "returns a status code 204" do
      request.headers["Authorization"] = "foobar"
      json = generate_activity(1.0)
      post :create, params: {"scope"=>"DEFAULT", "name"=>"test", "json"=>json}
      expect(response).to have_http_status(:created)
      created = JSON.parse(response.body)
      expect(created["start"]).not_to be_nil
      delete :destroy, params: {"scope"=>"DEFAULT", "name"=>"test", "id"=>created["start"]}
      expect(response).to have_http_status(:no_content)
    end
  end

  describe "DELETE destroy" do
    it "returns a status code 404" do
      request.headers["Authorization"] = "foobar"
      delete :destroy, params: {"scope"=>"DEFAULT", "name"=>"test", "id"=>"200"}
      ret = JSON.parse(response.body)
      expect(ret["status"]).to eql("error")
      expect(ret["message"]).not_to be_nil
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST multi_create" do
    it "returns an array and status code 200" do
      request.headers["Authorization"] = "foobar"
      post_array = Array.new
      for i in (1..10) do
        dt = DateTime.now.new_offset(0)
        start_time = dt + (i/24.0)
        stop_time = dt + ((i+0.5)/24.0)
        post_array << {
          "name" => "test",
          "start" => start_time.to_s,
          "stop" => stop_time.to_s,
          "kind" => "cmd",
          "data" => {"test"=>"test #{i}"}
        }
      end
      json = JSON.generate(post_array)
      post :multi_create, params: {"scope"=>"DEFAULT", "json"=>json}
      expect(response).to have_http_status(:ok)
      get :index, params: {"scope"=>"DEFAULT", "name"=>"test"}
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json.empty?).to eql(false)
      expect(json.length).to eql(10)
    end
  end

  describe "POST multi_create with errors" do
    it "returns an array and status code 200" do
      request.headers["Authorization"] = "foobar"
      dt = DateTime.now.new_offset(0)
      start_time = dt + (1/24.0)
      stop_time = dt + ((1.5)/24.0)
      post_array = [
        {"name" => "foo", "start" => start_time.to_s, "stop" => stop_time.to_s},
        {"start" => start_time.to_s, "stop" => stop_time.to_s},
        {},
        "Test",
        1,
      ]
      json = JSON.generate(post_array)
      post :multi_create, params: {"scope"=>"DEFAULT", "json"=>json}
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json.empty?).to eql(false)
      expect(json.length).to eql(5)
    end
  end

  describe "POST multi_create, multi_destory" do
    it "returns a hash and status code 400" do
      request.headers["Authorization"] = "foobar"
      post :multi_create, params: {"scope"=>"DEFAULT", "json"=>"TEST"}
      expect(response).to have_http_status(400)
      json = JSON.parse(response.body)
      expect(json["status"]).to eql("error")
      expect(json["message"]).not_to be_nil
      post :multi_destroy, params: {"scope"=>"DEFAULT", "json"=>"TEST"}
      expect(response).to have_http_status(400)
      json = JSON.parse(response.body)
      expect(json["status"]).to eql("error")
      expect(json["message"]).not_to be_nil
    end
  end

  describe "POST multi_destroy" do
    it "returns an array and status code 200" do
      request.headers["Authorization"] = "foobar"
      create_post_array = Array.new
      for i in (1..10) do
        dt = DateTime.now.new_offset(0)
        start_time = dt + (i/24.0)
        stop_time = dt + ((i+0.5)/24.0)
        create_post_array << {
          "name" => "test",
          "start" => start_time.to_s,
          "stop" => stop_time.to_s,
          "kind" => "cmd",
          "data" => {"test"=>"test #{i}"}
        }
      end
      json = JSON.generate(create_post_array)
      post :multi_create, params: {"scope"=>"DEFAULT", "json"=>json}
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      destroy_post_array = Array.new
      json.each do |hash|
        destroy_post_array << {"name" => hash["name"], "id" => hash['start']}
      end
      json = JSON.generate(destroy_post_array)
      post :multi_destroy, params: {"scope"=>"DEFAULT", "json"=>json}
      expect(response).to have_http_status(:ok)
      get :index, params: {"scope"=>"DEFAULT", "name"=>"test"}
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json.empty?).to eql(true)
    end
  end

  describe "POST multi_destroy with errors" do
    it "returns an array and status code 200" do
      request.headers["Authorization"] = "foobar"
      dt = DateTime.now.new_offset(0)
      destroy_post_array = [
        {"name" => "foo", "id" => "123456"},
        {"name" => "foo"},
        {"id" => "1234567"},
        {},
        "Test",
        1,
      ]
      json = JSON.generate(destroy_post_array)
      post :multi_destroy, params: {"scope"=>"DEFAULT", "json"=>json}
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json.empty?).to eql(false)
      expect(json.length).to eql(6)
    end
  end


end