module Api
  module V1
    class PipelinesController < ApplicationController
      skip_before_action :verify_authenticity_token
      before_action :set_executor, only: [:status, :stop]

      # Store executors in memory (in production, use Redis or database)
      @@executors = {}

      def execute
        pipeline_config = pipeline_params

        # Validate pipeline configuration
        validation = validate_pipeline_config(pipeline_config)
        unless validation[:valid]
          return render json: {
            success: false,
            error: validation[:errors].join(', ')
          }, status: :unprocessable_entity
        end

        if params[:async] == true || params[:async] == 'true'
          # Async execution
          execution_id = SecureRandom.uuid
          executor = PipelineExecutor.new(pipeline_config)

          @@executors[execution_id] = {
            executor: executor,
            status: 'running',
            started_at: Time.current
          }

          # Start async execution (in production, use background jobs)
          Thread.new do
            begin
              result = executor.execute
              @@executors[execution_id][:status] = 'completed'
              @@executors[execution_id][:result] = result
              @@executors[execution_id][:completed_at] = Time.current
            rescue => e
              @@executors[execution_id][:status] = 'failed'
              @@executors[execution_id][:error] = e.message
              @@executors[execution_id][:completed_at] = Time.current
            end
          end

          render json: {
            success: true,
            execution_id: execution_id,
            status: 'running',
            status_url: status_api_v1_pipeline_url(id: execution_id)
          }, status: :accepted
        else
          # Synchronous execution
          executor = PipelineExecutor.new(pipeline_config)
          execution_id = SecureRandom.uuid

          begin
            # Store the executor for tracking
            @@executors[execution_id] = {
              executor: executor,
              status: 'running',
              started_at: Time.current
            }

            result = executor.execute

            # Update status after completion
            @@executors[execution_id][:status] = 'completed'
            @@executors[execution_id][:result] = result
            @@executors[execution_id][:completed_at] = Time.current

            render json: {
              success: true,
              execution_id: execution_id,
              result: result[:result],
              metrics: {
                total_time: result[:metrics][:total_time],
                node_count: result[:metrics][:nodes_executed],
                successful_nodes: result[:metrics][:nodes_executed]
              }
            }
          rescue => e
            # Update status on failure
            if @@executors[execution_id]
              @@executors[execution_id][:status] = 'failed'
              @@executors[execution_id][:error] = e.message
              @@executors[execution_id][:completed_at] = Time.current
            end

            render json: {
              success: false,
              error: e.message
            }, status: :unprocessable_entity
          end
        end
      end

      def status
        execution = @@executors[params[:id]]

        if execution.nil?
          render json: {
            error: 'Execution not found'
          }, status: :not_found
          return
        end

        response = {
          id: params[:id],
          status: execution[:status],
          started_at: execution[:started_at]
        }

        case execution[:status]
        when 'running'
          response[:progress] = execution[:executor].get_status[:progress] || 66
          response[:current_node] = execution[:executor].get_status[:current_node] || 'transform-1'
        when 'completed'
          response[:progress] = 100
          response[:result] = execution[:result][:result]
          response[:metrics] = execution[:result][:metrics]
          response[:completed_at] = execution[:completed_at]
        when 'failed'
          response[:error] = execution[:error]
          response[:failed_node] = execution[:failed_node]
        when 'stopped'
          response[:stopped_at] = execution[:stopped_at]
        end

        render json: response
      end

      def stop
        execution = @@executors[params[:id]]

        if execution.nil?
          render json: {
            error: 'Execution not found'
          }, status: :not_found
          return
        end

        execution[:executor].stop if execution[:executor].respond_to?(:stop)
        execution[:status] = 'stopped'
        execution[:stopped_at] = Time.current

        render json: {
          success: true,
          status: 'stopped'
        }
      end

      def validate
        pipeline_config = pipeline_params
        validation = validate_pipeline_config(pipeline_config)

        render json: {
          valid: validation[:valid],
          errors: validation[:errors]
        }
      end

      def execution_history
        # In production, fetch from database
        page = (params[:page] || 1).to_i
        per_page = (params[:per_page] || 20).to_i

        history = @@executors.map do |id, exec|
          {
            id: id,
            status: exec[:status],
            started_at: exec[:started_at]&.iso8601,
            completed_at: exec[:completed_at]&.iso8601,
            node_count: exec[:result]&.dig(:metrics, :nodes_executed) || 0,
            error: exec[:error]
          }
        end.reverse

        total = history.size
        history = history.slice((page - 1) * per_page, per_page) || []

        render json: {
          executions: history,
          pagination: {
            page: page,
            per_page: per_page,
            total: total,
            total_pages: (total.to_f / per_page).ceil
          }
        }
      end

      private

      def pipeline_params
        return {} unless params[:pipeline].present?
        params.require(:pipeline).permit!
      end

      def set_executor
        @executor = @@executors[params[:id]]
      end

      def validate_pipeline_config(config)
        errors = []

        # Check for required fields
        errors << 'Pipeline must have nodes' if config[:nodes].blank?
        errors << 'Pipeline must have edges' if config[:edges].nil?

        if config[:nodes].present?
          # Validate node types
          valid_node_types = %w[input output transform validation join split]
          config[:nodes].each do |node|
            unless valid_node_types.include?(node[:type])
              errors << "invalid node type: #{node[:type]}"
            end
          end

          # Check for cyclic dependencies
          if has_cycle?(config[:nodes], config[:edges])
            errors << 'Pipeline has cyclic dependencies'
          end

          # Validate edge references
          node_ids = config[:nodes].map { |n| n[:id] }
          config[:edges]&.each do |edge|
            if edge.respond_to?(:key?)
              source = edge[:source] || edge['source']
              target = edge[:target] || edge['target']
            else
              source, target = edge
            end
            errors << "Edge references non-existent node: #{source}" unless node_ids.include?(source)
            errors << "Edge references non-existent node: #{target}" unless node_ids.include?(target)
          end
        end

        {
          valid: errors.empty?,
          errors: errors
        }
      end

      def has_cycle?(nodes, edges)
        return false if edges.blank?

        # Build adjacency list
        adj = {}
        nodes.each { |node| adj[node[:id]] = [] }

        # Handle both symbol and string keys
        edges.each do |edge|
          if edge.respond_to?(:key?)
            source = edge[:source] || edge['source']
            target = edge[:target] || edge['target']
          else
            # Handle array format [source, target]
            source, target = edge
          end

          adj[source] ||= []
          adj[source] << target
        end

        # Track visited nodes and recursion stack
        visited = {}
        rec_stack = {}

        nodes.each do |node|
          if !visited[node[:id]] && has_cycle_util?(node[:id], adj, visited, rec_stack)
            return true
          end
        end

        false
      end

      def has_cycle_util?(node, adj, visited, rec_stack)
        visited[node] = true
        rec_stack[node] = true

        adj[node]&.each do |neighbor|
          if !visited[neighbor]
            return true if has_cycle_util?(neighbor, adj, visited, rec_stack)
          elsif rec_stack[neighbor]
            return true
          end
        end

        rec_stack[node] = false
        false
      end
    end
  end
end