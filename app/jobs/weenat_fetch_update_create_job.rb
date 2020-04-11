class WeenatFetchUpdateCreateJob < ActiveJob::Base
  queue_as :default

  def perform

    started_at = Time.now.to_i - 10.days
    stopped_at = Time.now.to_i

    Weenat::WeenatIntegration.fetch_all.execute do |c|
      c.success do |list|
        list.map do |plot|

          puts plot.inspect.green
          # plot attributes
          # plot[:id]
          # plot[:name]
          # plot[:latitude]
          # plot[:longitude]
          # plot[:device_count]
          geolocation = ::Charta.new_point(plot[:latitude], plot[:longitude])

          sensor = Sensor.find_or_create_by(
            vendor_euid: :weenat,
            model_euid: :weenat,
            euid: plot[:id],
            retrieval_mode: :integration
          )
          sensor.update!(
            name: "Weenat #{plot[:name]}",
            last_transmission_at: Time.now
          )

          # Get data of one plot
          Weenat::WeenatIntegration.last_values(plot[:id], started_at, stopped_at).execute do |c|
            c.success do |values|
              values.each do |analysis|

                read_at = Time.at(analysis[0].to_s.to_i)
                items_values = {}
                #RR : Cumul des précipitations (en mm) en une heure
                items_values[:cumulated_rainfall] = analysis[1][:RR].in(:millimeter) if analysis[1][:RR] != nil
                #T : Température moyenne de l’air sous abri (en °C) en une heure
                items_values[:average_temperature] = analysis[1][:T].in(:celsius) if analysis[1][:T] != nil
                #U : Humidité relative moyenne (en %) en une heure
                items_values[:average_relative_humidity] = analysis[1][:U].in(:percent) if analysis[1][:U] != nil

              sensor.analyses.create!(
                sampled_at: read_at,
                retrieval_status: :ok,
                nature: :sensor_analysis,
                geolocation: geolocation,
                sampling_temporal_mode: :period,
                items_attributes: items_values
              )
              end
            end
          end
        end
      end
    end
  end
end
