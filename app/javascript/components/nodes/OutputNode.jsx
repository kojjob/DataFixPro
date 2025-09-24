import React from 'react';
import { Handle, Position } from 'reactflow';

const OutputNode = ({ data, isConnectable }) => {
  return (
    <div className="px-4 py-2 shadow-md rounded-md bg-red-50 border-2 border-red-300 min-w-[150px]">
      <Handle
        type="target"
        position={Position.Left}
        id="input"
        style={{ background: '#EF4444' }}
        isConnectable={isConnectable}
      />
      <div className="flex items-center">
        <div className="rounded-full w-3 h-3 bg-red-500 mr-2"></div>
        <div className="text-sm font-bold text-red-900">{data.label}</div>
      </div>
      <div className="text-xs text-red-700 mt-1">
        💾 {data.outputType === 'database' ? 'Database' : 'File Export'}
      </div>
      {data.destination && (
        <div className="text-xs text-red-600 mt-1 font-mono">
          {data.destination}
        </div>
      )}
    </div>
  );
};

export default OutputNode;