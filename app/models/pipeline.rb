class Pipeline < ApplicationRecord
  belongs_to :tenant
  belongs_to :data_source, optional: true
  has_many :pipeline_steps, dependent: :destroy
  has_many :pipeline_runs, dependent: :destroy

  validates :name, presence: true
  validates :status, inclusion: { in: %w[draft active inactive] }

  # Store the visual pipeline configuration as JSON
  attribute :pipeline_config, :jsonb

  # Scopes
  scope :active, -> { where(status: 'active') }
  scope :draft, -> { where(status: 'draft') }
  scope :scheduled, -> { where.not(schedule_type: nil) }

  def execute
    PipelineRunnerJob.perform_later(id)
  end

  def last_run
    pipeline_runs.order(created_at: :desc).first
  end

  def running?
    last_run&.status == 'running'
  end

  def can_run?
    !running? && status == 'active'
  end

  # Convert visual nodes to pipeline steps
  def sync_steps_from_config
    return unless pipeline_config.present?

    nodes = pipeline_config['nodes'] || []
    edges = pipeline_config['edges'] || []

    # Clear existing steps
    pipeline_steps.destroy_all

    # Create steps from nodes
    nodes.each_with_index do |node, index|
      pipeline_steps.create!(
        name: node['data']['label'],
        step_type: node['type'],
        configuration: node['data'],
        position: index + 1,
        status: 'enabled'
      )
    end
  end
end