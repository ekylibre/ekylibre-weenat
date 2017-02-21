class WeenatFetchUpdateCreateJob < ActiveJob::Base
  queue_as :default

  def perform
    WeenatIntegration.fetch_all.execute do |c|
      c.success do |list|
        list.map do |desc|
          sensor = Sensor.find_or_create_by(
            vendor_euid: :weenat,
            model_euid: :weenat,
            euid: desc[:id],
            retrieval_mode: :integration
          )
          sensor.update!(
            name: "Weenat #{desc[:name]}",
            partner_url: desc[:plot_url],
            last_transmission_at: desc[:last_pick_at]
          )

          # Get data
          WeenatIntegration.last_value(sensor).execute do |c|
            c.success do |values|
              sensor.analyses.create!(
                retrieval_status: :ok,
                nature: :sensor_analysis,
                geolocation: desc[:location],
                sampling_temporal_mode: :period,
                items_attributes: values
              )
            end
          end
        end
      end
    end
  end
end
