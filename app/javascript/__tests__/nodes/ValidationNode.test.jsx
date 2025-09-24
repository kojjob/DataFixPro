import React from 'react';
import { render, screen } from '@testing-library/react';
import { ReactFlowProvider } from 'reactflow';
import ValidationNode from '../../components/nodes/ValidationNode';

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

describe('ValidationNode Component', () => {
  const mockData = {
    label: 'Validate Data',
    validationRules: [
      {
        id: '1',
        field: 'email',
        type: 'format',
        rule: 'email',
        message: 'Invalid email format'
      },
      {
        id: '2',
        field: 'age',
        type: 'range',
        min: 18,
        max: 100,
        message: 'Age must be between 18 and 100'
      },
      {
        id: '3',
        field: 'status',
        type: 'required',
        message: 'Status is required'
      }
    ],
    validationMode: 'strict', // 'strict' or 'tolerant'
    statistics: {
      totalRecords: 1000,
      validRecords: 950,
      invalidRecords: 50,
      errors: {
        email: 30,
        age: 15,
        status: 5
      }
    }
  };

  const defaultProps = {
    id: 'validation-1',
    data: mockData,
    selected: false
  };

  const renderValidationNode = (props = {}) => {
    return render(
      <ReactFlowProvider>
        <ValidationNode {...defaultProps} {...props} />
      </ReactFlowProvider>
    );
  };

  describe('Rendering', () => {
    it('should render the validation node with correct label', () => {
      renderValidationNode();
      expect(screen.getByText('Validate Data')).toBeInTheDocument();
    });

    it('should display the validation icon', () => {
      renderValidationNode();
      expect(screen.getByText('✅')).toBeInTheDocument();
    });

    it('should apply selected styles when selected', () => {
      const { container } = renderValidationNode({ selected: true });
      const nodeElement = container.firstChild;
      expect(nodeElement).toHaveClass('ring-2');
      expect(nodeElement).toHaveClass('ring-green-500');
    });

    it('should render processing indicator when processing', () => {
      const processingData = {
        ...mockData,
        isProcessing: true
      };
      renderValidationNode({ data: processingData });
      expect(screen.getByTestId('processing-spinner')).toBeInTheDocument();
    });
  });

  describe('Handles', () => {
    it('should render input handle', () => {
      renderValidationNode();
      expect(screen.getByTestId('handle-target-input')).toBeInTheDocument();
    });

    it('should render valid output handle', () => {
      renderValidationNode();
      expect(screen.getByTestId('handle-source-valid')).toBeInTheDocument();
    });

    it('should render invalid output handle', () => {
      renderValidationNode();
      expect(screen.getByTestId('handle-source-invalid')).toBeInTheDocument();
    });

    it('should position handles correctly', () => {
      renderValidationNode();
      expect(screen.getByTestId('handle-target-input')).toHaveAttribute('data-position', 'left');
      expect(screen.getByTestId('handle-source-valid')).toHaveAttribute('data-position', 'right');
      expect(screen.getByTestId('handle-source-invalid')).toHaveAttribute('data-position', 'right');
    });
  });

  describe('Validation Rules Display', () => {
    it('should display validation rules', () => {
      renderValidationNode();
      expect(screen.getByText('email: format (email)')).toBeInTheDocument();
      expect(screen.getByText('age: range (18-100)')).toBeInTheDocument();
      expect(screen.getByText('status: required')).toBeInTheDocument();
    });

    it('should display rule count summary', () => {
      renderValidationNode();
      expect(screen.getByText('3 validation rules')).toBeInTheDocument();
    });

    it('should handle empty rules gracefully', () => {
      const noRulesData = {
        ...mockData,
        validationRules: []
      };
      renderValidationNode({ data: noRulesData });
      expect(screen.getByText('No validation rules defined')).toBeInTheDocument();
    });

    it('should display custom validation rules', () => {
      const customRuleData = {
        ...mockData,
        validationRules: [
          {
            id: '1',
            field: 'custom_field',
            type: 'custom',
            expression: 'value.length > 5',
            message: 'Custom validation failed'
          }
        ]
      };
      renderValidationNode({ data: customRuleData });
      expect(screen.getByText(/custom_field: custom/)).toBeInTheDocument();
    });
  });

  describe('Validation Modes', () => {
    it('should display strict mode badge', () => {
      renderValidationNode();
      expect(screen.getByText('STRICT MODE')).toBeInTheDocument();
      expect(screen.getByText('STRICT MODE')).toHaveClass('bg-red-100');
    });

    it('should display tolerant mode badge', () => {
      const tolerantData = {
        ...mockData,
        validationMode: 'tolerant'
      };
      renderValidationNode({ data: tolerantData });
      expect(screen.getByText('TOLERANT MODE')).toBeInTheDocument();
      expect(screen.getByText('TOLERANT MODE')).toHaveClass('bg-yellow-100');
    });

    it('should explain validation mode behavior', () => {
      renderValidationNode();
      expect(screen.getByText('Stops on first error')).toBeInTheDocument();
    });
  });

  describe('Statistics Display', () => {
    it('should display validation statistics', () => {
      renderValidationNode();
      expect(screen.getByText('950/1000 valid')).toBeInTheDocument();
    });

    it('should calculate and display success rate', () => {
      renderValidationNode();
      expect(screen.getByText('(95.0%)')).toBeInTheDocument();
    });

    it('should display error breakdown', () => {
      renderValidationNode();
      expect(screen.getByText('Errors:')).toBeInTheDocument();
      expect(screen.getByText('email: 30')).toBeInTheDocument();
      expect(screen.getByText('age: 15')).toBeInTheDocument();
      expect(screen.getByText('status: 5')).toBeInTheDocument();
    });

    it('should handle missing statistics gracefully', () => {
      const noStatsData = {
        ...mockData,
        statistics: undefined
      };
      renderValidationNode({ data: noStatsData });
      expect(screen.getByText('Validate Data')).toBeInTheDocument();
      // Should not crash
    });

    it('should show warning when validation errors are high', () => {
      const highErrorData = {
        ...mockData,
        statistics: {
          totalRecords: 1000,
          validRecords: 200,
          invalidRecords: 800
        }
      };
      renderValidationNode({ data: highErrorData });
      expect(screen.getByTestId('high-error-warning')).toBeInTheDocument();
    });
  });

  describe('Validation Rule Types', () => {
    it('should display format validation rules', () => {
      const formatRules = {
        ...mockData,
        validationRules: [
          { id: '1', field: 'email', type: 'format', rule: 'email' },
          { id: '2', field: 'phone', type: 'format', rule: 'phone' },
          { id: '3', field: 'date', type: 'format', rule: 'date' }
        ]
      };
      renderValidationNode({ data: formatRules });
      expect(screen.getByText('email: format (email)')).toBeInTheDocument();
      expect(screen.getByText('phone: format (phone)')).toBeInTheDocument();
      expect(screen.getByText('date: format (date)')).toBeInTheDocument();
    });

    it('should display range validation rules', () => {
      const rangeRules = {
        ...mockData,
        validationRules: [
          { id: '1', field: 'price', type: 'range', min: 0, max: 1000 },
          { id: '2', field: 'quantity', type: 'range', min: 1, max: 100 }
        ]
      };
      renderValidationNode({ data: rangeRules });
      expect(screen.getByText('price: range (0-1000)')).toBeInTheDocument();
      expect(screen.getByText('quantity: range (1-100)')).toBeInTheDocument();
    });

    it('should display enum validation rules', () => {
      const enumRules = {
        ...mockData,
        validationRules: [
          {
            id: '1',
            field: 'status',
            type: 'enum',
            values: ['active', 'inactive', 'pending']
          }
        ]
      };
      renderValidationNode({ data: enumRules });
      expect(screen.getByText('status: enum (3 values)')).toBeInTheDocument();
    });

    it('should display pattern validation rules', () => {
      const patternRules = {
        ...mockData,
        validationRules: [
          {
            id: '1',
            field: 'code',
            type: 'pattern',
            pattern: '^[A-Z]{3}-\\d{4}$'
          }
        ]
      };
      renderValidationNode({ data: patternRules });
      expect(screen.getByText('code: pattern')).toBeInTheDocument();
    });
  });

  describe('Visual States', () => {
    it('should have hover effects on the node', () => {
      const { container } = renderValidationNode();
      const nodeElement = container.firstChild;
      expect(nodeElement).toHaveClass('hover:shadow-lg');
    });

    it('should use green gradient for validation node', () => {
      const { container } = renderValidationNode();
      const nodeElement = container.firstChild;
      expect(nodeElement).toHaveClass('bg-gradient-to-br');
      expect(nodeElement).toHaveClass('from-green-50');
      expect(nodeElement).toHaveClass('to-green-100');
    });

    it('should show connected state indicator', () => {
      const connectedData = {
        ...mockData,
        inputConnected: true
      };
      renderValidationNode({ data: connectedData });
      expect(screen.getByTestId('connected-indicator')).toHaveClass('text-green-600');
    });

    it('should show validation status indicator', () => {
      const statusData = {
        ...mockData,
        validationStatus: 'passed'
      };
      renderValidationNode({ data: statusData });
      expect(screen.getByTestId('validation-status')).toHaveClass('text-green-600');
    });

    it('should show failed validation indicator', () => {
      const failedData = {
        ...mockData,
        validationStatus: 'failed'
      };
      renderValidationNode({ data: failedData });
      expect(screen.getByTestId('validation-status')).toHaveClass('text-red-600');
    });
  });

  describe('Advanced Features', () => {
    it('should display composite validation rules', () => {
      const compositeRules = {
        ...mockData,
        validationRules: [
          {
            id: '1',
            field: 'password',
            type: 'composite',
            rules: ['required', 'min:8', 'uppercase', 'lowercase', 'number']
          }
        ]
      };
      renderValidationNode({ data: compositeRules });
      expect(screen.getByText('password: composite (5 rules)')).toBeInTheDocument();
    });

    it('should display conditional validation rules', () => {
      const conditionalRules = {
        ...mockData,
        validationRules: [
          {
            id: '1',
            field: 'discount',
            type: 'conditional',
            condition: 'type === "premium"',
            rule: 'range:10-50'
          }
        ]
      };
      renderValidationNode({ data: conditionalRules });
      expect(screen.getByText(/discount: conditional/)).toBeInTheDocument();
    });

    it('should display schema validation', () => {
      const schemaData = {
        ...mockData,
        validationSchema: 'UserSchema',
        validationRules: []
      };
      renderValidationNode({ data: schemaData });
      expect(screen.getByText('Schema:')).toBeInTheDocument();
      expect(screen.getByText('UserSchema')).toBeInTheDocument();
    });
  });
});