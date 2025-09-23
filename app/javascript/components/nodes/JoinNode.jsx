import React from 'react';
import { Handle, Position } from 'reactflow';

const JoinNode = ({ id, data, selected }) => {
  const getJoinTypeBadgeClass = (joinType) => {
    switch (joinType) {
      case 'inner':
        return 'bg-blue-100 text-blue-800';
      case 'left':
        return 'bg-green-100 text-green-800';
      case 'right':
        return 'bg-yellow-100 text-yellow-800';
      case 'full':
        return 'bg-purple-100 text-purple-800';
      default:
        return 'bg-gray-100 text-gray-800';
    }
  };

  const getFieldCount = () => {
    const leftCount = data.selectedFields?.left?.length || 0;
    const rightCount = data.selectedFields?.right?.length || 0;

    if (leftCount === 0 && rightCount === 0) {
      return 'No fields selected';
    }

    if (data.selectedFields?.left?.includes('*') || data.selectedFields?.right?.includes('*')) {
      return 'All fields';
    }

    const total = leftCount + rightCount;
    return `${total} field${total !== 1 ? 's' : ''}`;
  };

  const getConditionDisplay = () => {
    if (!data.joinConditions || data.joinConditions.length === 0) {
      return 'No conditions';
    }

    if (data.joinConditions.length === 1) {
      const condition = data.joinConditions[0];
      return `${condition.leftField} ${condition.operator} ${condition.rightField}`;
    }

    return `${data.joinConditions.length} conditions`;
  };

  const getConnectionIndicatorClass = () => {
    if (data.inputsConnected?.left && data.inputsConnected?.right) {
      return 'text-green-600';
    }
    if (data.inputsConnected?.left || data.inputsConnected?.right) {
      return 'text-yellow-600';
    }
    return 'text-gray-400';
  };

  return (
    <div
      className={`
        px-4 py-3 rounded-lg shadow-md border-2
        bg-gradient-to-br from-indigo-50 to-indigo-100
        border-indigo-300
        hover:shadow-lg transition-shadow
        min-w-[250px]
        ${selected ? 'ring-2 ring-indigo-500' : ''}
      `}
    >
      {/* Left input handle */}
      <Handle
        type="target"
        position={Position.Left}
        id="left"
        style={{ top: '30%' }}
        data-testid="handle-target-left"
        data-position="left"
      />

      {/* Right input handle */}
      <Handle
        type="target"
        position={Position.Left}
        id="right"
        style={{ top: '70%' }}
        data-testid="handle-target-right"
        data-position="left"
      />

      {/* Output handle */}
      <Handle
        type="source"
        position={Position.Right}
        id="output"
        style={{ top: '50%' }}
        data-testid="handle-source-output"
        data-position="right"
      />

      {/* Header */}
      <div className="flex items-center justify-between mb-2">
        <div className="flex items-center gap-2">
          <span className="text-lg">🔗</span>
          <span className="font-semibold text-gray-800">{data.label}</span>
          {data.isProcessing && (
            <div data-testid="processing-spinner" className="animate-spin h-4 w-4 border-2 border-indigo-500 rounded-full border-t-transparent" />
          )}
        </div>
        {data.inputsConnected && (
          <span
            data-testid="connected-indicator"
            className={getConnectionIndicatorClass()}
          >
            ●
          </span>
        )}
      </div>

      {/* Join Type Badge */}
      <div className="mb-2">
        <span className={`px-2 py-1 text-xs font-medium rounded ${getJoinTypeBadgeClass(data.joinType)}`}>
          {(data.joinType || 'inner').toUpperCase()}
        </span>
      </div>

      {/* Table Names */}
      <div className="text-sm text-gray-700 mb-2">
        <div className="flex items-center gap-1">
          <span className="font-medium">{data.leftTable || 'Left Table'}</span>
          <span className="text-gray-500">⋈</span>
          <span className="font-medium">{data.rightTable || 'Right Table'}</span>
        </div>
      </div>

      {/* Join Conditions */}
      <div className="text-xs text-gray-600 mb-2">
        <span className="font-medium">On: </span>
        <span>{getConditionDisplay()}</span>
      </div>

      {/* Selected Fields */}
      <div className="text-xs text-gray-600 mb-2">
        <span className="font-medium">Fields: </span>
        <span>{getFieldCount()}</span>
      </div>

      {/* Stats */}
      {(data.rowCount || data.executionTime) && (
        <div className="text-xs text-gray-500 flex gap-2 mt-2 pt-2 border-t border-indigo-200">
          {data.rowCount && (
            <span>{data.rowCount.toLocaleString()} rows</span>
          )}
          {data.executionTime && (
            <span>{data.executionTime}ms</span>
          )}
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

export default JoinNode;