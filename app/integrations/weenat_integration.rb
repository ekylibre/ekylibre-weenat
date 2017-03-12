class WeenatIntegration < ActionIntegration::Base
  API_VERSION = 'v2'.freeze

  authenticate_with :oauth do
    parameter :access_token
    parameter :token_type
  end
  calls :fetch_all

  def self.oauth_callback_url(options = {})
    url = "https://api.weenat.com/#{API_VERSION}/o/authorize/?client_id=#{ENV['WEENAT_OAUTH2_CLIENT_ID']}&response_type=token"
    url << "&redirect_uri=https://ekylibre.com/callbacks/weenat/?farm=#{Ekylibre::Tenant.current}"
    url
  end

  def fetch_all
    integration = fetch
    get_json('https://api.weenat.com/v2/weenats', 'Authorization' => "#{integration.parameters['token_type'] || 'Bearer' } #{integration.parameters['access_token']}") do |r|
      r.success do
        list = JSON(r.body)
        list.map do |sensor|
          {
            id: sensor[:id],
            network_device_uid: sensor[:device],
            name: sensor[:name],
            location: { latitude: sensor[:latitude], longitude: sensor[:longitude] },
            last_pick_at: sensor[:last_pick],
            last_geolocation_pick_at: sensor[:last_pick_gps],
            last_signal_power: sensor[:last_signal],
            plot_url: sensor[:url_plot]
          }
        end
      end

      r.redirect do
        Rails.logger.info '*sigh*'.yellow
      end

      r.error do
        Rails.logger.info 'What the fuck brah?'.red
      end
    end
  end

  def last_value(sensor_id)
    integration = fetch
    get_json("https://api.weenat.com/v2/weenats/#{sensor_id}/last_value/", 'Authorization' => "#{integration.parameters['token_type'] || 'Bearer'} #{integration.parameters['access_token']}") do |r|
      r.success do
        object = JSON(r.body)
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

end
