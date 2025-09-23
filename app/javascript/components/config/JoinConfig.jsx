import React, { useState, useEffect, useCallback } from 'react';

const JoinConfig = ({ nodeId, data, onChange, onClose }) => {
  const [localData, setLocalData] = useState(data);
  const [validation, setValidation] = useState({ isValid: true, errors: [] });

  // Join type descriptions
  const joinTypeDescriptions = {
    inner: 'Returns all records when there is a match in both tables',
    left: 'Returns all records from the left table and matched records from the right',
    right: 'Returns all records from the right table and matched records from the left',
    full: 'Returns all records when there is a match in either table'
  };

  // Available operators for join conditions
  const operators = ['=', '!=', '<', '>', '<=', '>='];

  // Validate configuration
  useEffect(() => {
    const errors = [];

    // Check if both tables are selected
    if (!localData.leftTable || !localData.rightTable) {
      errors.push('Please select both tables');
    }

    // Check if join conditions are complete
    const hasIncompleteConditions = localData.joinConditions.some(
      condition => !condition.leftField || !condition.rightField
    );
    if (hasIncompleteConditions) {
      errors.push('Please complete all join conditions');
    }

    // Check if fields are selected
    const noFieldsSelected = (!localData.selectedFields?.left?.length &&
                             !localData.selectedFields?.right?.length);
    if (noFieldsSelected) {
      errors.push('No fields selected');
    }

    setValidation({
      isValid: errors.length === 0,
      errors
    });
  }, [localData]);

  // Generate unique ID for new conditions
  const generateId = () => Date.now().toString();

  // Update local data and trigger onChange
  const updateData = useCallback((updates) => {
    const newData = { ...localData, ...updates };
    setLocalData(newData);
    onChange(nodeId, newData);
  }, [localData, nodeId, onChange]);

  // Handle join type change
  const handleJoinTypeChange = (e) => {
    updateData({ joinType: e.target.value });
  };

  // Handle table name changes
  const handleTableChange = (side, value) => {
    if (side === 'left') {
      updateData({ leftTable: value });
    } else {
      updateData({ rightTable: value });
    }
  };

  // Handle join condition changes
  const handleConditionChange = (index, field, value) => {
    const newConditions = [...localData.joinConditions];
    newConditions[index] = { ...newConditions[index], [field]: value };
    updateData({ joinConditions: newConditions });
  };

  // Add new join condition
  const addCondition = () => {
    const newCondition = {
      id: generateId(),
      leftField: '',
      operator: '=',
      rightField: ''
    };
    updateData({ joinConditions: [...localData.joinConditions, newCondition] });
  };

  // Remove join condition
  const removeCondition = (index) => {
    const newConditions = localData.joinConditions.filter((_, i) => i !== index);
    updateData({ joinConditions: newConditions });
  };

  // Handle field selection
  const handleFieldToggle = (side, field) => {
    const currentFields = localData.selectedFields?.[side] || [];
    let newFields;

    if (currentFields.includes(field)) {
      newFields = currentFields.filter(f => f !== field);
    } else {
      newFields = [...currentFields, field];
    }

    updateData({
      selectedFields: {
        ...localData.selectedFields,
        [side]: newFields
      }
    });
  };

  // Handle select all for a table
  const handleSelectAll = (side) => {
    const currentFields = localData.selectedFields?.[side] || [];
    const isAllSelected = currentFields.includes('*');

    updateData({
      selectedFields: {
        ...localData.selectedFields,
        [side]: isAllSelected ? [] : ['*']
      }
    });
  };

  // Generate SQL preview
  const generateSQL = () => {
    const { joinType, leftTable, rightTable, joinConditions, selectedFields } = localData;

    // Build SELECT clause
    const leftFields = selectedFields?.left?.length
      ? (selectedFields.left.includes('*') ? `${leftTable}.*` : selectedFields.left.join(', '))
      : '';
    const rightFields = selectedFields?.right?.length
      ? (selectedFields.right.includes('*') ? `${rightTable}.*` : selectedFields.right.join(', '))
      : '';

    const allFields = [leftFields, rightFields].filter(f => f).join(', ') || '*';

    // Build JOIN clause
    const joinTypeSQL = joinType.toUpperCase();
    const joinClause = joinType === 'full' ? 'FULL OUTER JOIN' : `${joinTypeSQL} JOIN`;

    // Build ON clause
    const conditions = joinConditions
      .filter(c => c.leftField && c.rightField)
      .map(c => `${leftTable}.${c.leftField} ${c.operator} ${rightTable}.${c.rightField}`)
      .join(' AND ');

    return `SELECT ${allFields}\nFROM ${leftTable}\n${joinClause} ${rightTable}\nON ${conditions}`;
  };

  // Copy SQL to clipboard
  const copySQLToClipboard = () => {
    navigator.clipboard.writeText(generateSQL());
  };

  // Handle apply button
  const handleApply = () => {
    onChange(nodeId, localData);
    onClose();
  };

  // Handle escape key
  useEffect(() => {
    const handleEscape = (e) => {
      if (e.key === 'Escape') {
        onClose();
      }
    };

    document.addEventListener('keydown', handleEscape);
    return () => document.removeEventListener('keydown', handleEscape);
  }, [onClose]);

  // Get available fields (mock data for now)
  const availableFields = localData.availableFields || {
    left: ['users.id', 'users.name', 'users.email'],
    right: ['orders.id', 'orders.user_id', 'orders.total']
  };

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
      <div className="bg-white rounded-lg shadow-xl w-full max-w-4xl max-h-[90vh] overflow-hidden">
        {/* Header */}
        <div className="bg-gradient-to-r from-indigo-500 to-blue-600 text-white p-4 flex justify-between items-center">
          <h2 className="text-xl font-semibold">Join Configuration</h2>
          <button
            onClick={onClose}
            aria-label="close"
            className="text-white hover:bg-white hover:bg-opacity-20 rounded p-1"
          >
            ✕
          </button>
        </div>

        {/* Content */}
        <div className="p-6 overflow-y-auto max-h-[calc(90vh-120px)]">
          {/* Validation Errors */}
          {validation.errors.length > 0 && (
            <div className="mb-4 p-3 bg-red-50 border border-red-200 rounded">
              {validation.errors.map((error, index) => (
                <p key={index} className="text-red-600 text-sm">{error}</p>
              ))}
            </div>
          )}

          {/* Join Type Section */}
          <div className="mb-6">
            <h3 className="text-lg font-semibold mb-3">Join Type</h3>
            <div className="flex items-center gap-4">
              <label htmlFor="joinType" className="font-medium">Join Type</label>
              <select
                id="joinType"
                value={localData.joinType}
                onChange={handleJoinTypeChange}
                className="px-3 py-2 border rounded focus:outline-none focus:ring-2 focus:ring-indigo-500"
              >
                <option value="inner">INNER JOIN</option>
                <option value="left">LEFT JOIN</option>
                <option value="right">RIGHT JOIN</option>
                <option value="full">FULL OUTER JOIN</option>
              </select>
            </div>
            <p className="text-sm text-gray-600 mt-2">
              {joinTypeDescriptions[localData.joinType]}
            </p>
          </div>

          {/* Tables Section */}
          <div className="mb-6">
            <h3 className="text-lg font-semibold mb-3">Tables</h3>
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label htmlFor="leftTable" className="block font-medium mb-1">Left Table</label>
                <input
                  id="leftTable"
                  type="text"
                  value={localData.leftTable || ''}
                  onChange={(e) => handleTableChange('left', e.target.value)}
                  onBlur={(e) => handleTableChange('left', e.target.value)}
                  className="w-full px-3 py-2 border rounded focus:outline-none focus:ring-2 focus:ring-indigo-500"
                />
              </div>
              <div>
                <label htmlFor="rightTable" className="block font-medium mb-1">Right Table</label>
                <input
                  id="rightTable"
                  type="text"
                  value={localData.rightTable || ''}
                  onChange={(e) => handleTableChange('right', e.target.value)}
                  onBlur={(e) => handleTableChange('right', e.target.value)}
                  className="w-full px-3 py-2 border rounded focus:outline-none focus:ring-2 focus:ring-indigo-500"
                />
              </div>
            </div>
          </div>

          {/* Join Conditions Section */}
          <div className="mb-6">
            <h3 className="text-lg font-semibold mb-3">Join Conditions</h3>
            {localData.joinConditions.map((condition, index) => (
              <div key={condition.id} className="flex items-center gap-2 mb-2">
                <input
                  type="text"
                  value={condition.leftField}
                  onChange={(e) => handleConditionChange(index, 'leftField', e.target.value)}
                  onBlur={(e) => handleConditionChange(index, 'leftField', e.target.value)}
                  placeholder="Left field"
                  className="flex-1 px-3 py-2 border rounded focus:outline-none focus:ring-2 focus:ring-indigo-500"
                />
                <select
                  value={condition.operator}
                  onChange={(e) => handleConditionChange(index, 'operator', e.target.value)}
                  className="px-3 py-2 border rounded focus:outline-none focus:ring-2 focus:ring-indigo-500"
                >
                  {operators.map(op => (
                    <option key={op} value={op}>{op}</option>
                  ))}
                </select>
                <input
                  type="text"
                  value={condition.rightField}
                  onChange={(e) => handleConditionChange(index, 'rightField', e.target.value)}
                  onBlur={(e) => handleConditionChange(index, 'rightField', e.target.value)}
                  placeholder="Right field"
                  className="flex-1 px-3 py-2 border rounded focus:outline-none focus:ring-2 focus:ring-indigo-500"
                />
                <button
                  onClick={() => removeCondition(index)}
                  disabled={localData.joinConditions.length === 1}
                  aria-label="delete condition"
                  className={`px-3 py-2 rounded ${
                    localData.joinConditions.length === 1
                      ? 'bg-gray-200 text-gray-400 cursor-not-allowed'
                      : 'bg-red-500 text-white hover:bg-red-600'
                  }`}
                >
                  ✕
                </button>
              </div>
            ))}
            <button
              onClick={addCondition}
              className="mt-2 px-4 py-2 bg-indigo-500 text-white rounded hover:bg-indigo-600"
            >
              Add Condition
            </button>
          </div>

          {/* Field Selection Section */}
          <div className="mb-6">
            <h3 className="text-lg font-semibold mb-3">Select Fields</h3>
            <div className="grid grid-cols-2 gap-4">
              {/* Left Table Fields */}
              <div data-testid="left-fields" className="border rounded p-3">
                <h4 className="font-medium mb-2">{localData.leftTable || 'Left Table'}</h4>
                <div className="mb-2">
                  <label className="flex items-center">
                    <input
                      type="checkbox"
                      checked={localData.selectedFields?.left?.includes('*')}
                      onChange={() => handleSelectAll('left')}
                      aria-label={`Select all from ${localData.leftTable || 'users'}`}
                      className="mr-2"
                    />
                    <span className="font-medium">Select All</span>
                  </label>
                </div>
                {availableFields.left.map(field => (
                  <label key={field} className="flex items-center mb-1">
                    <input
                      type="checkbox"
                      checked={localData.selectedFields?.left?.includes(field) ||
                              localData.selectedFields?.left?.includes('*')}
                      onChange={() => handleFieldToggle('left', field)}
                      disabled={localData.selectedFields?.left?.includes('*')}
                      aria-label={field}
                      className="mr-2"
                    />
                    <span className="text-sm">{field}</span>
                  </label>
                ))}
              </div>

              {/* Right Table Fields */}
              <div data-testid="right-fields" className="border rounded p-3">
                <h4 className="font-medium mb-2">{localData.rightTable || 'Right Table'}</h4>
                <div className="mb-2">
                  <label className="flex items-center">
                    <input
                      type="checkbox"
                      checked={localData.selectedFields?.right?.includes('*')}
                      onChange={() => handleSelectAll('right')}
                      aria-label={`Select all from ${localData.rightTable || 'orders'}`}
                      className="mr-2"
                    />
                    <span className="font-medium">Select All</span>
                  </label>
                </div>
                {availableFields.right.map(field => (
                  <label key={field} className="flex items-center mb-1">
                    <input
                      type="checkbox"
                      checked={localData.selectedFields?.right?.includes(field) ||
                              localData.selectedFields?.right?.includes('*')}
                      onChange={() => handleFieldToggle('right', field)}
                      disabled={localData.selectedFields?.right?.includes('*')}
                      aria-label={field}
                      className="mr-2"
                    />
                    <span className="text-sm">{field}</span>
                  </label>
                ))}
              </div>
            </div>
          </div>

          {/* SQL Preview Section */}
          <div className="mb-6">
            <h3 className="text-lg font-semibold mb-3">SQL Preview</h3>
            <div className="relative">
              <pre
                data-testid="sql-preview"
                className="p-4 bg-gray-100 rounded font-mono text-sm overflow-x-auto"
              >
                {generateSQL()}
              </pre>
              <button
                onClick={copySQLToClipboard}
                className="absolute top-2 right-2 px-3 py-1 bg-gray-600 text-white text-sm rounded hover:bg-gray-700"
              >
                Copy SQL
              </button>
            </div>
          </div>
        </div>

        {/* Footer */}
        <div className="border-t p-4 flex justify-end gap-3">
          <button
            onClick={onClose}
            className="px-4 py-2 border border-gray-300 rounded hover:bg-gray-50"
          >
            Cancel
          </button>
          <button
            onClick={handleApply}
            disabled={!validation.isValid}
            className={`px-4 py-2 rounded text-white ${
              validation.isValid
                ? 'bg-indigo-500 hover:bg-indigo-600'
                : 'bg-gray-400 cursor-not-allowed'
            }`}
          >
            Apply
          </button>
        </div>
      </div>
    </div>
  );
};

export default JoinConfig;