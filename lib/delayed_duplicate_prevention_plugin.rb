# based on https://gist.github.com/synth/fba7baeffd083a931184

require 'delayed_job'

class DelayedDuplicatePreventionPlugin < Delayed::Plugin

  module SignatureConcern
    extend ActiveSupport::Concern

    included do
      before_validation :add_signature
      validate :prevent_duplicate
    end

    private

    def add_signature
      # If signature fails, id will keep everything working (though deduplication will not work)
      self.signature = generate_signature || generate_signature_random
      self.args = get_args
      truncate_signature_if_needed
    end

    def generate_signature
      begin
        # NOTE: placing this block at the top since class method invocations also have Delayed::PerformableMethod as payload_object
        if payload_object.respond_to?(:object) && payload_object.object&.is_a?(Class) && !payload_object.respond_to?(:signature)
          generate_signature_for_class_method
        elsif payload_object.respond_to?(:signature) || payload_object.is_a?(Delayed::PerformableMethod)
          generate_signature_for_job_payload
        else
          generate_signature_random
        end
      rescue
        log_signature_failed
      end
    end

    # this is to prevent ActiveRecord::ValueTooLong error for some cases with complex/long args
    def truncate_signature_if_needed
      return unless self.signature.present?

      column_limit = self.class.columns_hash["signature"].limit
      return unless column_limit

      if self.signature.length > column_limit
        self.signature = self.signature[0...(column_limit - 1)]
      end
    end

    def generate_signature_for_class_method
       # cast individual args to string and AR objects to class:id if any
      arg_signatures = get_args.map do |obj|
        obj.respond_to?(:id) ? "#{obj.class}:#{obj.id}" : obj.to_s
      end

      kwarg_signatures = get_kwargs.map do |(key, val)|
        val = val.respond_to?(:id) ? "#{val.class}:#{val.id}" : val.to_s
        [key, val]
      end.to_h

      "#{payload_object.object}##{payload_object.method_name}-#{arg_signatures}-#{kwarg_signatures}"
    end

    # Methods tagged with handle_asynchronously
    def generate_signature_for_job_payload
      if payload_object.respond_to?(:signature)
        if payload_object.method(:signature).arity > 0
          combined_args = [get_args, get_kwargs]
          sig = payload_object.signature(payload_object.method_name, combined_args)
        else
          sig = payload_object.signature
        end
      else
        if payload_object.object.respond_to?(:id) and payload_object.object.id.present?
          sig = "#{payload_object.object.class}:#{payload_object.object.id}"
        else
          sig = "#{payload_object.object}"
        end
      end
      if payload_object.respond_to?(:method_name)
        sig += "##{payload_object.method_name}" unless sig.match("##{payload_object.method_name}")
      end
      sig
    end

    # # Regular Job
    # def generate_signature_for_job_wrapper
    #   sig = "#{payload_object.job_data["job_class"]}"
    #   payload_object.job_data["arguments"].each do |job_arg|
    #     string_job_arg = job_arg.is_a?(String) ? job_arg : job_arg.to_json
    #   end
    #   sig += "#{payload_object.job_data["job_class"]}"
    #   sig
    # end

    def generate_signature_random
      SecureRandom.uuid
    end

    def log_signature_failed
      Rails.logger.error "DelayedDuplicatePreventionPlugin could not generate the signature correctly."
    end

    def get_args
      self.payload_object.try(:args) || []
    end

    def get_kwargs
      self.payload_object.try(:kwargs) || []
    end

    def prevent_duplicate
      if DuplicateChecker.duplicate?(self)
        Rails.logger.warn "Found duplicate job(#{self.signature}), ignoring..."
        errors.add(:base, "This is a duplicate")
      end
    end
  end

  class DuplicateChecker
    attr_reader :job

    def self.duplicate?(job)
      new(job).duplicate?
    end

    def initialize(job)
      @job = job
    end

    def duplicate?
      possible_dupes.any? { |possible_dupe| args_match?(possible_dupe, job) }
    end

    private

    def possible_dupes
      possible_dupes = Delayed::Job.where(attempts: 0, locked_at: nil)  # Only jobs not started, otherwise it would never compute a real change if the job is currently running
                                   .where(signature: job.signature)     # Same signature
      possible_dupes = possible_dupes.where.not(id: job.id) if job.id.present?
      possible_dupes
    end

    def args_match?(job1, job2)
      job1.payload_object.args == job2.payload_object.args &&
        job1.payload_object.kwargs == job2.payload_object.kwargs
    rescue
      false
    end
  end
end
