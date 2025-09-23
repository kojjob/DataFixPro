import React from 'react';
import { Handle, Position } from 'reactflow';

const AggregateNode = ({ data, isConnectable }) => {
  return (
    <div className="px-4 py-2 shadow-md rounded-md bg-purple-50 border-2 border-purple-300 min-w-[150px]">
      <Handle
        type="target"
        position={Position.Left}
        id="input"
        style={{ background: '#8B5CF6' }}
        isConnectable={isConnectable}
      />
      <div className="flex items-center">
        <div className="rounded-full w-3 h-3 bg-purple-500 mr-2"></div>
        <div className="text-sm font-bold text-purple-900">{data.label}</div>
      </div>
      <div className="text-xs text-purple-700 mt-1">
        📈 {data.aggregations?.length || 0} aggregations
      </div>
      {data.groupBy && data.groupBy.length > 0 && (
        <div className="text-xs text-purple-600 mt-1">
          Group by: {data.groupBy.join(', ')}
        </div>
      )}
      <Handle
        type="source"
        position={Position.Right}
        id="output"
        style={{ background: '#8B5CF6' }}
        isConnectable={isConnectable}
      />
    </div>
  );
};

export default AggregateNode;