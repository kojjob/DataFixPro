# Sprint 4 Enhancement: Test-Driven Development Implementation Plan

## 🎯 TDD Philosophy for Sprint 4 Enhancements

**Core Principle**: Write tests first, implementation second. Every enhancement follows the Red-Green-Refactor cycle.

## 📋 Test Coverage Requirements

- **Unit Tests**: 100% coverage for all new components and utilities
- **Integration Tests**: Full coverage for node interactions and pipeline operations
- **E2E Tests**: Critical user journeys and workflows
- **Performance Tests**: Benchmarks for all data processing operations
- **Security Tests**: Vulnerability scanning and authorization testing

## 🔴 Phase 1: Core UX Improvements - Test First

### 1.1 Undo/Redo System Tests

```javascript
// spec/javascript/hooks/useHistory.test.js
import { renderHook, act } from '@testing-library/react-hooks';
import useHistory from '../../app/javascript/hooks/useHistory';

describe('useHistory Hook', () => {
  describe('Initial State', () => {
    it('should initialize with empty history', () => {
      const { result } = renderHook(() => useHistory());
      expect(result.current.canUndo).toBe(false);
      expect(result.current.canRedo).toBe(false);
    });
  });

  describe('Push History', () => {
    it('should add state to history', () => {
      const { result } = renderHook(() => useHistory());

      act(() => {
        result.current.pushHistory({ nodes: [], edges: [] });
      });

      expect(result.current.canUndo).toBe(false); // First state, can't undo

      act(() => {
        result.current.pushHistory({ nodes: ['node1'], edges: [] });
      });

      expect(result.current.canUndo).toBe(true);
    });

    it('should truncate future history when pushing after undo', () => {
      const { result } = renderHook(() => useHistory());

      act(() => {
        result.current.pushHistory({ state: 1 });
        result.current.pushHistory({ state: 2 });
        result.current.pushHistory({ state: 3 });
      });

      act(() => {
        result.current.undo();
        result.current.undo();
      });

      act(() => {
        result.current.pushHistory({ state: 4 });
      });

      expect(result.current.canRedo).toBe(false);
    });
  });

  describe('Undo Operations', () => {
    it('should undo to previous state', () => {
      const { result } = renderHook(() => useHistory());

      act(() => {
        result.current.pushHistory({ value: 1 });
        result.current.pushHistory({ value: 2 });
        result.current.pushHistory({ value: 3 });
      });

      let previousState;
      act(() => {
        previousState = result.current.undo();
      });

      expect(previousState).toEqual({ value: 2 });
      expect(result.current.canUndo).toBe(true);
      expect(result.current.canRedo).toBe(true);
    });

    it('should not undo beyond first state', () => {
      const { result } = renderHook(() => useHistory());

      act(() => {
        result.current.pushHistory({ value: 1 });
      });

      let undoResult;
      act(() => {
        undoResult = result.current.undo();
      });

      expect(undoResult).toBeUndefined();
      expect(result.current.canUndo).toBe(false);
    });
  });

  describe('Redo Operations', () => {
    it('should redo to next state', () => {
      const { result } = renderHook(() => useHistory());

      act(() => {
        result.current.pushHistory({ value: 1 });
        result.current.pushHistory({ value: 2 });
        result.current.pushHistory({ value: 3 });
      });

      act(() => {
        result.current.undo();
        result.current.undo();
      });

      let nextState;
      act(() => {
        nextState = result.current.redo();
      });

      expect(nextState).toEqual({ value: 2 });
      expect(result.current.canRedo).toBe(true);
    });

    it('should not redo beyond last state', () => {
      const { result } = renderHook(() => useHistory());

      act(() => {
        result.current.pushHistory({ value: 1 });
      });

      let redoResult;
      act(() => {
        redoResult = result.current.redo();
      });

      expect(redoResult).toBeUndefined();
      expect(result.current.canRedo).toBe(false);
    });
  });

  describe('History Limits', () => {
    it('should maintain maximum history size', () => {
      const { result } = renderHook(() => useHistory({ maxSize: 3 }));

      act(() => {
        result.current.pushHistory({ value: 1 });
        result.current.pushHistory({ value: 2 });
        result.current.pushHistory({ value: 3 });
        result.current.pushHistory({ value: 4 });
      });

      // Should remove oldest state when exceeding max
      act(() => {
        result.current.undo();
        result.current.undo();
        result.current.undo();
      });

      expect(result.current.canUndo).toBe(false); // Only 3 states kept
    });
  });
});
```

### 1.2 Keyboard Shortcuts Tests

```javascript
// spec/javascript/hooks/useKeyboardShortcuts.test.js
import { renderHook } from '@testing-library/react-hooks';
import { fireEvent } from '@testing-library/react';
import useKeyboardShortcuts from '../../app/javascript/hooks/useKeyboardShortcuts';

describe('useKeyboardShortcuts Hook', () => {
  let handlers;

  beforeEach(() => {
    handlers = {
      undo: jest.fn(),
      redo: jest.fn(),
      deleteSelected: jest.fn(),
      selectAll: jest.fn(),
      copy: jest.fn(),
      paste: jest.fn(),
      save: jest.fn()
    };
  });

  describe('Undo Shortcut', () => {
    it('should trigger undo on Ctrl+Z', () => {
      renderHook(() => useKeyboardShortcuts(handlers));

      fireEvent.keyDown(window, {
        key: 'z',
        ctrlKey: true,
        preventDefault: jest.fn()
      });

      expect(handlers.undo).toHaveBeenCalled();
    });

    it('should trigger undo on Cmd+Z (Mac)', () => {
      renderHook(() => useKeyboardShortcuts(handlers));

      fireEvent.keyDown(window, {
        key: 'z',
        metaKey: true,
        preventDefault: jest.fn()
      });

      expect(handlers.undo).toHaveBeenCalled();
    });

    it('should not trigger undo on Z without modifier', () => {
      renderHook(() => useKeyboardShortcuts(handlers));

      fireEvent.keyDown(window, {
        key: 'z',
        preventDefault: jest.fn()
      });

      expect(handlers.undo).not.toHaveBeenCalled();
    });
  });

  describe('Redo Shortcut', () => {
    it('should trigger redo on Ctrl+Y', () => {
      renderHook(() => useKeyboardShortcuts(handlers));

      fireEvent.keyDown(window, {
        key: 'y',
        ctrlKey: true,
        preventDefault: jest.fn()
      });

      expect(handlers.redo).toHaveBeenCalled();
    });

    it('should trigger redo on Cmd+Shift+Z (Mac)', () => {
      renderHook(() => useKeyboardShortcuts(handlers));

      fireEvent.keyDown(window, {
        key: 'z',
        metaKey: true,
        shiftKey: true,
        preventDefault: jest.fn()
      });

      expect(handlers.redo).toHaveBeenCalled();
    });
  });

  describe('Delete Shortcut', () => {
    it('should trigger delete on Delete key', () => {
      renderHook(() => useKeyboardShortcuts(handlers));

      fireEvent.keyDown(window, {
        key: 'Delete',
        preventDefault: jest.fn()
      });

      expect(handlers.deleteSelected).toHaveBeenCalled();
    });

    it('should trigger delete on Backspace key', () => {
      renderHook(() => useKeyboardShortcuts(handlers));

      fireEvent.keyDown(window, {
        key: 'Backspace',
        preventDefault: jest.fn()
      });

      expect(handlers.deleteSelected).toHaveBeenCalled();
    });
  });

  describe('Copy/Paste Shortcuts', () => {
    it('should trigger copy on Ctrl+C', () => {
      renderHook(() => useKeyboardShortcuts(handlers));

      fireEvent.keyDown(window, {
        key: 'c',
        ctrlKey: true,
        preventDefault: jest.fn()
      });

      expect(handlers.copy).toHaveBeenCalled();
    });

    it('should trigger paste on Ctrl+V', () => {
      renderHook(() => useKeyboardShortcuts(handlers));

      fireEvent.keyDown(window, {
        key: 'v',
        ctrlKey: true,
        preventDefault: jest.fn()
      });

      expect(handlers.paste).toHaveBeenCalled();
    });
  });

  describe('Select All Shortcut', () => {
    it('should trigger selectAll on Ctrl+A', () => {
      renderHook(() => useKeyboardShortcuts(handlers));

      fireEvent.keyDown(window, {
        key: 'a',
        ctrlKey: true,
        preventDefault: jest.fn()
      });

      expect(handlers.selectAll).toHaveBeenCalled();
    });
  });

  describe('Save Shortcut', () => {
    it('should trigger save on Ctrl+S', () => {
      renderHook(() => useKeyboardShortcuts(handlers));

      fireEvent.keyDown(window, {
        key: 's',
        ctrlKey: true,
        preventDefault: jest.fn()
      });

      expect(handlers.save).toHaveBeenCalled();
    });
  });

  describe('Cleanup', () => {
    it('should remove event listener on unmount', () => {
      const removeEventListenerSpy = jest.spyOn(window, 'removeEventListener');
      const { unmount } = renderHook(() => useKeyboardShortcuts(handlers));

      unmount();

      expect(removeEventListenerSpy).toHaveBeenCalledWith('keydown', expect.any(Function));
    });
  });
});
```

## 🔴 Phase 2: Advanced Node Types - Test First

### 2.1 Join Node Component Tests

```javascript
// spec/javascript/components/nodes/JoinNode.test.jsx
import React from 'react';
import { render, screen } from '@testing-library/react';
import { ReactFlowProvider } from 'reactflow';
import JoinNode from '../../../../app/javascript/components/nodes/JoinNode';

describe('JoinNode Component', () => {
  const mockNodeData = {
    label: 'Join Tables',
    joinType: 'INNER',
    leftField: 'user_id',
    rightField: 'id',
    joinCondition: 'users.id = orders.user_id'
  };

  const renderNode = (data = mockNodeData) => {
    return render(
      <ReactFlowProvider>
        <JoinNode data={data} isConnectable={true} />
      </ReactFlowProvider>
    );
  };

  describe('Rendering', () => {
    it('should render join node with label', () => {
      renderNode();
      expect(screen.getByText('Join Tables')).toBeInTheDocument();
    });

    it('should display join type', () => {
      renderNode();
      expect(screen.getByText('🔗 INNER JOIN')).toBeInTheDocument();
    });

    it('should display join condition when provided', () => {
      renderNode();
      expect(screen.getByText('ON users.id = orders.user_id')).toBeInTheDocument();
    });

    it('should render with default join type when not specified', () => {
      renderNode({ label: 'Join', joinType: undefined });
      expect(screen.getByText('🔗 INNER JOIN')).toBeInTheDocument();
    });
  });

  describe('Join Types', () => {
    it.each([
      ['INNER', '🔗 INNER JOIN'],
      ['LEFT', '🔗 LEFT JOIN'],
      ['RIGHT', '🔗 RIGHT JOIN'],
      ['FULL', '🔗 FULL JOIN'],
      ['CROSS', '🔗 CROSS JOIN']
    ])('should display %s join correctly', (joinType, expectedText) => {
      renderNode({ ...mockNodeData, joinType });
      expect(screen.getByText(expectedText)).toBeInTheDocument();
    });
  });

  describe('Handles', () => {
    it('should have two input handles for left and right inputs', () => {
      const { container } = renderNode();
      const targetHandles = container.querySelectorAll('.react-flow__handle-left');
      expect(targetHandles).toHaveLength(2);
    });

    it('should have one output handle', () => {
      const { container } = renderNode();
      const sourceHandles = container.querySelectorAll('.react-flow__handle-right');
      expect(sourceHandles).toHaveLength(1);
    });
  });

  describe('Visual Styling', () => {
    it('should have indigo color scheme', () => {
      const { container } = renderNode();
      const nodeElement = container.firstChild;
      expect(nodeElement).toHaveClass('bg-indigo-50');
      expect(nodeElement).toHaveClass('border-indigo-300');
    });
  });
});
```

### 2.2 Join Configuration Panel Tests

```javascript
// spec/javascript/components/config/JoinConfig.test.jsx
import React from 'react';
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import JoinConfig from '../../../../app/javascript/components/config/JoinConfig';

describe('JoinConfig Component', () => {
  const mockNode = {
    id: 'join-1',
    data: {
      label: 'Join Node',
      joinType: 'INNER',
      leftField: '',
      rightField: '',
      additionalConditions: ''
    }
  };

  const mockOnChange = jest.fn();

  beforeEach(() => {
    jest.clearAllMocks();
  });

  const renderConfig = (node = mockNode) => {
    return render(
      <JoinConfig node={node} onChange={mockOnChange} />
    );
  };

  describe('Join Type Selection', () => {
    it('should display all join type options', () => {
      renderConfig();

      const select = screen.getByLabelText('Join Type');
      expect(select).toBeInTheDocument();

      const options = ['Inner Join', 'Left Join', 'Right Join', 'Full Outer Join', 'Cross Join'];
      options.forEach(option => {
        expect(screen.getByRole('option', { name: option })).toBeInTheDocument();
      });
    });

    it('should call onChange when join type is changed', async () => {
      renderConfig();

      const select = screen.getByLabelText('Join Type');
      await userEvent.selectOptions(select, 'LEFT');

      expect(mockOnChange).toHaveBeenCalledWith('join-1', {
        ...mockNode.data,
        joinType: 'LEFT'
      });
    });
  });

  describe('Field Selection', () => {
    it('should render left and right field dropdowns', () => {
      renderConfig();

      expect(screen.getByLabelText('Left Table Field')).toBeInTheDocument();
      expect(screen.getByLabelText('Right Table Field')).toBeInTheDocument();
    });

    it('should populate fields when connected nodes provide schema', async () => {
      const nodeWithFields = {
        ...mockNode,
        data: {
          ...mockNode.data,
          leftFields: ['id', 'user_id', 'created_at'],
          rightFields: ['id', 'order_id', 'customer_id']
        }
      };

      renderConfig(nodeWithFields);

      const leftSelect = screen.getByLabelText('Left Table Field');
      fireEvent.click(leftSelect);

      await waitFor(() => {
        expect(screen.getByText('id')).toBeInTheDocument();
        expect(screen.getByText('user_id')).toBeInTheDocument();
        expect(screen.getByText('created_at')).toBeInTheDocument();
      });
    });

    it('should update join condition when fields are selected', async () => {
      const nodeWithFields = {
        ...mockNode,
        data: {
          ...mockNode.data,
          leftFields: ['user_id'],
          rightFields: ['id']
        }
      };

      renderConfig(nodeWithFields);

      const leftSelect = screen.getByLabelText('Left Table Field');
      await userEvent.selectOptions(leftSelect, 'user_id');

      expect(mockOnChange).toHaveBeenCalledWith('join-1',
        expect.objectContaining({
          leftField: 'user_id'
        })
      );
    });
  });

  describe('Additional Conditions', () => {
    it('should render additional conditions textarea', () => {
      renderConfig();

      const textarea = screen.getByLabelText('Additional Conditions (Optional)');
      expect(textarea).toBeInTheDocument();
      expect(textarea).toHaveAttribute('placeholder', "e.g., AND left.status = 'active'");
    });

    it('should update additional conditions on input', async () => {
      renderConfig();

      const textarea = screen.getByLabelText('Additional Conditions (Optional)');
      await userEvent.type(textarea, "AND orders.amount > 100");

      expect(mockOnChange).toHaveBeenLastCalledWith('join-1',
        expect.objectContaining({
          additionalConditions: "AND orders.amount > 100"
        })
      );
    });
  });

  describe('Distinct Results Option', () => {
    it('should render distinct results checkbox', () => {
      renderConfig();

      const checkbox = screen.getByLabelText('Return distinct results only');
      expect(checkbox).toBeInTheDocument();
      expect(checkbox).not.toBeChecked();
    });

    it('should toggle distinct results option', async () => {
      renderConfig();

      const checkbox = screen.getByLabelText('Return distinct results only');
      await userEvent.click(checkbox);

      expect(mockOnChange).toHaveBeenCalledWith('join-1',
        expect.objectContaining({
          distinctResults: true
        })
      );
    });
  });

  describe('Validation', () => {
    it('should show warning when cross join is selected with conditions', () => {
      const nodeWithCrossJoin = {
        ...mockNode,
        data: {
          ...mockNode.data,
          joinType: 'CROSS',
          additionalConditions: 'WHERE x = y'
        }
      };

      renderConfig(nodeWithCrossJoin);

      expect(screen.getByText('Warning: Cross joins typically don\'t use conditions')).toBeInTheDocument();
    });

    it('should validate join fields are selected for non-cross joins', async () => {
      renderConfig();

      const saveButton = screen.getByText('Validate Configuration');
      await userEvent.click(saveButton);

      expect(screen.getByText('Please select both left and right fields for the join')).toBeInTheDocument();
    });
  });
});
```

## 🔴 Phase 3: Rails Backend Tests - RSpec

### 3.1 Pipeline Model Tests

```ruby
# spec/models/pipeline_spec.rb
require 'rails_helper'

RSpec.describe Pipeline, type: :model do
  let(:tenant) { create(:tenant) }
  let(:pipeline) { create(:pipeline, tenant: tenant) }

  describe 'validations' do
    it { should belong_to(:tenant) }
    it { should belong_to(:data_source).optional }
    it { should have_many(:pipeline_steps).dependent(:destroy) }
    it { should have_many(:pipeline_runs).dependent(:destroy) }
    it { should validate_presence_of(:name) }
    it { should validate_inclusion_of(:status).in_array(%w[draft active inactive]) }
  end

  describe '#sync_steps_from_config' do
    let(:pipeline_config) do
      {
        'nodes' => [
          {
            'id' => 'node-1',
            'type' => 'dataSource',
            'data' => { 'label' => 'Users Table', 'tableName' => 'users' }
          },
          {
            'id' => 'node-2',
            'type' => 'filter',
            'data' => { 'label' => 'Active Users', 'conditions' => ['status = active'] }
          },
          {
            'id' => 'node-3',
            'type' => 'output',
            'data' => { 'label' => 'Save Results', 'destination' => 'active_users' }
          }
        ],
        'edges' => [
          { 'source' => 'node-1', 'target' => 'node-2' },
          { 'source' => 'node-2', 'target' => 'node-3' }
        ]
      }
    end

    before do
      pipeline.pipeline_config = pipeline_config
    end

    it 'creates pipeline steps from nodes' do
      expect {
        pipeline.sync_steps_from_config
      }.to change { pipeline.pipeline_steps.count }.from(0).to(3)
    end

    it 'sets correct step types' do
      pipeline.sync_steps_from_config

      steps = pipeline.pipeline_steps.order(:position)
      expect(steps[0].step_type).to eq('dataSource')
      expect(steps[1].step_type).to eq('filter')
      expect(steps[2].step_type).to eq('output')
    end

    it 'preserves node configuration' do
      pipeline.sync_steps_from_config

      source_step = pipeline.pipeline_steps.find_by(step_type: 'dataSource')
      expect(source_step.configuration['tableName']).to eq('users')
    end

    it 'removes existing steps before syncing' do
      existing_step = create(:pipeline_step, pipeline: pipeline)

      pipeline.sync_steps_from_config

      expect(PipelineStep.exists?(existing_step.id)).to be_falsey
    end

    it 'handles empty config gracefully' do
      pipeline.pipeline_config = nil

      expect {
        pipeline.sync_steps_from_config
      }.not_to raise_error
    end
  end

  describe '#execute' do
    it 'enqueues PipelineRunnerJob' do
      expect(PipelineRunnerJob).to receive(:perform_later).with(pipeline.id)

      pipeline.execute
    end

    it 'creates a pipeline run record' do
      expect {
        pipeline.execute
      }.to change { pipeline.pipeline_runs.count }.by(1)
    end
  end

  describe '#can_run?' do
    context 'when pipeline is active and not running' do
      before do
        pipeline.update(status: 'active')
      end

      it 'returns true' do
        expect(pipeline.can_run?).to be_truthy
      end
    end

    context 'when pipeline is already running' do
      before do
        pipeline.update(status: 'active')
        create(:pipeline_run, pipeline: pipeline, status: 'running')
      end

      it 'returns false' do
        expect(pipeline.can_run?).to be_falsey
      end
    end

    context 'when pipeline is inactive' do
      before do
        pipeline.update(status: 'inactive')
      end

      it 'returns false' do
        expect(pipeline.can_run?).to be_falsey
      end
    end
  end
end
```

### 3.2 API Controller Tests

```ruby
# spec/controllers/api/pipelines_controller_spec.rb
require 'rails_helper'

RSpec.describe Api::PipelinesController, type: :controller do
  let(:user) { create(:user) }
  let(:tenant) { user.tenant }
  let(:pipeline) { create(:pipeline, tenant: tenant) }

  before do
    sign_in user
  end

  describe 'POST #create' do
    let(:valid_params) do
      {
        pipeline: {
          name: 'Test Pipeline',
          description: 'Test Description',
          status: 'draft',
          nodes: [
            { id: '1', type: 'dataSource', data: { label: 'Source' } }
          ],
          edges: []
        }
      }
    end

    context 'with valid parameters' do
      it 'creates a new pipeline' do
        expect {
          post :create, params: valid_params, format: :json
        }.to change(Pipeline, :count).by(1)
      end

      it 'stores visual flow data' do
        post :create, params: valid_params, format: :json

        pipeline = Pipeline.last
        expect(pipeline.pipeline_config['nodes']).to eq(valid_params[:pipeline][:nodes])
        expect(pipeline.pipeline_config['edges']).to eq(valid_params[:pipeline][:edges])
      end

      it 'returns success response' do
        post :create, params: valid_params, format: :json

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json['success']).to be_truthy
        expect(json['pipeline']['id']).to be_present
      end
    end

    context 'with invalid parameters' do
      let(:invalid_params) do
        {
          pipeline: {
            name: '', # Invalid: blank name
            status: 'invalid_status'
          }
        }
      end

      it 'does not create a pipeline' do
        expect {
          post :create, params: invalid_params, format: :json
        }.not_to change(Pipeline, :count)
      end

      it 'returns error response' do
        post :create, params: invalid_params, format: :json

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json['success']).to be_falsey
        expect(json['errors']).to include("Name can't be blank")
      end
    end
  end

  describe 'PUT #update' do
    let(:update_params) do
      {
        id: pipeline.id,
        pipeline: {
          name: 'Updated Pipeline',
          nodes: [
            { id: '1', type: 'dataSource', data: { label: 'Updated Source' } },
            { id: '2', type: 'filter', data: { label: 'New Filter' } }
          ],
          edges: [
            { source: '1', target: '2' }
          ]
        }
      }
    end

    it 'updates the pipeline' do
      put :update, params: update_params, format: :json

      pipeline.reload
      expect(pipeline.name).to eq('Updated Pipeline')
    end

    it 'updates visual flow data' do
      put :update, params: update_params, format: :json

      pipeline.reload
      expect(pipeline.pipeline_config['nodes'].length).to eq(2)
      expect(pipeline.pipeline_config['edges'].length).to eq(1)
    end

    it 'returns success response' do
      put :update, params: update_params, format: :json

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json['success']).to be_truthy
    end

    context 'when pipeline belongs to another tenant' do
      let(:other_pipeline) { create(:pipeline) }

      it 'returns not found' do
        put :update, params: { id: other_pipeline.id, pipeline: { name: 'Hacked' } }, format: :json

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'POST #run' do
    before do
      pipeline.update(status: 'active')
    end

    it 'starts pipeline execution' do
      expect(PipelineRunnerJob).to receive(:perform_later).with(pipeline.id)

      post :run, params: { id: pipeline.id }, format: :json
    end

    it 'returns success response' do
      post :run, params: { id: pipeline.id }, format: :json

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json['message']).to eq('Pipeline execution started')
    end

    context 'when pipeline is already running' do
      before do
        create(:pipeline_run, pipeline: pipeline, status: 'running')
      end

      it 'returns error response' do
        post :run, params: { id: pipeline.id }, format: :json

        expect(response).to have_http_status(:conflict)
        json = JSON.parse(response.body)
        expect(json['error']).to eq('Pipeline is already running')
      end
    end
  end

  describe 'GET #status' do
    let!(:pipeline_run) { create(:pipeline_run, pipeline: pipeline, status: 'completed') }

    it 'returns pipeline status' do
      get :status, params: { id: pipeline.id }, format: :json

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json['status']).to eq(pipeline.status)
      expect(json['last_run']).to be_present
      expect(json['last_run']['status']).to eq('completed')
    end
  end
end
```

## 🔴 Phase 4: Integration & E2E Tests

### 4.1 Pipeline Builder E2E Tests (Playwright)

```javascript
// e2e/pipeline-builder.spec.js
import { test, expect } from '@playwright/test';

test.describe('Pipeline Builder E2E', () => {
  test.beforeEach(async ({ page }) => {
    // Login and navigate to pipeline builder
    await page.goto('/');
    await page.fill('#email', 'test@example.com');
    await page.fill('#password', 'password123');
    await page.click('button[type="submit"]');

    await page.waitForURL('/pipeline_builders/new');
  });

  test('should create a complete pipeline workflow', async ({ page }) => {
    // Step 1: Drag data source node
    const sidebar = page.locator('aside');
    const canvas = page.locator('.react-flow');

    await sidebar.locator('text=Data Source').dragTo(canvas, {
      targetPosition: { x: 200, y: 100 }
    });

    // Step 2: Configure data source
    await page.click('.react-flow__node-dataSource');
    await page.selectOption('select[name="sourceType"]', 'database');
    await page.fill('input[name="tableName"]', 'users');

    // Step 3: Add transform node
    await sidebar.locator('text=Transform').dragTo(canvas, {
      targetPosition: { x: 400, y: 100 }
    });

    // Step 4: Connect nodes
    const sourceHandle = page.locator('.react-flow__node-dataSource .react-flow__handle-source');
    const targetHandle = page.locator('.react-flow__node-transform .react-flow__handle-target');

    await sourceHandle.dragTo(targetHandle);

    // Step 5: Add filter node
    await sidebar.locator('text=Filter').dragTo(canvas, {
      targetPosition: { x: 600, y: 100 }
    });

    // Step 6: Connect transform to filter
    await page.locator('.react-flow__node-transform .react-flow__handle-source')
      .dragTo(page.locator('.react-flow__node-filter .react-flow__handle-target'));

    // Step 7: Add output node
    await sidebar.locator('text=Output').dragTo(canvas, {
      targetPosition: { x: 800, y: 100 }
    });

    // Step 8: Connect filter to output
    await page.locator('.react-flow__node-filter .react-flow__handle-source')
      .dragTo(page.locator('.react-flow__node-output .react-flow__handle-target'));

    // Step 9: Save pipeline
    await page.fill('input[name="pipelineName"]', 'Test E2E Pipeline');
    await page.click('button:has-text("Save Pipeline")');

    // Verify success
    await expect(page.locator('text=Pipeline saved successfully')).toBeVisible();
  });

  test('should support undo/redo operations', async ({ page }) => {
    const sidebar = page.locator('aside');
    const canvas = page.locator('.react-flow');

    // Add multiple nodes
    await sidebar.locator('text=Data Source').dragTo(canvas, {
      targetPosition: { x: 200, y: 100 }
    });

    await sidebar.locator('text=Transform').dragTo(canvas, {
      targetPosition: { x: 400, y: 100 }
    });

    // Verify 2 nodes exist
    await expect(page.locator('.react-flow__node')).toHaveCount(2);

    // Undo last action (Ctrl+Z)
    await page.keyboard.press('Control+Z');
    await expect(page.locator('.react-flow__node')).toHaveCount(1);

    // Redo (Ctrl+Y)
    await page.keyboard.press('Control+Y');
    await expect(page.locator('.react-flow__node')).toHaveCount(2);
  });

  test('should handle keyboard shortcuts', async ({ page }) => {
    const sidebar = page.locator('aside');
    const canvas = page.locator('.react-flow');

    // Add nodes
    await sidebar.locator('text=Data Source').dragTo(canvas, {
      targetPosition: { x: 200, y: 100 }
    });

    await sidebar.locator('text=Filter').dragTo(canvas, {
      targetPosition: { x: 400, y: 100 }
    });

    // Select all (Ctrl+A)
    await page.keyboard.press('Control+A');
    await expect(page.locator('.react-flow__node.selected')).toHaveCount(2);

    // Delete selected
    await page.keyboard.press('Delete');
    await expect(page.locator('.react-flow__node')).toHaveCount(0);
  });

  test('should validate pipeline before saving', async ({ page }) => {
    // Try to save empty pipeline
    await page.click('button:has-text("Save Pipeline")');

    // Should show validation error
    await expect(page.locator('text=Pipeline must contain at least one node')).toBeVisible();
  });

  test('should show performance metrics during execution', async ({ page }) => {
    // Create a simple pipeline
    const sidebar = page.locator('aside');
    const canvas = page.locator('.react-flow');

    await sidebar.locator('text=Data Source').dragTo(canvas, {
      targetPosition: { x: 200, y: 100 }
    });

    // Save and run pipeline
    await page.fill('input[name="pipelineName"]', 'Performance Test');
    await page.click('button:has-text("Save Pipeline")');
    await page.click('button:has-text("Run Pipeline")');

    // Check performance monitor appears
    await expect(page.locator('.pipeline-monitor')).toBeVisible();
    await expect(page.locator('text=Processing Time')).toBeVisible();
    await expect(page.locator('text=Records Processed')).toBeVisible();
    await expect(page.locator('text=Memory Usage')).toBeVisible();
  });
});
```

## 🎯 TDD Workflow for Each Enhancement

### Standard TDD Cycle for New Features

1. **Write Failing Test** (Red)
   ```bash
   npm test -- --watch useHistory.test.js
   # Test fails because hook doesn't exist
   ```

2. **Implement Minimum Code** (Green)
   ```javascript
   // Implement just enough to make test pass
   const useHistory = () => {
     return { canUndo: false, canRedo: false };
   };
   ```

3. **Refactor** (Refactor)
   - Improve code structure
   - Remove duplication
   - Enhance readability
   - Ensure tests still pass

4. **Add Next Test**
   - Write test for next behavior
   - Repeat cycle

## 📊 Test Coverage Goals

```yaml
coverage_requirements:
  unit_tests:
    target: 100%
    minimum: 95%

  integration_tests:
    target: 90%
    minimum: 85%

  e2e_tests:
    critical_paths: 100%
    happy_paths: 90%
    edge_cases: 80%

  performance_tests:
    benchmarks: All data operations
    load_tests: 1000+ concurrent users
    stress_tests: 1M+ records
```

## 🚀 Test Execution Strategy

```bash
# Run all tests before any commit
npm test
bundle exec rspec

# Run specific test suites
npm test -- --testPathPattern=hooks
bundle exec rspec spec/models

# Run with coverage
npm test -- --coverage
COVERAGE=true bundle exec rspec

# Run E2E tests
npx playwright test

# Run performance tests
npm run test:performance
bundle exec rspec spec/performance
```

## ✅ Definition of Done

A feature is only considered complete when:

1. **All tests pass** (unit, integration, E2E)
2. **Coverage meets requirements** (>95% for new code)
3. **Performance benchmarks met**
4. **Security tests pass**
5. **Code review approved**
6. **Documentation updated**
7. **Deployed to staging**
8. **Acceptance tests pass**

This TDD approach ensures that every enhancement to Sprint 4 is thoroughly tested, maintainable, and production-ready.