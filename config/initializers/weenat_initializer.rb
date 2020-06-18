autoload :Weenat, 'weenat'

Weenat::WeenatIntegration.on_check_success do
  weenat_import_preference = Preference.find_by(name: 'weenat_import')
  if weenat_import_preference&.value
    last_imported_at = weenat_import_preference.value
  end
  WeenatFirstRunJob.perform_later(last_imported_at)
end

Weenat::WeenatIntegration.run every: :hour do
  weenat_import_preference = Preference.find_by(name: 'weenat_import')
  return unless weenat_import_preference&.value

  last_imported_at = weenat_import_preference.value
  WeenatFetchUpdateCreateJob.perform_now(last_imported_at)
end
