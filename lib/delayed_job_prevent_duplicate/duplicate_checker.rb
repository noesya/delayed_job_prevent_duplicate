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
      # Looking for jobs with the same signature.
      # Only jobs not started, otherwise it would never compute a real change if the job is currently running
      duplicates = Delayed::Job.where(attempts: 0, locked_at: nil, signature: job.signature)
      duplicates = duplicates.where.not(id: job.id) if job.id.present?
      duplicates.exists?
    end
  end
end
