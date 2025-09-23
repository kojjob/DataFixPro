require 'rails_helper'

RSpec.describe Pipeline, type: :model do
  describe 'associations' do
    it { should belong_to(:tenant) }
    it { should belong_to(:data_source) }
    it { should have_many(:pipeline_steps).dependent(:destroy).order(:position) }
    it { should have_many(:pipeline_runs).dependent(:destroy) }
  end

  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:status) }
    it { should validate_inclusion_of(:status).in_array(%w[draft active paused archived]) }
    it { should validate_inclusion_of(:schedule_type).in_array(%w[manual scheduled triggered]).allow_nil }
  end

  describe 'multi-tenancy' do
    it { should have_db_column(:tenant_id) }

    it 'should be scoped to tenant' do
      expect(Pipeline.reflect_on_association(:tenant).macro).to eq(:belongs_to)
    end
  end

  describe 'scopes' do
    let(:tenant) { create(:tenant) }
    let(:data_source) { create(:data_source, tenant: tenant) }

    before do
      ActsAsTenant.current_tenant = tenant
      @active_pipeline = create(:pipeline, status: 'active', data_source: data_source)
      @draft_pipeline = create(:pipeline, status: 'draft', data_source: data_source)
      @paused_pipeline = create(:pipeline, status: 'paused', data_source: data_source)
      @archived_pipeline = create(:pipeline, status: 'archived', data_source: data_source)
      @scheduled_pipeline = create(:pipeline, schedule_type: 'scheduled', data_source: data_source)
    end

    describe '.active' do
      it 'returns only active pipelines' do
        expect(Pipeline.active).to contain_exactly(@active_pipeline)
      end
    end

    describe '.draft' do
      it 'returns only draft pipelines' do
        expect(Pipeline.draft).to contain_exactly(@draft_pipeline)
      end
    end

    describe '.scheduled' do
      it 'returns only scheduled pipelines' do
        expect(Pipeline.scheduled).to contain_exactly(@scheduled_pipeline)
      end
    end

    describe '.runnable' do
      it 'returns active and scheduled pipelines that are due' do
        upcoming_pipeline = create(:pipeline,
          status: 'active',
          schedule_type: 'scheduled',
          next_run_at: 1.hour.from_now,
          data_source: data_source
        )

        due_pipeline = create(:pipeline,
          status: 'active',
          schedule_type: 'scheduled',
          next_run_at: 1.minute.ago,
          data_source: data_source
        )

        expect(Pipeline.runnable).to contain_exactly(@active_pipeline, due_pipeline)
      end
    end
  end

  describe 'instance methods' do
    let(:tenant) { create(:tenant) }
    let(:data_source) { create(:data_source, tenant: tenant) }
    let(:pipeline) { create(:pipeline, data_source: data_source) }

    before { ActsAsTenant.current_tenant = tenant }

    describe '#active?' do
      it 'returns true when status is active' do
        pipeline.status = 'active'
        expect(pipeline.active?).to be true
      end

      it 'returns false when status is not active' do
        pipeline.status = 'draft'
        expect(pipeline.active?).to be false
      end
    end

    describe '#scheduled?' do
      it 'returns true when schedule_type is scheduled' do
        pipeline.schedule_type = 'scheduled'
        expect(pipeline.scheduled?).to be true
      end

      it 'returns false when schedule_type is not scheduled' do
        pipeline.schedule_type = 'manual'
        expect(pipeline.scheduled?).to be false
      end
    end

    describe '#can_run?' do
      context 'when pipeline is active' do
        before { pipeline.status = 'active' }

        it 'returns true for manual pipelines' do
          pipeline.schedule_type = 'manual'
          expect(pipeline.can_run?).to be true
        end

        it 'returns true for scheduled pipelines that are due' do
          pipeline.schedule_type = 'scheduled'
          pipeline.next_run_at = 1.minute.ago
          expect(pipeline.can_run?).to be true
        end

        it 'returns false for scheduled pipelines not yet due' do
          pipeline.schedule_type = 'scheduled'
          pipeline.next_run_at = 1.hour.from_now
          expect(pipeline.can_run?).to be false
        end
      end

      context 'when pipeline is not active' do
        it 'returns false' do
          pipeline.status = 'draft'
          expect(pipeline.can_run?).to be false
        end
      end
    end

    describe '#add_step' do
      it 'adds a pipeline step with correct position' do
        step1 = pipeline.add_step(
          step_type: 'extract',
          name: 'Extract data',
          configuration: { query: 'SELECT * FROM users' }
        )

        expect(step1.position).to eq(1)
        expect(step1.step_type).to eq('extract')

        step2 = pipeline.add_step(
          step_type: 'transform',
          name: 'Transform data',
          configuration: { mapping: { id: 'user_id' } }
        )

        expect(step2.position).to eq(2)
      end
    end

    describe '#reorder_steps' do
      let!(:step1) { create(:pipeline_step, pipeline: pipeline, position: 1) }
      let!(:step2) { create(:pipeline_step, pipeline: pipeline, position: 2) }
      let!(:step3) { create(:pipeline_step, pipeline: pipeline, position: 3) }

      it 'reorders steps based on provided IDs' do
        pipeline.reorder_steps([step3.id, step1.id, step2.id])

        expect(step3.reload.position).to eq(1)
        expect(step1.reload.position).to eq(2)
        expect(step2.reload.position).to eq(3)
      end
    end

    describe '#duplicate' do
      let!(:step1) { create(:pipeline_step, pipeline: pipeline) }
      let!(:step2) { create(:pipeline_step, pipeline: pipeline) }

      it 'creates a duplicate pipeline with steps' do
        duplicate = pipeline.duplicate

        expect(duplicate).to be_persisted
        expect(duplicate.name).to eq("#{pipeline.name} (Copy)")
        expect(duplicate.status).to eq('draft')
        expect(duplicate.pipeline_steps.count).to eq(2)
        expect(duplicate.pipeline_steps.map(&:configuration)).to eq(
          pipeline.pipeline_steps.map(&:configuration)
        )
      end
    end

    describe '#calculate_next_run' do
      context 'with cron schedule' do
        it 'calculates next run time based on cron expression' do
          pipeline.schedule_type = 'scheduled'
          pipeline.schedule_cron = '0 0 * * *' # Daily at midnight

          next_run = pipeline.calculate_next_run

          expect(next_run).to be > Time.current
          expect(next_run.hour).to eq(0)
          expect(next_run.min).to eq(0)
        end
      end

      context 'with interval schedule' do
        it 'calculates next run time based on interval' do
          pipeline.schedule_type = 'scheduled'
          pipeline.schedule_interval = 3600 # 1 hour in seconds
          pipeline.last_run_at = Time.current

          next_run = pipeline.calculate_next_run

          expect(next_run).to be_within(1.second).of(1.hour.from_now)
        end
      end
    end
  end

  describe 'callbacks' do
    let(:tenant) { create(:tenant) }
    let(:data_source) { create(:data_source, tenant: tenant) }

    before { ActsAsTenant.current_tenant = tenant }

    describe 'before_validation' do
      it 'sets default status to draft' do
        pipeline = Pipeline.new(name: 'Test', data_source: data_source)
        pipeline.valid?
        expect(pipeline.status).to eq('draft')
      end
    end

    describe 'after_update' do
      it 'updates next_run_at when schedule changes' do
        pipeline = create(:pipeline,
          schedule_type: 'scheduled',
          schedule_cron: '0 0 * * *',
          data_source: data_source
        )

        expect(pipeline.next_run_at).not_to be_nil

        pipeline.update!(schedule_cron: '0 12 * * *')

        expect(pipeline.next_run_at.hour).to eq(12)
      end
    end
  end
end