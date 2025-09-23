class StepExecution < ApplicationRecord
  belongs_to :pipeline_run
  belongs_to :pipeline_step

  validates :status, presence: true, inclusion: { in: %w[running completed failed skipped] }
  validates :step_type, presence: true
  validates :started_at, presence: true
  validates :input_rows, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :output_rows, presence: true, numericality: { greater_than_or_equal_to: 0 }

  scope :running, -> { where(status: 'running') }
  scope :completed, -> { where(status: 'completed') }
  scope :failed, -> { where(status: 'failed') }
  scope :skipped, -> { where(status: 'skipped') }

  before_validation :set_defaults, if: :new_record?
  before_save :calculate_duration, if: :will_save_change_to_completed_at?

  def running?
    status == 'running'
  end

  def completed?
    status == 'completed'
  end

  def failed?
    status == 'failed'
  end

  def skipped?
    status == 'skipped'
  end

  def finished?
    completed? || failed? || skipped?
  end

  def success?
    completed? || skipped?
  end

  def processing_rate
    return 0 if duration.nil? || duration.zero?

    input_rows.to_f / duration
  end

  def efficiency_ratio
    return 0 if input_rows.zero?

    output_rows.to_f / input_rows
  end

  def mark_completed!(output_rows_count, metadata = {})
    update!(
      status: 'completed',
      completed_at: Time.current,
      output_rows: output_rows_count,
      metadata: metadata
    )
  end

  def mark_failed!(error_message, metadata = {})
    update!(
      status: 'failed',
      completed_at: Time.current,
      error_message: error_message,
      metadata: metadata
    )
  end

  def mark_skipped!(reason = 'Step disabled')
    update!(
      status: 'skipped',
      completed_at: Time.current,
      output_rows: input_rows,
      metadata: { skipped: true, reason: reason }
    )
  end

  private

  def set_defaults
    self.status ||= 'running'
    self.started_at ||= Time.current
    self.step_type ||= pipeline_step&.step_type
    self.input_rows ||= 0
    self.output_rows ||= 0
  end

  def calculate_duration
    if started_at.present? && completed_at.present?
      self.duration = (completed_at - started_at).to_i
    end
  end
end