module Weenat
  class Engine < ::Rails::Engine

    initializer 'weenat.assets.precompile' do |app|
      app.config.assets.precompile += %w[*.svg *.png]
    end

    initializer :i18n do |app|
      app.config.i18n.load_path += Dir[Weenat::Engine.root.join('config', 'locales', '**', '*.yml')]
    end

    initializer :ekylibre_weenat_integration do
      Weenat::WeenatIntegration.on_check_success do
        WeenatFirstRunJob.perform_later
      end

      Weenat::WeenatIntegration.run every: :hour do
        last_weenat_import = Preference.find_by(name: 'last_weenat_import')
        weenat_import_running = Preference.find_by(name: 'weenat_import_running')
        if last_weenat_import&.value && !weenat_import_running&.value
          last_imported_at = last_weenat_import.value
          WeenatFetchUpdateCreateJob.perform_now(last_imported_at)
        end
      end
    end

  end
end
