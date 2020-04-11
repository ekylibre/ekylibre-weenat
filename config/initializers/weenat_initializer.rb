autoload :Weenat, 'weenat'

Weenat::WeenatIntegration.on_check_success do
  WeenatFetchUpdateCreateJob.perform_later
end

Weenat::WeenatIntegration.run every: :day do
  WeenatFetchUpdateCreateJob.perform_now
end
