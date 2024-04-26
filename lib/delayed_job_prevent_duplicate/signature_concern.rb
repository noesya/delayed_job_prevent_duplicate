require_relative "duplicate_checker"

module DelayedJobPreventDuplicate
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
    end

    def generate_signature
      begin
        if payload_object.is_a?(Delayed::PerformableMethod)
          generate_signature_for_performable_method
        else
          generate_signature_random
        end
      rescue
        generate_signature_failed
      end
    end

    # Methods tagged with handle_asynchronously
    def generate_signature_for_performable_method
      if payload_object.object.respond_to?(:id) and payload_object.object.id.present?
        sig = "#{payload_object.object.class}:#{payload_object.object.id}"
      else
        sig = "#{payload_object.object}"
      end
      sig += "##{payload_object.method_name}"
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

    def generate_signature_failed
      puts "DelayedDuplicatePreventionPlugin could not generate the signature correctly."
    end

    def get_args
      self.payload_object.respond_to?(:args) ? self.payload_object.args : []
    end

    def prevent_duplicate
      if DuplicateChecker.duplicate?(self)
        Rails.logger.warn "Found duplicate job(#{self.signature}), ignoring..."
        errors.add(:base, "This is a duplicate")
      end
    end
  end
end