class Pipeline < ApplicationRecord
  acts_as_tenant :tenant

  belongs_to :tenant
  belongs_to :data_source
  has_many :pipeline_steps, -> { order(:position) }, dependent: :destroy
  has_many :pipeline_runs, dependent: :destroy

  validates :name, presence: true
  validates :status, presence: true, inclusion: { in: %w[draft active paused archived] }
  validates :schedule_type, inclusion: { in: %w[manual scheduled triggered] }, allow_nil: true

  scope :active, -> { where(status: 'active') }
  scope :draft, -> { where(status: 'draft') }
  scope :scheduled, -> { where(schedule_type: 'scheduled') }
  scope :runnable, -> { where(status: 'active').where('schedule_type != ? OR (schedule_type = ? AND next_run_at <= ?)', 'scheduled', 'scheduled', Time.current) }

  before_validation :set_defaults, if: :new_record?
  after_update :update_next_run_schedule, if: :saved_change_to_schedule_cron?

  def active?
    status == 'active'
  end

  def scheduled?
    schedule_type == 'scheduled'
  end

  def can_run?
    return false unless active?
    return true if schedule_type != 'scheduled'

    scheduled? && next_run_at.present? && next_run_at <= Time.current
  end

  def add_step(step_attributes)
    transaction do
      lock!
      max_position = pipeline_steps.maximum(:position) || 0
      pipeline_steps.create!(step_attributes.merge(position: max_position + 1))
    end
  end

  def reorder_steps(step_ids)
    transaction do
      step_ids.each_with_index do |step_id, index|
        pipeline_steps.find(step_id).update!(position: index + 1)
      end
    end
  end

  def duplicate
    duplicate_pipeline = dup
    duplicate_pipeline.name = "#{name} (Copy)"
    duplicate_pipeline.status = 'draft'
    duplicate_pipeline.schedule_type = nil
    duplicate_pipeline.schedule_cron = nil
    duplicate_pipeline.schedule_interval = nil
    duplicate_pipeline.next_run_at = nil
    duplicate_pipeline.last_run_at = nil

    if duplicate_pipeline.save
      pipeline_steps.each do |step|
        duplicate_step = step.dup
        duplicate_step.pipeline = duplicate_pipeline
        duplicate_step.save!
      end
    end

    duplicate_pipeline
  end

  def calculate_next_run
    return nil unless scheduled?

    if schedule_cron.present?

      cron = CronParser.new(schedule_cron)
      cron.next(Time.current)
    elsif schedule_interval.present? && last_run_at.present?
      last_run_at + schedule_interval.seconds
    elsif schedule_interval.present?
      Time.current + schedule_interval.seconds
    end
  rescue => e
    Rails.logger.error "Error calculating next run for pipeline #{id}: #{e.message}"
    nil
  end

  private

  def set_defaults
    self.status ||= 'draft'
  end

  def update_next_run_schedule
    if scheduled? && (schedule_cron.present? || schedule_interval.present?)
      new_next_run_at = calculate_next_run
      update_columns(next_run_at: new_next_run_at) if new_next_run_at != next_run_at
    end
  end
end