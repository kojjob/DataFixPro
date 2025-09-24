import React from 'react';
import { Handle, Position } from 'reactflow';

const SplitNode = ({ id, data, selected }) => {
  // Color palette for different output ports
  const portColors = [
    'bg-blue-100 text-blue-800',
    'bg-green-100 text-green-800',
    'bg-yellow-100 text-yellow-800',
    'bg-purple-100 text-purple-800',
    'bg-pink-100 text-pink-800',
    'bg-indigo-100 text-indigo-800'
  ];

  // Get split type badge styling
  const getSplitTypeBadgeClass = (splitType) => {
    switch (splitType) {
      case 'conditional':
        return 'bg-blue-100 text-blue-800';
      case 'random':
        return 'bg-green-100 text-green-800';
      case 'hash':
        return 'bg-purple-100 text-purple-800';
      case 'round-robin':
        return 'bg-orange-100 text-orange-800';
      default:
        return 'bg-gray-100 text-gray-800';
    }
  };

  // Calculate percentage for row counts
  const calculatePercentage = (count, total) => {
    if (!total) return 0;
    return Math.round((count / total) * 100);
  };

  // Get total row count
  const getTotalRows = () => {
    if (!data.rowCounts) return 0;
    return Object.values(data.rowCounts).reduce((sum, count) => sum + count, 0);
  };

  // Render split criteria based on type
  const renderSplitCriteria = () => {
    const { splitType } = data;

    if (splitType === 'random' && data.splitRatio) {
      return (
        <div className="text-xs text-gray-600">
          {data.splitRatio.join('% / ')}%
        </div>
      );
    }

    if (splitType === 'hash' && data.hashField) {
      return (
        <div className="text-xs text-gray-600">
          <div>Field: {data.hashField}</div>
          <div>{data.buckets || 2} buckets</div>
        </div>
      );
    }

    if (splitType === 'conditional' && data.conditions?.length > 0) {
      return (
        <div className="space-y-1">
          {data.conditions.map((condition, index) => (
            <div
              key={condition.id}
              data-testid={`output-port-${index + 1}`}
              className={`text-xs p-1 rounded ${portColors[index % portColors.length]}`}
            >
              <div className="font-medium">{condition.name}</div>
              {condition.isElse ? (
                <div className="text-xs opacity-75">(else)</div>
              ) : (
                <div className="text-xs opacity-75">
                  {condition.field} {condition.operator} {condition.value}
                </div>
              )}
              {data.rowCounts?.[data.outputPorts?.[index]] && (
                <div className="text-xs mt-1">
                  {data.rowCounts[data.outputPorts[index]].toLocaleString()} rows
                  <span className="ml-1">
                    ({calculatePercentage(
                      data.rowCounts[data.outputPorts[index]],
                      getTotalRows()
                    )}%)
                  </span>
                </div>
              )}
            </div>
          ))}
        </div>
      );
    }

    return <div className="text-xs text-gray-500">No conditions defined</div>;
  };

  // Get connection indicator class
  const getConnectionIndicatorClass = () => {
    return data.inputConnected ? 'text-green-600' : 'text-gray-400';
  };

  // Determine number of outputs
  const outputCount = data.outputPorts?.length || data.conditions?.length || 2;

  return (
    <div
      className={`
        px-4 py-3 rounded-lg shadow-md border-2
        bg-gradient-to-br from-purple-50 to-purple-100
        border-purple-300
        hover:shadow-lg transition-shadow
        min-w-[250px]
        ${selected ? 'ring-2 ring-purple-500' : ''}
      `}
    >
      {/* Input handle */}
      <Handle
        type="target"
        position={Position.Left}
        id="input"
        style={{ top: '50%' }}
        data-testid="handle-target-input"
        data-position="left"
      />

      {/* Output handles - dynamically positioned */}
      {Array.from({ length: outputCount }).map((_, index) => (
        <Handle
          key={`output${index + 1}`}
          type="source"
          position={Position.Right}
          id={`output${index + 1}`}
          style={{
            top: `${((index + 1) * 100) / (outputCount + 1)}%`
          }}
          data-testid={`handle-source-output${index + 1}`}
          data-position="right"
        />
      ))}

      {/* Header */}
      <div className="flex items-center justify-between mb-2">
        <div className="flex items-center gap-2">
          <span className="text-lg">🔀</span>
          <span className="font-semibold text-gray-800">{data.label}</span>
          {data.isProcessing && (
            <div data-testid="processing-spinner" className="animate-spin h-4 w-4 border-2 border-purple-500 rounded-full border-t-transparent" />
          )}
        </div>
        {data.inputConnected !== undefined && (
          <span
            data-testid="connected-indicator"
            className={getConnectionIndicatorClass()}
          >
            ●
          </span>
        )}
      </div>

      {/* Split Type Badge */}
      <div className="mb-2">
        <span className={`px-2 py-1 text-xs font-medium rounded ${getSplitTypeBadgeClass(data.splitType)}`}>
          {(data.splitType || 'conditional').toUpperCase()}
        </span>
      </div>

      {/* Split Criteria */}
      <div className="mb-2">
        {renderSplitCriteria()}
      </div>

      {/* Statistics (if available) */}
      {data.rowCounts && getTotalRows() > 0 && (
        <div className="text-xs text-gray-500 mt-2 pt-2 border-t border-purple-200">
          Total: {getTotalRows().toLocaleString()} rows
        </div>
      )}

      {/* Validation Indicator */}
      {data.validation && (
        <div className="absolute top-2 right-2">
          {data.validation.isValid ? (
            <span className="text-green-600">✓</span>
          ) : (
            <span
              className="text-yellow-600"
              title={data.validation.error}
            >
              ⚠️
            </span>
          )}
        </div>
      )}
    </div>
  );
};

export default SplitNode;