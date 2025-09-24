import React from 'react';
import { render, screen } from '@testing-library/react';
import { ReactFlowProvider } from 'reactflow';
import JoinNode from '../../components/nodes/JoinNode';

// Mock ReactFlow hooks
jest.mock('reactflow', () => ({
  ...jest.requireActual('reactflow'),
  Handle: ({ type, position, id, style }) => (
    <div data-testid={`handle-${type}-${id}`} data-position={position} style={style}>
      Handle
    </div>
  ),
  Position: {
    Top: 'top',
    Right: 'right',
    Bottom: 'bottom',
    Left: 'left'
  },
  useUpdateNodeInternals: () => jest.fn()
}));

describe('JoinNode Component', () => {
  const mockData = {
    label: 'Join Tables',
    joinType: 'inner',
    leftTable: 'users',
    rightTable: 'orders',
    joinConditions: [
      {
        leftField: 'id',
        operator: '=',
        rightField: 'user_id'
      }
    ],
    selectedFields: {
      left: ['users.id', 'users.name', 'users.email'],
      right: ['orders.id', 'orders.total', 'orders.created_at']
    }
  };

  const defaultProps = {
    id: 'join-1',
    data: mockData,
    selected: false
  };

  const renderJoinNode = (props = {}) => {
    return render(
      <ReactFlowProvider>
        <JoinNode {...defaultProps} {...props} />
      </ReactFlowProvider>
    );
  };

  describe('Rendering', () => {
    it('should render the join node with correct label', () => {
      renderJoinNode();
      expect(screen.getByText('Join Tables')).toBeInTheDocument();
    });

    it('should display the join type badge', () => {
      renderJoinNode();
      expect(screen.getByText('INNER')).toBeInTheDocument();
    });

    it('should show the table names being joined', () => {
      renderJoinNode();
      expect(screen.getByText(/users/)).toBeInTheDocument();
      expect(screen.getByText(/orders/)).toBeInTheDocument();
    });

    it('should have the correct icon', () => {
      renderJoinNode();
      expect(screen.getByText('🔗')).toBeInTheDocument();
    });

    it('should apply selected styles when selected', () => {
      const { container } = renderJoinNode({ selected: true });
      const nodeElement = container.firstChild;
      expect(nodeElement).toHaveClass('ring-2');
      expect(nodeElement).toHaveClass('ring-indigo-500');
    });

    it('should render with validation state when present', () => {
      const dataWithValidation = {
        ...mockData,
        validation: { isValid: true }
      };
      renderJoinNode({ data: dataWithValidation });
      expect(screen.getByText('✓')).toBeInTheDocument();
    });

    it('should render with error state when validation fails', () => {
      const dataWithError = {
        ...mockData,
        validation: { isValid: false, error: 'Missing join condition' }
      };
      renderJoinNode({ data: dataWithError });
      expect(screen.getByText('⚠️')).toBeInTheDocument();
      expect(screen.getByTitle('Missing join condition')).toBeInTheDocument();
    });
  });

  describe('Handles', () => {
    it('should render two input handles (left and right tables)', () => {
      renderJoinNode();
      expect(screen.getByTestId('handle-target-left')).toBeInTheDocument();
      expect(screen.getByTestId('handle-target-right')).toBeInTheDocument();
    });

    it('should render one output handle', () => {
      renderJoinNode();
      expect(screen.getByTestId('handle-source-output')).toBeInTheDocument();
    });

    it('should position handles correctly', () => {
      renderJoinNode();
      expect(screen.getByTestId('handle-target-left')).toHaveAttribute('data-position', 'left');
      expect(screen.getByTestId('handle-target-right')).toHaveAttribute('data-position', 'left');
      expect(screen.getByTestId('handle-source-output')).toHaveAttribute('data-position', 'right');
    });
  });

  describe('Join Types', () => {
    it('should display INNER join correctly', () => {
      renderJoinNode();
      expect(screen.getByText('INNER')).toBeInTheDocument();
      expect(screen.getByText('INNER')).toHaveClass('bg-blue-100', 'text-blue-800');
    });

    it('should display LEFT join correctly', () => {
      const leftJoinData = { ...mockData, joinType: 'left' };
      renderJoinNode({ data: leftJoinData });
      expect(screen.getByText('LEFT')).toBeInTheDocument();
      expect(screen.getByText('LEFT')).toHaveClass('bg-green-100', 'text-green-800');
    });

    it('should display RIGHT join correctly', () => {
      const rightJoinData = { ...mockData, joinType: 'right' };
      renderJoinNode({ data: rightJoinData });
      expect(screen.getByText('RIGHT')).toBeInTheDocument();
      expect(screen.getByText('RIGHT')).toHaveClass('bg-yellow-100', 'text-yellow-800');
    });

    it('should display FULL join correctly', () => {
      const fullJoinData = { ...mockData, joinType: 'full' };
      renderJoinNode({ data: fullJoinData });
      expect(screen.getByText('FULL')).toBeInTheDocument();
      expect(screen.getByText('FULL')).toHaveClass('bg-purple-100', 'text-purple-800');
    });
  });

  describe('Join Conditions', () => {
    it('should display join conditions', () => {
      renderJoinNode();
      // Should show simplified condition format
      expect(screen.getByText(/id = user_id/)).toBeInTheDocument();
    });

    it('should handle multiple join conditions', () => {
      const multiConditionData = {
        ...mockData,
        joinConditions: [
          { leftField: 'id', operator: '=', rightField: 'user_id' },
          { leftField: 'tenant_id', operator: '=', rightField: 'tenant_id' }
        ]
      };
      renderJoinNode({ data: multiConditionData });
      expect(screen.getByText(/2 conditions/)).toBeInTheDocument();
    });

    it('should show warning when no join conditions', () => {
      const noConditionData = {
        ...mockData,
        joinConditions: []
      };
      renderJoinNode({ data: noConditionData });
      expect(screen.getByText(/No conditions/)).toBeInTheDocument();
    });
  });

  describe('Field Selection', () => {
    it('should show field count when fields are selected', () => {
      renderJoinNode();
      expect(screen.getByText(/6 fields/)).toBeInTheDocument(); // 3 from users + 3 from orders
    });

    it('should show warning when no fields selected', () => {
      const noFieldsData = {
        ...mockData,
        selectedFields: { left: [], right: [] }
      };
      renderJoinNode({ data: noFieldsData });
      expect(screen.getByText(/No fields selected/)).toBeInTheDocument();
    });

    it('should show all fields indicator when asterisk is used', () => {
      const allFieldsData = {
        ...mockData,
        selectedFields: { left: ['*'], right: ['*'] }
      };
      renderJoinNode({ data: allFieldsData });
      expect(screen.getByText(/All fields/)).toBeInTheDocument();
    });
  });

  describe('Processing State', () => {
    it('should show processing indicator when processing', () => {
      const processingData = {
        ...mockData,
        isProcessing: true
      };
      renderJoinNode({ data: processingData });
      expect(screen.getByTestId('processing-spinner')).toBeInTheDocument();
    });

    it('should show row count when available', () => {
      const dataWithRows = {
        ...mockData,
        rowCount: 1250
      };
      renderJoinNode({ data: dataWithRows });
      expect(screen.getByText(/1,250 rows/)).toBeInTheDocument();
    });

    it('should show execution time when available', () => {
      const dataWithTime = {
        ...mockData,
        executionTime: 245
      };
      renderJoinNode({ data: dataWithTime });
      expect(screen.getByText(/245ms/)).toBeInTheDocument();
    });
  });

  describe('Visual States', () => {
    it('should have hover effects on the node', () => {
      const { container } = renderJoinNode();
      const nodeElement = container.firstChild;
      expect(nodeElement).toHaveClass('hover:shadow-lg');
    });

    it('should use proper color scheme for join node', () => {
      const { container } = renderJoinNode();
      const nodeElement = container.firstChild;
      expect(nodeElement).toHaveClass('bg-gradient-to-br');
      expect(nodeElement).toHaveClass('from-indigo-50');
      expect(nodeElement).toHaveClass('to-indigo-100');
    });

    it('should show connected state when both inputs connected', () => {
      const connectedData = {
        ...mockData,
        inputsConnected: { left: true, right: true }
      };
      renderJoinNode({ data: connectedData });
      expect(screen.getByTestId('connected-indicator')).toHaveClass('text-green-600');
    });

    it('should show disconnected state when inputs missing', () => {
      const disconnectedData = {
        ...mockData,
        inputsConnected: { left: true, right: false }
      };
      renderJoinNode({ data: disconnectedData });
      expect(screen.getByTestId('connected-indicator')).toHaveClass('text-yellow-600');
    });
  });
});