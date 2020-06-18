class WeenatFetchUpdateCreateJob < ActiveJob::Base
  queue_as :default

  # get 2 hours of weather data every hour
  def perform(last_imported_at)

    # compute start and stop in EPOCH timestamp for weenat API
    started_at = last_imported_at
    stopped_at = Time.zone.now.to_i

    last_sampled_at_list = []

    # transcode Weenat weather indicators in Ekylibre weather indicators
    transcode_indicators = {
                            :RR => {indicator: :cumulated_rainfall, unit: :millimeter},
                            :T => {indicator: :average_temperature, unit: :celsius},
                            :U => {indicator: :average_relative_humidity, unit: :percent},
                            :FF => {indicator: :average_wind_speed, unit: :kilometer_per_hour},
                            :FXY => {indicator: :maximal_wind_speed, unit: :kilometer_per_hour}
                          }.freeze

    #TODO call get_token method here to avoid multiple call of get_token during one session

    # Get all plot and create sensor
    Weenat::WeenatIntegration.fetch_all.execute do |c|
      c.success do |list|
        list.map do |plot|

          # puts plot.inspect.green
          # plot attributes
          # plot[:id]
          # plot[:name]
          # plot[:latitude]
          # plot[:longitude]
          # plot[:device_count]
          geolocation = ::Charta.new_point(plot[:latitude], plot[:longitude]).to_ewkt

          sensor = Sensor.find_or_create_by(
            vendor_euid: :weenat,
            euid: plot[:id],
            retrieval_mode: :integration
          )
          sensor.update!(
            name: "#{plot[:name]}",
            model_euid: :weenat,
            partner_url: "https://app.weenat.com",
            last_transmission_at: Time.zone.now
          )

          # Get data for a plot (plot[:id]) and create analyse and items
          Weenat::WeenatIntegration.last_values(plot[:id], started_at, stopped_at).execute do |c|
            c.success do |values|
              values.each do |plot_analysis|
                reference_number = sensor.euid.to_s + "_" + plot_analysis[0].to_s
                read_at = Time.at(plot_analysis[0].to_s.to_i)

                analyse = sensor.analyses.find_or_create_by(
                  reference_number: reference_number,
                  sampled_at: read_at,
                  analysed_at: read_at,
                  retrieval_status: :ok,
                  nature: :sensor_analysis,
                  geolocation: geolocation,
                  sampling_temporal_mode: :period
                )
                # Avoid re creations of the same items if analyse exist with items
                unless analyse.items.any?
                  # Transcode each item present with transcode_indicators and save it
                  plot_analysis[1].each do |plot_analysis_item|
                    transcoded_indicator = transcode_indicators[plot_analysis_item.first]
                    if transcoded_indicator && plot_analysis_item.last != nil
                      analyse.read!(transcoded_indicator[:indicator], plot_analysis_item.last.in(transcoded_indicator[:unit]))
                    end
                  end
                end

              end
              if values.any?
                last_sampled_at_list << values.max_by { |k, _v| k }.first.to_s.to_i
              end
            end
          end
        end
      end
    end

    Preference.set!('weenat_import', last_sampled_at_list.min, 'integer')
  end

end
