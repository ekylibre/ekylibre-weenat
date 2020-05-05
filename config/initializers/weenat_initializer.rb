autoload :Weenat, 'weenat'

Weenat::WeenatIntegration.on_check_success do
  WeenatFirstRunJob.perform_later
end

Weenat::WeenatIntegration.run every: :hour do
  WeenatFetchUpdateCreateJob.perform_now
end
