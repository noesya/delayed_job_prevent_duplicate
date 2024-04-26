module DelayedJobPreventDuplicate
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
      job1.payload_object.args == job2.payload_object.args
    rescue
      false
    end
  end
end
