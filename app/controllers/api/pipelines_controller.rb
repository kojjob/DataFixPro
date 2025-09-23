module Api
  class PipelinesController < ApplicationController
    skip_before_action :verify_authenticity_token
    before_action :authenticate_user!
    before_action :set_tenant
    before_action :set_pipeline, only: [:update, :run, :stop, :status]

    def create
      @pipeline = @tenant.pipelines.new(pipeline_params)

      # Store the visual flow data
      if params[:pipeline][:nodes] && params[:pipeline][:edges]
        @pipeline.pipeline_config = {
          nodes: params[:pipeline][:nodes],
          edges: params[:pipeline][:edges]
        }
      end

      if @pipeline.save
        render json: {
          success: true,
          pipeline: {
            id: @pipeline.id,
            name: @pipeline.name
          }
        }
      else
        render json: {
          success: false,
          errors: @pipeline.errors.full_messages
        }, status: :unprocessable_entity
      end
    end

    def update
      # Store the visual flow data
      if params[:pipeline][:nodes] && params[:pipeline][:edges]
        @pipeline.pipeline_config = {
          nodes: params[:pipeline][:nodes],
          edges: params[:pipeline][:edges]
        }
      end

      if @pipeline.update(pipeline_params)
        render json: {
          success: true,
          message: 'Pipeline saved successfully'
        }
      else
        render json: {
          success: false,
          errors: @pipeline.errors.full_messages
        }, status: :unprocessable_entity
      end
    end

    def run
      # Start pipeline execution
      PipelineRunnerJob.perform_later(@pipeline.id)

      render json: {
        success: true,
        message: 'Pipeline execution started'
      }
    end

    def stop
      # Stop pipeline execution
      # Implementation would depend on your job management strategy

      render json: {
        success: true,
        message: 'Pipeline stop requested'
      }
    end

    def status
      last_run = @pipeline.pipeline_runs.order(created_at: :desc).first

      render json: {
        success: true,
        status: @pipeline.status,
        last_run: last_run ? {
          id: last_run.id,
          status: last_run.status,
          started_at: last_run.started_at,
          completed_at: last_run.completed_at,
          error_message: last_run.error_message
        } : nil
      }
    end

    private

    def set_tenant
      @tenant = current_user.tenant
    end

    def set_pipeline
      @pipeline = @tenant.pipelines.find(params[:id])
    end

    def pipeline_params
      params.require(:pipeline).permit(:name, :description, :status)
    end
  end
end