# frozen_string_literal: true

require 'sinatra'
require 'json'
require_relative 'db'
require_relative 'app/services/create_operation_service'
require_relative 'app/services/submit_operation_service'

before do
  set_params
  set_user
end

helpers do
  def set_params
    @params = JSON.parse(request.body.read)
  rescue JSON::ParserError
    halt 400, { status: 'error', message: 'Invalid JSON format' }.to_json
  end

  def extract_param!(key)
    value = @params[key]
    if value.nil? || (value.respond_to?(:empty?) && value.empty?) || (value.is_a?(String) && value.strip.empty?)
      halt 400,
           { status: 'error',
             message: "#{key} is required" }.to_json
    end
    value
  end

  def set_user
    user_id = extract_param!('user_id')
    @user = User[user_id] or halt 404, { status: 'error', message: 'User not found' }.to_json
  end
end

post '/operation' do
  content_type :json

  positions = extract_param!('positions')
  CreateOperationService.new(@user, positions).call.to_json
rescue StandardError => e
  status 422
  { status: 'error', message: e.message }.to_json
end

post '/submit' do
  content_type :json

  operation_id = extract_param!('operation_id')
  write_off = extract_param!('write_off')

  operation = Operation[operation_id] or halt 404, { status: 'error', message: 'Operation not found' }.to_json

  SubmitOperationService.new(@user, operation, write_off).call.to_json
rescue StandardError => e
  status 422
  { status: 'error', message: e.message }.to_json
end
