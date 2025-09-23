class PipelineRun < ApplicationRecord
  belongs_to :pipeline
  has_many :step_executions, dependent: :destroy

  validates :status, presence: true, inclusion: { in: %w[running completed failed stopped] }
  validates :started_at, presence: true
  validates :trigger_type, presence: true, inclusion: { in: %w[manual scheduled triggered] }

  scope :running, -> { where(status: 'running') }
  scope :completed, -> { where(status: 'completed') }
  scope :failed, -> { where(status: 'failed') }
  scope :stopped, -> { where(status: 'stopped') }

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

  def stopped?
    status == 'stopped'
  end

  def finished?
    completed? || failed? || stopped?
  end

  def success_rate
    return 0 if step_executions.empty?

    successful_steps = step_executions.where(status: 'completed').count
    total_steps = step_executions.count

    (successful_steps.to_f / total_steps * 100).round(2)
  end

  def total_rows_processed
    step_executions.sum(:output_rows)
  end

  def mark_completed!
    update!(
      status: 'completed',
      completed_at: Time.current
    )
  end

  def mark_failed!(error_message = nil)
    update!(
      status: 'failed',
      completed_at: Time.current,
      error_message: error_message
    )
  end

  def mark_stopped!
    update!(
      status: 'stopped',
      completed_at: Time.current
    )
  end

  private

  def set_defaults
    self.status ||= 'running'
    self.started_at ||= Time.current
    self.trigger_type ||= 'manual'
  end

  def calculate_duration
    if started_at.present? && completed_at.present?
      self.duration = (completed_at - started_at).to_i
    end
  end
end