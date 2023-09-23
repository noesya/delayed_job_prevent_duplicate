# frozen_string_literal: true

require_relative "delayed_job_prevent_duplicate/version"

module DelayedJobPreventDuplicate
  class Error < StandardError; end

  # NOTE: delayed_job has explicitly said they will not support kwargs
  #       https://github.com/collectiveidea/delayed_job/issues/1134#issuecomment-1432003032
  #       As such, I'm drawing the opinion that we should be moving to Delayed gem
  #       and this should be the default behavior in this gem while still supporting
  #       DelayedJob
  begin
    gem "delayed", ">= 0.5.0"
    require "delayed"
  rescue LoadError
    begin
      gem "delayed_job", ">= 3.0", "< 5"
      require "delayed_job"
    rescue LoadError
      warn "The DelayedJobPreventDuplicate plugin requires the Delayed (>= 0.5.0) or DelayedJob (>= 3.0, < 5) gems. Please add either to your Gemfile"
      raise
    end
  end

  require 'delayed_duplicate_prevention_plugin'

  def self.load
    if defined?(Delayed::Backend::ActiveRecord::Job)
      Delayed::Backend::ActiveRecord::Job.send(:include, DelayedDuplicatePreventionPlugin::SignatureConcern)
    else
      Delayed::Job.send(:include, DelayedDuplicatePreventionPlugin::SignatureConcern)
    end

    Delayed::Worker.plugins << DelayedDuplicatePreventionPlugin
  end

  # NOTE: `delayed` gem moves the ActiveRecord class into app/models
  #        which is loaded via a Rails Engine. As such, the autoload
  #        paths for the active record model aren't added until the application
  #        actually loads. So, we hook into Railties to make sure its loaded later
  if defined?(Rails::Engine)
    class DelayedRailtie < ::Rails::Railtie
      config.after_initialize do
        DelayedJobPreventDuplicate.load
      end
    end
  else
    self.load
  end

end
