# frozen_string_literal: true

require "delayed_job"

require_relative "delayed_job_prevent_duplicate/signature_concern"
require_relative "delayed_job_prevent_duplicate/version"

module DelayedJobPreventDuplicate
  class Error < StandardError; end

  Delayed::Backend::ActiveRecord::Job.send(:include, SignatureConcern)
end
