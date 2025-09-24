import React from 'react';
import { render, screen } from '@testing-library/react';
import { ReactFlowProvider } from 'reactflow';
import SplitNode from '../../components/nodes/SplitNode';

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

describe('SplitNode Component', () => {
  const mockData = {
    label: 'Split Data',
    splitType: 'conditional',
    conditions: [
      {
        id: '1',
        name: 'High Value',
        field: 'amount',
        operator: '>',
        value: '1000'
      },
      {
        id: '2',
        name: 'Low Value',
        field: 'amount',
        operator: '<=',
        value: '1000'
      }
    ],
    outputPorts: ['output1', 'output2'],
    rowCounts: {
      output1: 750,
      output2: 250
    }
  };

  const defaultProps = {
    id: 'split-1',
    data: mockData,
    selected: false
  };

  const renderSplitNode = (props = {}) => {
    return render(
      <ReactFlowProvider>
        <SplitNode {...defaultProps} {...props} />
      </ReactFlowProvider>
    );
  };

  describe('Rendering', () => {
    it('should render the split node with correct label', () => {
      renderSplitNode();
      expect(screen.getByText('Split Data')).toBeInTheDocument();
    });

    it('should display the split icon', () => {
      renderSplitNode();
      expect(screen.getByText('🔀')).toBeInTheDocument();
    });

    it('should apply selected styles when selected', () => {
      const { container } = renderSplitNode({ selected: true });
      const nodeElement = container.firstChild;
      expect(nodeElement).toHaveClass('ring-2');
      expect(nodeElement).toHaveClass('ring-purple-500');
    });

    it('should render processing indicator when processing', () => {
      const processingData = {
        ...mockData,
        isProcessing: true
      };
      renderSplitNode({ data: processingData });
      expect(screen.getByTestId('processing-spinner')).toBeInTheDocument();
    });
  });

  describe('Handles', () => {
    it('should render one input handle', () => {
      renderSplitNode();
      expect(screen.getByTestId('handle-target-input')).toBeInTheDocument();
    });

    it('should render multiple output handles based on conditions', () => {
      renderSplitNode();
      expect(screen.getByTestId('handle-source-output1')).toBeInTheDocument();
      expect(screen.getByTestId('handle-source-output2')).toBeInTheDocument();
    });

    it('should position handles correctly', () => {
      renderSplitNode();
      expect(screen.getByTestId('handle-target-input')).toHaveAttribute('data-position', 'left');
      expect(screen.getByTestId('handle-source-output1')).toHaveAttribute('data-position', 'right');
      expect(screen.getByTestId('handle-source-output2')).toHaveAttribute('data-position', 'right');
    });
  });

  describe('Split Types', () => {
    it('should display conditional split type', () => {
      renderSplitNode();
      expect(screen.getByText('CONDITIONAL')).toBeInTheDocument();
    });

    it('should display random split type', () => {
      const randomData = {
        ...mockData,
        splitType: 'random',
        splitRatio: [70, 30]
      };
      renderSplitNode({ data: randomData });
      expect(screen.getByText('RANDOM')).toBeInTheDocument();
      expect(screen.getByText('70% / 30%')).toBeInTheDocument();
    });

    it('should display hash split type', () => {
      const hashData = {
        ...mockData,
        splitType: 'hash',
        hashField: 'user_id',
        buckets: 3
      };
      renderSplitNode({ data: hashData });
      expect(screen.getByText('HASH')).toBeInTheDocument();
      expect(screen.getByText('Field: user_id')).toBeInTheDocument();
      expect(screen.getByText('3 buckets')).toBeInTheDocument();
    });

    it('should display round-robin split type', () => {
      const roundRobinData = {
        ...mockData,
        splitType: 'round-robin'
      };
      renderSplitNode({ data: roundRobinData });
      expect(screen.getByText('ROUND-ROBIN')).toBeInTheDocument();
    });
  });

  describe('Conditions Display', () => {
    it('should display condition names and criteria for conditional split', () => {
      renderSplitNode();
      expect(screen.getByText('High Value')).toBeInTheDocument();
      expect(screen.getByText('amount > 1000')).toBeInTheDocument();
      expect(screen.getByText('Low Value')).toBeInTheDocument();
      expect(screen.getByText('amount <= 1000')).toBeInTheDocument();
    });

    it('should display default output when no conditions', () => {
      const noConditionData = {
        ...mockData,
        conditions: []
      };
      renderSplitNode({ data: noConditionData });
      expect(screen.getByText('No conditions defined')).toBeInTheDocument();
    });

    it('should apply different colors for each output port', () => {
      renderSplitNode();
      const output1 = screen.getByTestId('output-port-1');
      const output2 = screen.getByTestId('output-port-2');
      expect(output1).toHaveClass('bg-blue-100');
      expect(output2).toHaveClass('bg-green-100');
    });
  });

  describe('Statistics Display', () => {
    it('should display row counts for each output', () => {
      renderSplitNode();
      expect(screen.getByText('750 rows')).toBeInTheDocument();
      expect(screen.getByText('250 rows')).toBeInTheDocument();
    });

    it('should display percentage distribution', () => {
      renderSplitNode();
      expect(screen.getByText('(75%)')).toBeInTheDocument();
      expect(screen.getByText('(25%)')).toBeInTheDocument();
    });

    it('should handle missing statistics gracefully', () => {
      const noStatsData = {
        ...mockData,
        rowCounts: undefined
      };
      renderSplitNode({ data: noStatsData });
      // Should not crash and display node normally
      expect(screen.getByText('Split Data')).toBeInTheDocument();
    });
  });

  describe('Validation States', () => {
    it('should show valid indicator when validation passes', () => {
      const validData = {
        ...mockData,
        validation: { isValid: true }
      };
      renderSplitNode({ data: validData });
      expect(screen.getByText('✓')).toBeInTheDocument();
    });

    it('should show warning indicator when validation fails', () => {
      const invalidData = {
        ...mockData,
        validation: { isValid: false, error: 'Conditions overlap' }
      };
      renderSplitNode({ data: invalidData });
      expect(screen.getByText('⚠️')).toBeInTheDocument();
      expect(screen.getByTitle('Conditions overlap')).toBeInTheDocument();
    });
  });

  describe('Visual States', () => {
    it('should have hover effects on the node', () => {
      const { container } = renderSplitNode();
      const nodeElement = container.firstChild;
      expect(nodeElement).toHaveClass('hover:shadow-lg');
    });

    it('should use purple gradient for split node', () => {
      const { container } = renderSplitNode();
      const nodeElement = container.firstChild;
      expect(nodeElement).toHaveClass('bg-gradient-to-br');
      expect(nodeElement).toHaveClass('from-purple-50');
      expect(nodeElement).toHaveClass('to-purple-100');
    });

    it('should show connected state when input is connected', () => {
      const connectedData = {
        ...mockData,
        inputConnected: true
      };
      renderSplitNode({ data: connectedData });
      expect(screen.getByTestId('connected-indicator')).toHaveClass('text-green-600');
    });

    it('should show disconnected state when input is not connected', () => {
      const disconnectedData = {
        ...mockData,
        inputConnected: false
      };
      renderSplitNode({ data: disconnectedData });
      expect(screen.getByTestId('connected-indicator')).toHaveClass('text-gray-400');
    });
  });

  describe('Special Cases', () => {
    it('should handle dynamic number of outputs', () => {
      const multiOutputData = {
        ...mockData,
        conditions: [
          { id: '1', name: 'Output 1', field: 'type', operator: '=', value: 'A' },
          { id: '2', name: 'Output 2', field: 'type', operator: '=', value: 'B' },
          { id: '3', name: 'Output 3', field: 'type', operator: '=', value: 'C' },
          { id: '4', name: 'Output 4', field: 'type', operator: '=', value: 'D' }
        ],
        outputPorts: ['output1', 'output2', 'output3', 'output4']
      };
      renderSplitNode({ data: multiOutputData });

      expect(screen.getByTestId('handle-source-output1')).toBeInTheDocument();
      expect(screen.getByTestId('handle-source-output2')).toBeInTheDocument();
      expect(screen.getByTestId('handle-source-output3')).toBeInTheDocument();
      expect(screen.getByTestId('handle-source-output4')).toBeInTheDocument();
    });

    it('should display else condition if present', () => {
      const elseConditionData = {
        ...mockData,
        conditions: [
          ...mockData.conditions,
          { id: '3', name: 'Others', isElse: true }
        ],
        outputPorts: ['output1', 'output2', 'output3']
      };
      renderSplitNode({ data: elseConditionData });
      expect(screen.getByText('Others')).toBeInTheDocument();
      expect(screen.getByText('(else)')).toBeInTheDocument();
    });
  });
});