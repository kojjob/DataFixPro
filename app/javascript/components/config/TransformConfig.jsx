import React, { useState } from 'react';

const TransformConfig = ({ node, onChange }) => {
  const [newField, setNewField] = useState({ name: '', expression: '' });

  const handleChange = (field, value) => {
    onChange(node.id, {
      ...node.data,
      [field]: value
    });
  };

  const addTransformation = () => {
    if (newField.name && newField.expression) {
      const transformations = node.data.transformations || [];
      handleChange('transformations', [...transformations, { ...newField }]);
      setNewField({ name: '', expression: '' });
    }
  };

  const removeTransformation = (index) => {
    const transformations = node.data.transformations || [];
    handleChange('transformations', transformations.filter((_, i) => i !== index));
  };

  return (
    <div className="p-4 bg-white rounded-lg shadow-lg">
      <h3 className="text-lg font-semibold mb-4">Transformation Configuration</h3>

      <div className="space-y-4">
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">
            Transformation Name
          </label>
          <input
            type="text"
            value={node.data.label || ''}
            onChange={(e) => handleChange('label', e.target.value)}
            className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-green-500"
            placeholder="Enter transformation name"
          />
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">
            Transformation Type
          </label>
          <select
            value={node.data.transformType || 'custom'}
            onChange={(e) => handleChange('transformType', e.target.value)}
            className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-green-500"
          >
            <option value="custom">Custom Expression</option>
            <option value="rename">Rename Fields</option>
            <option value="cast">Type Casting</option>
            <option value="calculate">Calculated Fields</option>
            <option value="normalize">Data Normalization</option>
            <option value="pivot">Pivot Table</option>
            <option value="unpivot">Unpivot Table</option>
          </select>
        </div>

        {node.data.transformType === 'custom' && (
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Custom Transformations
            </label>

            <div className="space-y-2 mb-3">
              {(node.data.transformations || []).map((transform, index) => (
                <div key={index} className="flex items-center gap-2 bg-gray-50 p-2 rounded">
                  <span className="text-sm font-medium">{transform.name}:</span>
                  <span className="text-sm font-mono flex-1">{transform.expression}</span>
                  <button
                    onClick={() => removeTransformation(index)}
                    className="text-red-600 hover:text-red-800"
                  >
                    ✕
                  </button>
                </div>
              ))}
            </div>

            <div className="flex gap-2">
              <input
                type="text"
                value={newField.name}
                onChange={(e) => setNewField({ ...newField, name: e.target.value })}
                className="flex-1 px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-green-500"
                placeholder="Field name"
              />
              <input
                type="text"
                value={newField.expression}
                onChange={(e) => setNewField({ ...newField, expression: e.target.value })}
                className="flex-2 px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-green-500"
                placeholder="Expression (e.g., column1 + column2)"
              />
              <button
                onClick={addTransformation}
                className="px-4 py-2 bg-green-600 text-white rounded-md hover:bg-green-700"
              >
                Add
              </button>
            </div>
          </div>
        )}

        {node.data.transformType === 'rename' && (
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Field Mappings (JSON)
            </label>
            <textarea
              value={node.data.fieldMappings || '{"old_name": "new_name"}'}
              onChange={(e) => handleChange('fieldMappings', e.target.value)}
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-green-500 h-24 font-mono text-sm"
              placeholder='{"old_field": "new_field", "another_field": "renamed_field"}'
            />
          </div>
        )}

        {node.data.transformType === 'cast' && (
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-1">
              Type Casting Rules (JSON)
            </label>
            <textarea
              value={node.data.typeCasting || '{"field": "type"}'}
              onChange={(e) => handleChange('typeCasting', e.target.value)}
              className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-green-500 h-24 font-mono text-sm"
              placeholder='{"price": "float", "quantity": "integer", "date": "datetime"}'
            />
          </div>
        )}

        {node.data.transformType === 'pivot' && (
          <>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Index Column
              </label>
              <input
                type="text"
                value={node.data.indexColumn || ''}
                onChange={(e) => handleChange('indexColumn', e.target.value)}
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-green-500"
                placeholder="e.g., date"
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Pivot Column
              </label>
              <input
                type="text"
                value={node.data.pivotColumn || ''}
                onChange={(e) => handleChange('pivotColumn', e.target.value)}
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-green-500"
                placeholder="e.g., category"
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Value Column
              </label>
              <input
                type="text"
                value={node.data.valueColumn || ''}
                onChange={(e) => handleChange('valueColumn', e.target.value)}
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-green-500"
                placeholder="e.g., amount"
              />
            </div>
          </>
        )}

        <div className="flex items-center">
          <input
            type="checkbox"
            id={`preserve-${node.id}`}
            checked={node.data.preserveOriginalFields || false}
            onChange={(e) => handleChange('preserveOriginalFields', e.target.checked)}
            className="mr-2"
          />
          <label htmlFor={`preserve-${node.id}`} className="text-sm text-gray-700">
            Preserve original fields
          </label>
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">
            Description
          </label>
          <textarea
            value={node.data.description || ''}
            onChange={(e) => handleChange('description', e.target.value)}
            className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-green-500 h-16"
            placeholder="Describe what this transformation does..."
          />
        </div>
      </div>
    </div>
  );
};

export default TransformConfig;