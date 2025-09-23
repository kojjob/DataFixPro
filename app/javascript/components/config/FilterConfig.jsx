import React, { useState } from 'react';

const FilterConfig = ({ node, onChange }) => {
  const [newCondition, setNewCondition] = useState({ field: '', operator: '=', value: '' });

  const handleChange = (field, value) => {
    onChange(node.id, {
      ...node.data,
      [field]: value
    });
  };

  const addCondition = () => {
    if (newCondition.field && newCondition.value) {
      const conditions = node.data.conditions || [];
      handleChange('conditions', [...conditions, { ...newCondition }]);
      setNewCondition({ field: '', operator: '=', value: '' });
    }
  };

  const removeCondition = (index) => {
    const conditions = node.data.conditions || [];
    handleChange('conditions', conditions.filter((_, i) => i !== index));
  };

  const operators = ['=', '!=', '>', '<', '>=', '<=', 'contains', 'starts with', 'ends with', 'in', 'not in', 'is null', 'is not null'];

  return (
    <div className="p-4 bg-white rounded-lg shadow-lg">
      <h3 className="text-lg font-semibold mb-4">Filter Configuration</h3>

      <div className="space-y-4">
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">
            Filter Name
          </label>
          <input
            type="text"
            value={node.data.label || ''}
            onChange={(e) => handleChange('label', e.target.value)}
            className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-yellow-500"
            placeholder="Enter filter name"
          />
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">
            Filter Logic
          </label>
          <select
            value={node.data.logic || 'AND'}
            onChange={(e) => handleChange('logic', e.target.value)}
            className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-yellow-500"
          >
            <option value="AND">All conditions must match (AND)</option>
            <option value="OR">Any condition can match (OR)</option>
            <option value="CUSTOM">Custom logic</option>
          </select>
        </div>

        {node.data.logic === 'CUSTOM' && (
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Custom Logic Expression
            </label>
            <input
              type="text"
              value={node.data.customLogic || ''}
              onChange={(e) => handleChange('customLogic', e.target.value)}
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-yellow-500 font-mono"
              placeholder="e.g., (1 AND 2) OR (3 AND 4)"
            />
            <p className="text-xs text-gray-500 mt-1">
              Use condition numbers with AND, OR, and parentheses
            </p>
          </div>
        )}

        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">
            Filter Conditions
          </label>

          <div className="space-y-2 mb-3">
            {(node.data.conditions || []).map((condition, index) => (
              <div key={index} className="flex items-center gap-2 bg-gray-50 p-2 rounded">
                <span className="text-xs text-gray-500 font-bold">{index + 1}</span>
                <span className="text-sm">{condition.field}</span>
                <span className="text-sm font-medium text-yellow-600">{condition.operator}</span>
                <span className="text-sm font-mono">{condition.value}</span>
                <button
                  onClick={() => removeCondition(index)}
                  className="ml-auto text-red-600 hover:text-red-800"
                >
                  ✕
                </button>
              </div>
            ))}
          </div>

          <div className="space-y-2">
            <div className="flex gap-2">
              <input
                type="text"
                value={newCondition.field}
                onChange={(e) => setNewCondition({ ...newCondition, field: e.target.value })}
                className="flex-1 px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-yellow-500"
                placeholder="Field name"
              />
              <select
                value={newCondition.operator}
                onChange={(e) => setNewCondition({ ...newCondition, operator: e.target.value })}
                className="px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-yellow-500"
              >
                {operators.map(op => (
                  <option key={op} value={op}>{op}</option>
                ))}
              </select>
              <input
                type="text"
                value={newCondition.value}
                onChange={(e) => setNewCondition({ ...newCondition, value: e.target.value })}
                className="flex-1 px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-yellow-500"
                placeholder="Value"
                disabled={newCondition.operator === 'is null' || newCondition.operator === 'is not null'}
              />
              <button
                onClick={addCondition}
                className="px-4 py-2 bg-yellow-600 text-white rounded-md hover:bg-yellow-700"
              >
                Add
              </button>
            </div>
          </div>
        </div>

        <div className="flex items-center">
          <input
            type="checkbox"
            id={`case-sensitive-${node.id}`}
            checked={node.data.caseSensitive || false}
            onChange={(e) => handleChange('caseSensitive', e.target.checked)}
            className="mr-2"
          />
          <label htmlFor={`case-sensitive-${node.id}`} className="text-sm text-gray-700">
            Case sensitive matching
          </label>
        </div>

        <div className="flex items-center">
          <input
            type="checkbox"
            id={`inverse-${node.id}`}
            checked={node.data.inverseFilter || false}
            onChange={(e) => handleChange('inverseFilter', e.target.checked)}
            className="mr-2"
          />
          <label htmlFor={`inverse-${node.id}`} className="text-sm text-gray-700">
            Inverse filter (exclude matching rows)
          </label>
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">
            Description
          </label>
          <textarea
            value={node.data.description || ''}
            onChange={(e) => handleChange('description', e.target.value)}
            className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-yellow-500 h-16"
            placeholder="Describe what this filter does..."
          />
        </div>
      </div>
    </div>
  );
};

export default FilterConfig;