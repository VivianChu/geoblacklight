require 'rails/generators'

module Geoblacklight
  class Install < Rails::Generators::Base

    source_root File.expand_path('../templates', __FILE__)

    desc "Install Geoblacklight"

    def assets
      copy_file "geoblacklight.css.scss", "app/assets/stylesheets/geoblacklight.css.scss"
      copy_file "geoblacklight.js", "app/assets/javascripts/geoblacklight.js"
    end

    def create_blacklight_catalog
      remove_file "app/controllers/catalog_controller.rb"
      copy_file "catalog_controller.rb", "app/controllers/catalog_controller.rb"
    end

    def rails_config
      copy_file 'settings.yml', 'config/settings.yml'
    end

    def include_geoblacklight_solrdocument
      inject_into_file 'app/models/solr_document.rb', after: 'include Blacklight::Solr::Document' do
        "\n include Geoblacklight::SolrDocument"
      end
    end

    def fixtures
      FileUtils.mkdir_p 'spec/fixtures/geoblacklight_schema'
      system 'curl -L https://raw.githubusercontent.com/geoblacklight/geoblacklight-schema/master/examples/selected.json -o spec/fixtures/geoblacklight_schema/selected.json'
    end

    def add_unique_key
      inject_into_file 'app/models/solr_document.rb', after: "# self.unique_key = 'id'" do
        "\n  self.unique_key = 'layer_slug_s'"
      end
    end

    def inject_routes
      route 'post "wms/handle"'
      route 'resources :download, only: [:show, :file]'
      route "get 'download/file/:id' => 'download#file', as: :download_file"
    end

    def create_downloads_directory
      FileUtils.mkdir_p("tmp/cache/downloads") unless File.directory?("tmp/cache/downloads")
    end

    # Necessary for bootstrap-sass 3.2
    def inject_sprockets
      blacklight_css = Dir["app/assets/stylesheets/blacklight.css.scss"].first
      if blacklight_css
        insert_into_file blacklight_css, before: "@import 'bootstrap';" do
          "@import 'bootstrap-sprockets';\n"
        end
      else
        say_status "warning", "Can not find blacklight.css.scss, did not insert our require", :red
      end
    end

    def disable_turbolinks
      gsub_file('app/assets/javascripts/application.js', /\/\/= require turbolinks/, '')
    end

    def bundle_install
      Bundler.with_clean_env do
        run "bundle install"
      end
    end

  end
end
