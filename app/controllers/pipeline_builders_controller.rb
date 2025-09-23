class PipelineBuildersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_pipeline, only: [:edit]
  before_action :set_tenant

  def new
    @pipeline = @tenant.pipelines.new
  end

  def edit
    # Pipeline data will be loaded in the React component
  end

  def create
    @pipeline = @tenant.pipelines.new(pipeline_params)
    @pipeline.status = 'draft'

    if @pipeline.save
      render json: {
        success: true,
        pipeline_id: @pipeline.id,
        redirect_url: edit_pipeline_builder_path(@pipeline)
      }
    else
      render json: {
        success: false,
        errors: @pipeline.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  def update
    @pipeline = @tenant.pipelines.find(params[:id])

    if @pipeline.update(pipeline_params)
      render json: {
        success: true,
        message: 'Pipeline updated successfully'
      }
    else
      render json: {
        success: false,
        errors: @pipeline.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  private

  def set_tenant
    @tenant = current_user.tenant
  end

  def set_pipeline
    @pipeline = @tenant.pipelines.find(params[:id])
  end

  def pipeline_params
    params.require(:pipeline).permit(
      :name,
      :description,
      :status,
      :data_source_id,
      pipeline_config: {}
    )
  end
end