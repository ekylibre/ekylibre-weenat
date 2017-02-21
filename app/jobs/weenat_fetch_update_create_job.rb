class WeenatFetchUpdateCreateJob < ActiveJob::Base
  queue_as :default

  def perform
    WeenatIntegration.fetch_all.execute do |c|
      c.success do |traps|
        traps.map do |trap|
          sensor = Sensor.find_or_create_by(
            vendor_euid: :cap2020,
            model_euid: :cap_trap,
            euid: trap[:id],
            retrieval_mode: :integration
          )
          sensor.update!(
            name: "Weenat #{trap[:number]}-#{trap[:sigfox_id]}",
            partner_url: trap[:link],
            last_transmission_at: trap[:last_transmission],
            battery_level: trap[:battery_level]
          )

          retrieved_data = []

          # Example until we have the indicators.
          retrieved_data << { indicator_name: :daily_pest_count, value: trap[:last_count] }
          retrieved_data << { indicator_name: :weekly_pest_count, value: trap[:weekly_count] }

          sensor.analyses.create!(
            retrieval_status: :ok,
            # nature: :cap_trap_analysis,
            nature: :sensor_analysis,
            geolocation: trap[:location],
            sampling_temporal_mode: :period,
            items_attributes: retrieved_data
          )

          alerts = {
            daily_pest_count: :daily_pest_count,
            battery_life: :battery_level,
            lost_connection: :connection_lost,
            weekly_pest_count: :weekly_pest_count,
            weather_risk: :weather,
            area_at_risk: :danger_zone,
            pest_count_rapid_increase: :pest_spike
          }

          alerts.each do |alert_nature, trap_attribute|
            alert = sensor.alerts.find_or_create_by(nature: alert_nature)
            trap_level = trap[:alerts][trap_attribute]
            alert.phases.create!(started_at: DateTime.now, level: trap_level) unless alert.level == trap_level
          end
        end
      end
    end
  end
end
