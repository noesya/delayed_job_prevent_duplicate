# frozen_string_literal: true

require "rails/generators/base"
require "rails/generators/active_record/migration"

module DelayedJobPreventDuplicate
  class InstallGenerator < ::Rails::Generators::Base
    include ActiveRecord::Generators::Migration
    source_root File.expand_path("../../templates", __FILE__)

    def copy_migration
      migration_template "migration.rb", File.join(db_migrate_path, "add_signature_to_delayed_job.rb")
    end

  end
end
