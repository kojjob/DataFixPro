import React from 'react';
import { Handle, Position } from 'reactflow';

const FilterNode = ({ data, isConnectable }) => {
  return (
    <div className="px-4 py-2 shadow-md rounded-md bg-yellow-50 border-2 border-yellow-300 min-w-[150px]">
      <Handle
        type="target"
        position={Position.Left}
        id="input"
        style={{ background: '#F59E0B' }}
        isConnectable={isConnectable}
      />
      <div className="flex items-center">
        <div className="rounded-full w-3 h-3 bg-yellow-500 mr-2"></div>
        <div className="text-sm font-bold text-yellow-900">{data.label}</div>
      </div>
      <div className="text-xs text-yellow-700 mt-1">
        🔍 {data.conditions?.length || 0} conditions
      </div>
      <Handle
        type="source"
        position={Position.Right}
        id="output"
        style={{ background: '#F59E0B' }}
        isConnectable={isConnectable}
      />
    </div>
  );
};

export default FilterNode;