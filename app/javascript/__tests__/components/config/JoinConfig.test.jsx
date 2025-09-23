import React from 'react';
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import JoinConfig from '../../../components/config/JoinConfig';

describe('JoinConfig Component', () => {
  const mockData = {
    joinType: 'inner',
    leftTable: 'users',
    rightTable: 'orders',
    joinConditions: [
      {
        id: '1',
        leftField: 'id',
        operator: '=',
        rightField: 'user_id'
      }
    ],
    selectedFields: {
      left: ['users.id', 'users.name', 'users.email'],
      right: ['orders.id', 'orders.total']
    }
  };

  const mockOnChange = jest.fn();
  const mockOnClose = jest.fn();

  const defaultProps = {
    nodeId: 'join-1',
    data: mockData,
    onChange: mockOnChange,
    onClose: mockOnClose
  };

  beforeEach(() => {
    jest.clearAllMocks();
  });

  const renderJoinConfig = (props = {}) => {
    return render(<JoinConfig {...defaultProps} {...props} />);
  };

  describe('Rendering', () => {
    it('should render the configuration panel with title', () => {
      renderJoinConfig();
      expect(screen.getByText('Join Configuration')).toBeInTheDocument();
    });

    it('should display close button', () => {
      renderJoinConfig();
      expect(screen.getByRole('button', { name: /close/i })).toBeInTheDocument();
    });

    it('should render all main sections', () => {
      renderJoinConfig();
      // Use getAllByText since "Join Type" appears as both a heading and a label
      const joinTypeElements = screen.getAllByText('Join Type');
      expect(joinTypeElements.length).toBeGreaterThan(0);
      expect(screen.getByText('Tables')).toBeInTheDocument();
      expect(screen.getByText('Join Conditions')).toBeInTheDocument();
      expect(screen.getByText('Select Fields')).toBeInTheDocument();
    });
  });

  describe('Join Type Selection', () => {
    it('should display all join type options', () => {
      renderJoinConfig();
      const joinTypeSelect = screen.getByLabelText('Join Type');
      expect(joinTypeSelect).toBeInTheDocument();

      fireEvent.click(joinTypeSelect);
      expect(screen.getByText('INNER JOIN')).toBeInTheDocument();
      expect(screen.getByText('LEFT JOIN')).toBeInTheDocument();
      expect(screen.getByText('RIGHT JOIN')).toBeInTheDocument();
      expect(screen.getByText('FULL OUTER JOIN')).toBeInTheDocument();
    });

    it('should select current join type', () => {
      renderJoinConfig();
      const joinTypeSelect = screen.getByLabelText('Join Type');
      expect(joinTypeSelect.value).toBe('inner');
    });

    it('should update join type on selection', async () => {
      renderJoinConfig();
      const joinTypeSelect = screen.getByLabelText('Join Type');

      fireEvent.change(joinTypeSelect, { target: { value: 'left' } });

      await waitFor(() => {
        expect(mockOnChange).toHaveBeenCalledWith('join-1', {
          ...mockData,
          joinType: 'left'
        });
      });
    });

    it('should show join type description', () => {
      renderJoinConfig();
      expect(screen.getByText(/Returns all records when there is a match/)).toBeInTheDocument();
    });
  });

  describe('Table Selection', () => {
    it('should display left and right table inputs', () => {
      renderJoinConfig();
      expect(screen.getByLabelText('Left Table')).toBeInTheDocument();
      expect(screen.getByLabelText('Right Table')).toBeInTheDocument();
    });

    it('should show current table values', () => {
      renderJoinConfig();
      expect(screen.getByLabelText('Left Table')).toHaveValue('users');
      expect(screen.getByLabelText('Right Table')).toHaveValue('orders');
    });

    it('should update left table on change', async () => {
      renderJoinConfig();
      const leftTableInput = screen.getByLabelText('Left Table');

      await userEvent.clear(leftTableInput);
      await userEvent.type(leftTableInput, 'customers');

      fireEvent.blur(leftTableInput);

      await waitFor(() => {
        expect(mockOnChange).toHaveBeenCalledWith('join-1',
          expect.objectContaining({
            leftTable: 'customers'
          })
        );
      });
    });

    it('should update right table on change', async () => {
      renderJoinConfig();
      const rightTableInput = screen.getByLabelText('Right Table');

      await userEvent.clear(rightTableInput);
      await userEvent.type(rightTableInput, 'products');

      fireEvent.blur(rightTableInput);

      await waitFor(() => {
        expect(mockOnChange).toHaveBeenCalledWith('join-1',
          expect.objectContaining({
            rightTable: 'products'
          })
        );
      });
    });
  });

  describe('Join Conditions', () => {
    it('should display existing join conditions', () => {
      renderJoinConfig();
      expect(screen.getByDisplayValue('id')).toBeInTheDocument();
      expect(screen.getByDisplayValue('=')).toBeInTheDocument();
      expect(screen.getByDisplayValue('user_id')).toBeInTheDocument();
    });

    it('should show add condition button', () => {
      renderJoinConfig();
      expect(screen.getByRole('button', { name: /add condition/i })).toBeInTheDocument();
    });

    it('should add new condition when button clicked', async () => {
      renderJoinConfig();
      const addButton = screen.getByRole('button', { name: /add condition/i });

      fireEvent.click(addButton);

      await waitFor(() => {
        expect(mockOnChange).toHaveBeenCalledWith('join-1',
          expect.objectContaining({
            joinConditions: expect.arrayContaining([
              expect.objectContaining({ id: '1' }),
              expect.objectContaining({ leftField: '', operator: '=', rightField: '' })
            ])
          })
        );
      });
    });

    it('should update condition fields', async () => {
      renderJoinConfig();
      const leftFieldInput = screen.getByDisplayValue('id');

      await userEvent.clear(leftFieldInput);
      await userEvent.type(leftFieldInput, 'email');

      fireEvent.blur(leftFieldInput);

      await waitFor(() => {
        expect(mockOnChange).toHaveBeenCalledWith('join-1',
          expect.objectContaining({
            joinConditions: [
              expect.objectContaining({ leftField: 'email' })
            ]
          })
        );
      });
    });

    it('should change operator selection', async () => {
      renderJoinConfig();
      const operatorSelect = screen.getByDisplayValue('=');

      fireEvent.change(operatorSelect, { target: { value: '!=' } });

      await waitFor(() => {
        expect(mockOnChange).toHaveBeenCalledWith('join-1',
          expect.objectContaining({
            joinConditions: [
              expect.objectContaining({ operator: '!=' })
            ]
          })
        );
      });
    });

    it('should remove condition when delete button clicked', async () => {
      const multiConditionData = {
        ...mockData,
        joinConditions: [
          { id: '1', leftField: 'id', operator: '=', rightField: 'user_id' },
          { id: '2', leftField: 'status', operator: '=', rightField: 'status' }
        ]
      };

      renderJoinConfig({ data: multiConditionData });
      const deleteButtons = screen.getAllByRole('button', { name: /delete condition/i });

      fireEvent.click(deleteButtons[0]);

      await waitFor(() => {
        expect(mockOnChange).toHaveBeenCalledWith('join-1',
          expect.objectContaining({
            joinConditions: [
              expect.objectContaining({ id: '2' })
            ]
          })
        );
      });
    });

    it('should not allow removing last condition', () => {
      renderJoinConfig();
      const deleteButton = screen.queryByRole('button', { name: /delete condition/i });
      expect(deleteButton).toBeDisabled();
    });
  });

  describe('Field Selection', () => {
    it('should display field selection checkboxes', () => {
      renderJoinConfig();
      expect(screen.getByLabelText('users.id')).toBeInTheDocument();
      expect(screen.getByLabelText('users.name')).toBeInTheDocument();
      expect(screen.getByLabelText('orders.total')).toBeInTheDocument();
    });

    it('should show select all checkbox for each table', () => {
      renderJoinConfig();
      expect(screen.getByLabelText('Select all from users')).toBeInTheDocument();
      expect(screen.getByLabelText('Select all from orders')).toBeInTheDocument();
    });

    it('should check selected fields', () => {
      renderJoinConfig();
      expect(screen.getByLabelText('users.id')).toBeChecked();
      expect(screen.getByLabelText('users.name')).toBeChecked();
      expect(screen.getByLabelText('orders.id')).toBeChecked();
    });

    it('should toggle field selection', async () => {
      renderJoinConfig();
      const emailCheckbox = screen.getByLabelText('users.email');

      fireEvent.click(emailCheckbox);

      await waitFor(() => {
        expect(mockOnChange).toHaveBeenCalledWith('join-1',
          expect.objectContaining({
            selectedFields: expect.objectContaining({
              left: expect.not.arrayContaining(['users.email'])
            })
          })
        );
      });
    });

    it('should select all fields from a table', async () => {
      renderJoinConfig();
      const selectAllCheckbox = screen.getByLabelText('Select all from users');

      fireEvent.click(selectAllCheckbox);

      await waitFor(() => {
        expect(mockOnChange).toHaveBeenCalledWith('join-1',
          expect.objectContaining({
            selectedFields: expect.objectContaining({
              left: ['*']
            })
          })
        );
      });
    });
  });

  describe('SQL Preview', () => {
    it('should display SQL preview section', () => {
      renderJoinConfig();
      expect(screen.getByText('SQL Preview')).toBeInTheDocument();
    });

    it('should show generated SQL query', () => {
      renderJoinConfig();
      const sqlPreview = screen.getByTestId('sql-preview');
      expect(sqlPreview).toHaveTextContent('SELECT');
      expect(sqlPreview).toHaveTextContent('users.id, users.name, users.email');
      expect(sqlPreview).toHaveTextContent('orders.id, orders.total');
      expect(sqlPreview).toHaveTextContent('FROM users');
      expect(sqlPreview).toHaveTextContent('INNER JOIN orders');
      expect(sqlPreview).toHaveTextContent('ON users.id = orders.user_id');
    });

    it('should update SQL preview when configuration changes', async () => {
      renderJoinConfig();
      const joinTypeSelect = screen.getByLabelText('Join Type');

      fireEvent.change(joinTypeSelect, { target: { value: 'left' } });

      await waitFor(() => {
        const sqlPreview = screen.getByTestId('sql-preview');
        expect(sqlPreview).toHaveTextContent('LEFT JOIN');
      });
    });

    it('should show copy SQL button', () => {
      renderJoinConfig();
      expect(screen.getByRole('button', { name: /copy sql/i })).toBeInTheDocument();
    });
  });

  describe('Validation', () => {
    it('should show error when tables are not selected', async () => {
      const invalidData = {
        ...mockData,
        leftTable: '',
        rightTable: ''
      };

      renderJoinConfig({ data: invalidData });
      expect(screen.getByText('Please select both tables')).toBeInTheDocument();
    });

    it('should show error when join conditions are incomplete', () => {
      const invalidData = {
        ...mockData,
        joinConditions: [
          { id: '1', leftField: '', operator: '=', rightField: '' }
        ]
      };

      renderJoinConfig({ data: invalidData });
      expect(screen.getByText('Please complete all join conditions')).toBeInTheDocument();
    });

    it('should show warning when no fields are selected', () => {
      const noFieldsData = {
        ...mockData,
        selectedFields: { left: [], right: [] }
      };

      renderJoinConfig({ data: noFieldsData });
      expect(screen.getByText('No fields selected')).toBeInTheDocument();
    });

    it('should disable apply button when validation fails', () => {
      const invalidData = {
        ...mockData,
        leftTable: ''
      };

      renderJoinConfig({ data: invalidData });
      expect(screen.getByRole('button', { name: /apply/i })).toBeDisabled();
    });
  });

  describe('Actions', () => {
    it('should call onClose when close button clicked', () => {
      renderJoinConfig();
      const closeButton = screen.getByRole('button', { name: /close/i });

      fireEvent.click(closeButton);
      expect(mockOnClose).toHaveBeenCalled();
    });

    it('should call onClose when cancel button clicked', () => {
      renderJoinConfig();
      const cancelButton = screen.getByRole('button', { name: /cancel/i });

      fireEvent.click(cancelButton);
      expect(mockOnClose).toHaveBeenCalled();
    });

    it('should apply changes and close when apply button clicked', () => {
      renderJoinConfig();
      const applyButton = screen.getByRole('button', { name: /apply/i });

      fireEvent.click(applyButton);

      expect(mockOnChange).toHaveBeenCalledWith('join-1', mockData);
      expect(mockOnClose).toHaveBeenCalled();
    });

    it('should handle escape key to close', () => {
      renderJoinConfig();

      fireEvent.keyDown(document, { key: 'Escape', code: 'Escape' });
      expect(mockOnClose).toHaveBeenCalled();
    });
  });

  describe('Available Fields', () => {
    it('should load available fields from connected nodes', async () => {
      const connectedNodesData = {
        ...mockData,
        availableFields: {
          left: ['users.id', 'users.name', 'users.email', 'users.created_at'],
          right: ['orders.id', 'orders.user_id', 'orders.total', 'orders.status']
        }
      };

      renderJoinConfig({ data: connectedNodesData });

      await waitFor(() => {
        expect(screen.getByLabelText('users.created_at')).toBeInTheDocument();
        expect(screen.getByLabelText('orders.status')).toBeInTheDocument();
      });
    });

    it('should group fields by table', () => {
      renderJoinConfig();

      const leftFieldsSection = screen.getByTestId('left-fields');
      const rightFieldsSection = screen.getByTestId('right-fields');

      expect(leftFieldsSection).toHaveTextContent('users');
      expect(rightFieldsSection).toHaveTextContent('orders');
    });
  });
});