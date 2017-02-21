WeenatIntegration.on_check_success do
  WeenatFetchUpdateCreateJob.perform_later
end

WeenatIntegration.run every: :day do
  WeenatFetchUpdateCreateJob.perform_now
end
