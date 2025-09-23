import React from 'react';
import { Handle, Position } from 'reactflow';

const TransformNode = ({ data, isConnectable }) => {
  return (
    <div className="px-4 py-2 shadow-md rounded-md bg-green-50 border-2 border-green-300 min-w-[150px]">
      <Handle
        type="target"
        position={Position.Left}
        id="input"
        style={{ background: '#10B981' }}
        isConnectable={isConnectable}
      />
      <div className="flex items-center">
        <div className="rounded-full w-3 h-3 bg-green-500 mr-2"></div>
        <div className="text-sm font-bold text-green-900">{data.label}</div>
      </div>
      <div className="text-xs text-green-700 mt-1">
        🔄 {data.transformations?.length || 0} transformations
      </div>
      <Handle
        type="source"
        position={Position.Right}
        id="output"
        style={{ background: '#10B981' }}
        isConnectable={isConnectable}
      />
    </div>
  );
};

export default TransformNode;