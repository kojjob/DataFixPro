import React, { useState } from 'react';

const AggregateConfig = ({ node, onChange }) => {
  const [newAggregation, setNewAggregation] = useState({ field: '', function: 'sum', alias: '' });
  const [newGroupBy, setNewGroupBy] = useState('');

  const handleChange = (field, value) => {
    onChange(node.id, {
      ...node.data,
      [field]: value
    });
  };

  const addAggregation = () => {
    if (newAggregation.field && newAggregation.function) {
      const aggregations = node.data.aggregations || [];
      handleChange('aggregations', [...aggregations, { ...newAggregation }]);
      setNewAggregation({ field: '', function: 'sum', alias: '' });
    }
  };

  const removeAggregation = (index) => {
    const aggregations = node.data.aggregations || [];
    handleChange('aggregations', aggregations.filter((_, i) => i !== index));
  };

  const addGroupBy = () => {
    if (newGroupBy && !node.data.groupBy?.includes(newGroupBy)) {
      const groupBy = node.data.groupBy || [];
      handleChange('groupBy', [...groupBy, newGroupBy]);
      setNewGroupBy('');
    }
  };

  const removeGroupBy = (field) => {
    const groupBy = node.data.groupBy || [];
    handleChange('groupBy', groupBy.filter(f => f !== field));
  };

  const aggregateFunctions = [
    'sum', 'avg', 'min', 'max', 'count', 'count_distinct',
    'median', 'stddev', 'variance', 'first', 'last',
    'percentile_25', 'percentile_50', 'percentile_75', 'percentile_95'
  ];

  return (
    <div className="p-4 bg-white rounded-lg shadow-lg">
      <h3 className="text-lg font-semibold mb-4">Aggregation Configuration</h3>

      <div className="space-y-4">
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">
            Aggregation Name
          </label>
          <input
            type="text"
            value={node.data.label || ''}
            onChange={(e) => handleChange('label', e.target.value)}
            className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-purple-500"
            placeholder="Enter aggregation name"
          />
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">
            Group By Fields
          </label>

          <div className="flex flex-wrap gap-2 mb-2">
            {(node.data.groupBy || []).map((field, index) => (
              <span key={index} className="inline-flex items-center gap-1 px-3 py-1 bg-purple-100 text-purple-800 rounded-full text-sm">
                {field}
                <button
                  onClick={() => removeGroupBy(field)}
                  className="text-purple-600 hover:text-purple-800 font-bold"
                >
                  ×
                </button>
              </span>
            ))}
          </div>

          <div className="flex gap-2">
            <input
              type="text"
              value={newGroupBy}
              onChange={(e) => setNewGroupBy(e.target.value)}
              onKeyPress={(e) => e.key === 'Enter' && (e.preventDefault(), addGroupBy())}
              className="flex-1 px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-purple-500"
              placeholder="Field name to group by"
            />
            <button
              onClick={addGroupBy}
              className="px-4 py-2 bg-purple-600 text-white rounded-md hover:bg-purple-700"
            >
              Add
            </button>
          </div>
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">
            Aggregations
          </label>

          <div className="space-y-2 mb-3">
            {(node.data.aggregations || []).map((agg, index) => (
              <div key={index} className="flex items-center gap-2 bg-gray-50 p-2 rounded">
                <span className="text-sm font-medium text-purple-600">{agg.function}</span>
                <span className="text-sm">({agg.field})</span>
                {agg.alias && (
                  <>
                    <span className="text-sm text-gray-500">as</span>
                    <span className="text-sm font-medium">{agg.alias}</span>
                  </>
                )}
                <button
                  onClick={() => removeAggregation(index)}
                  className="ml-auto text-red-600 hover:text-red-800"
                >
                  ✕
                </button>
              </div>
            ))}
          </div>

          <div className="space-y-2">
            <div className="flex gap-2">
              <select
                value={newAggregation.function}
                onChange={(e) => setNewAggregation({ ...newAggregation, function: e.target.value })}
                className="px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-purple-500"
              >
                {aggregateFunctions.map(func => (
                  <option key={func} value={func}>{func}</option>
                ))}
              </select>
              <input
                type="text"
                value={newAggregation.field}
                onChange={(e) => setNewAggregation({ ...newAggregation, field: e.target.value })}
                className="flex-1 px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-purple-500"
                placeholder="Field name"
              />
              <input
                type="text"
                value={newAggregation.alias}
                onChange={(e) => setNewAggregation({ ...newAggregation, alias: e.target.value })}
                className="flex-1 px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-purple-500"
                placeholder="Alias (optional)"
              />
              <button
                onClick={addAggregation}
                className="px-4 py-2 bg-purple-600 text-white rounded-md hover:bg-purple-700"
              >
                Add
              </button>
            </div>
          </div>
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">
            Having Clause (Optional)
          </label>
          <input
            type="text"
            value={node.data.havingClause || ''}
            onChange={(e) => handleChange('havingClause', e.target.value)}
            className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-purple-500 font-mono"
            placeholder="e.g., COUNT(*) > 10 AND SUM(amount) > 1000"
          />
          <p className="text-xs text-gray-500 mt-1">
            Filter aggregated results using SQL-like conditions
          </p>
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">
            Sort Order
          </label>
          <div className="flex gap-2">
            <select
              value={node.data.sortField || ''}
              onChange={(e) => handleChange('sortField', e.target.value)}
              className="flex-1 px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-purple-500"
            >
              <option value="">No sorting</option>
              {(node.data.groupBy || []).map(field => (
                <option key={field} value={field}>{field}</option>
              ))}
              {(node.data.aggregations || []).map((agg, index) => (
                <option key={`agg-${index}`} value={agg.alias || `${agg.function}(${agg.field})`}>
                  {agg.alias || `${agg.function}(${agg.field})`}
                </option>
              ))}
            </select>
            <select
              value={node.data.sortOrder || 'ASC'}
              onChange={(e) => handleChange('sortOrder', e.target.value)}
              className="px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-purple-500"
              disabled={!node.data.sortField}
            >
              <option value="ASC">Ascending</option>
              <option value="DESC">Descending</option>
            </select>
          </div>
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">
            Limit Results (Optional)
          </label>
          <input
            type="number"
            value={node.data.limit || ''}
            onChange={(e) => handleChange('limit', e.target.value ? parseInt(e.target.value) : null)}
            className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-purple-500"
            placeholder="e.g., 100"
            min="1"
          />
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">
            Description
          </label>
          <textarea
            value={node.data.description || ''}
            onChange={(e) => handleChange('description', e.target.value)}
            className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-purple-500 h-16"
            placeholder="Describe what this aggregation does..."
          />
        </div>
      </div>
    </div>
  );
};

export default AggregateConfig;