require_relative "duplicate_checker"

module DelayedJobPreventDuplicate
  module SignatureConcern
    extend ActiveSupport::Concern

    included do
      before_validation :generate_signature
      validate :prevent_duplicate
    end

    private

    def generate_signature
      self.signature = signature_from_denormalized_data || random_signature
    end

    def signature_from_denormalized_data
      begin
        Digest::MD5.hexdigest(denormalized_data.to_json)
      rescue
        puts "DelayedJobPreventDuplicate could not generate the signature correctly."
        nil
      end
    end

    def self.random_signature
      SecureRandom.uuid
    end

    def denormalized_data
      @denormalize_data ||= begin
        if payload_object.is_a?(Delayed::PerformableMethod)
          denormalized_data_for_performable_method
        else
          denormalized_data_for_job_wrapper
        end
      end
    end

    # Methods tagged with handle_asynchronously
    def denormalized_data_for_performable_method
      {
        object: payload_object.object.to_global_id.to_s,
        method_name: payload_object.method_name,
        args: stringify_arguments(payload_object.args)
      }
    end

    # Regular Job
    def denormalized_data_for_job_wrapper
      {
        job_class: payload_object.job_data["job_class"],
        args: stringify_arguments(payload_object.job_data["arguments"])
      }
    end

    def stringify_arguments(arguments)
      serialize_arguments(arguments).join('|')
    end

    def serialize_arguments(arguments)
      arguments.map { |argument|
        argument.is_a?(ActiveRecord::Base)  ? argument.to_global_id.to_s
                                            : argument.to_json
      }
    end

    def prevent_duplicate
      if DuplicateChecker.duplicate?(self)
        Rails.logger.warn "Found duplicate job(#{self.signature}), ignoring..."
        errors.add(:base, "This is a duplicate")
      end
    end
  end
end
