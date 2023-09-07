# frozen_string_literal: true

require 'rails'

module DelayedJobPreventDuplicate
  class DelayedJobPreventDuplicateGenerator < ::Rails::Generators::Base

    include Rails::Generators::Migration
    source_root File.expand_path("../templates", __FILE__)

    def self.next_migration_number(path)
      unless @prev_migration_nr
        @prev_migration_nr = Time.now.utc.strftime("%Y%m%d%H%M%S").to_i
      else
        @prev_migration_nr += 1
      end
     @prev_migration_nr.to_s
    end

    def copy_migration
      migration_template "migration.rb", "db/migrate/add_signature_to_delayed_job.rb", migration_version: migration_version
    end

    def migration_version
      "[#{Rails::VERSION::MAJOR}.#{Rails::VERSION::MINOR}]"
    end

  end
end
