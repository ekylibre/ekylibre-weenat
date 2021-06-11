require 'rest-client'

module Weenat
  mattr_reader :default_options do
    {
      globals: {
        strip_namespaces: true,
        convert_response_tags_to: ->(tag) { tag.snakecase.to_sym },
        raise_errors: false
      },
      locals: {
        advanced_typecasting: true
      }
    }
  end

  class ServiceError < StandardError; end

  class WeenatIntegration < ActionIntegration::Base
    # Set url needed for weenat API v2
    API_VERSION = '/v2'.freeze
    BASE_URL = 'https://api-phoenix.weenat.com'.freeze
    TOKEN_URL = BASE_URL + '/api-token-auth/'.freeze
    PLOTS_URL = BASE_URL + API_VERSION + '/access/plots/'.freeze

    authenticate_with :check do
      parameter :login
      parameter :password
    end

    calls :retrieve_token, :fetch_all, :last_values

    # Get token with login and password
    def retrieve_token
      integration = fetch
      payload = { email: integration.parameters['login'], password: integration.parameters['password'] }
      post_json(TOKEN_URL, payload) do |r|
        r.success do
          list = JSON(r.body).deep_symbolize_keys
          r.error :api_down if r.body.include? 'Bad Request'
        end
      end
    end

    # Get all plots
    def fetch_all
      integration = fetch
      # Grab token
      token = JSON(retrieve_token.body).deep_symbolize_keys[:token]

      # for testing
      # call = RestClient::Request.execute(method: :get, url: PLOTS_URL, headers: {Authorization: "Bearer #{t}"})
      # plots = JSON.parse(call.body).map{|p| p.deep_symbolize_keys}

      # Call API
      get_json(PLOTS_URL, 'Authorization' => "JWT #{token}") do |r|
        r.success do
          list = JSON(r.body).map(&:deep_symbolize_keys)
        end

        r.redirect do
          Rails.logger.info '*sigh*'.yellow
        end

        r.error do
          Rails.logger.info 'What the fuck brah?'.red
        end
      end
    end

    # Get last_values of one plot
    def last_values(plot_id, started_at, stopped_at)
      integration = fetch
      # Grab token
      token = JSON(retrieve_token.body).deep_symbolize_keys[:token]

      # Call API
      get_json("#{PLOTS_URL}#{plot_id}/measures/?start=#{started_at}&end=#{stopped_at}", 'Authorization' => "Bearer #{token}") do |r|
        r.success do
          list = JSON(r.body).deep_symbolize_keys
        end

        r.redirect do
          Rails.logger.info '*sigh*'.yellow
        end

        r.error do
          Rails.logger.info 'What the fuck brah?'.red
        end
      end
    end

    # Check if the API is up
    # TODO where to store token ?
    def check(integration = nil)
      integration = fetch integration
      payload = { email: integration.parameters['login'], password: integration.parameters['password'] }
      post_json(TOKEN_URL, payload) do |r|
        r.success do
          Rails.logger.info 'CHECKED'.green
          r.error :api_down if r.body.include? 'Bad Request'
        end
      end
    end
  end
end
