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
    API_VERSION = '/v2'.freeze
    BASE_URL = "https://api.weenat.com".freeze
    TOKEN_URL = BASE_URL + "/api-token-auth/".freeze
    PLOTS_URL = BASE_URL + API_VERSION + "/access/plots/".freeze

    authenticate_with :check do
      parameter :login
      parameter :password
    end

    calls :get_token, :fetch_all, :last_values

    def get_token
      integration = fetch
      ## get token
      payload = {"username": integration.parameters['login'], "password": integration.parameters['password']}
      post_json(TOKEN_URL, payload) do |r|
        r.success do
          list = JSON(r.body).deep_symbolize_keys
          r.error :api_down if r.body.include? 'Bad Request'
        end
      end
    end

    def fetch_all
      integration = fetch
      token = JSON(get_token.body).deep_symbolize_keys[:token]

      # for testing
      #call = RestClient::Request.execute(method: :get, url: PLOTS_URL, headers: {Authorization: "Bearer #{t}"})
      #plots = JSON.parse(call.body).map{|p| p.deep_symbolize_keys}

      get_json(PLOTS_URL, 'Authorization' => "Bearer #{token}") do |r|
        r.success do
          list = JSON(r.body).map{|p| p.deep_symbolize_keys}
        end

        r.redirect do
          Rails.logger.info '*sigh*'.yellow
        end

        r.error do
          Rails.logger.info 'What the fuck brah?'.red
        end
      end
    end

    def last_values(sensor_id, started_at, stopped_at)
      integration = fetch
      token = JSON(get_token.body).deep_symbolize_keys[:token]
      get_json("#{PLOTS_URL}#{sensor_id}/measures/?start=#{started_at}&end=#{stopped_at}", 'Authorization' => "Bearer #{token}") do |r|
        r.success do
          list = JSON(r.body).deep_symbolize_keys
          # TODO: Missing variable names
        end

        r.redirect do
          Rails.logger.info '*sigh*'.yellow
        end

        r.error do
          Rails.logger.info 'What the fuck brah?'.red
        end
      end
    end

    def check(integration = nil)
      integration = fetch integration
      payload = {"username": integration.parameters['login'], "password": integration.parameters['password']}
      post_json(TOKEN_URL, payload) do |r|
        r.success do
          Rails.logger.info 'CHECKED'.green
          r.error :api_down if r.body.include? 'Bad Request'
        end
      end
    end

  end
end
