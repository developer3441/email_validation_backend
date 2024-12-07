# frozen_string_literal: true

require_relative 'config/loader'
require 'rack'
require 'rack/cors'


use Rack::Cors do
  allow do
    origins '*' # Replace '*' with specific domains if needed
    resource '*',
             headers: :any,
             methods: [:get, :post, :options, :put, :delete],
             expose: ['Authorization']
  end
end

run TruemailServer::RackCascade
