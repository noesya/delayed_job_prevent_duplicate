# frozen_string_literal: true

require_relative "delayed_job_prevent_duplicate/version"

module DelayedJobPreventDuplicate
  class Error < StandardError; end
 
  require 'delayed_duplicate_prevention_plugin'

  Delayed::Backend::ActiveRecord::Job.send(:include, DelayedDuplicatePreventionPlugin::SignatureConcern)
  Delayed::Worker.plugins << DelayedDuplicatePreventionPlugin
end
