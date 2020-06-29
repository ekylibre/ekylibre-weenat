autoload :Weenat, 'weenat'

Weenat::WeenatIntegration.on_check_success do
  WeenatFirstRunJob.perform_later
end

Weenat::WeenatIntegration.run every: :hour do
  weenat_import_preference = Preference.find_by(name: 'weenat_import')
  return unless weenat_import_preference&.value

  last_imported_at = weenat_import_preference.value
  WeenatFetchUpdateCreateJob.perform_now(last_imported_at)
end
