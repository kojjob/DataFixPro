import React from 'react';
import { Handle, Position } from 'reactflow';

const DataSourceNode = ({ data, isConnectable }) => {
  return (
    <div className="px-4 py-2 shadow-md rounded-md bg-blue-50 border-2 border-blue-300 min-w-[150px]">
      <div className="flex items-center">
        <div className="rounded-full w-3 h-3 bg-blue-500 mr-2"></div>
        <div className="text-sm font-bold text-blue-900">{data.label}</div>
      </div>
      <div className="text-xs text-blue-700 mt-1">
        {data.sourceType === 'database' ? '🗄️ Database' : '🔌 API'}
      </div>
      {data.tableName && (
        <div className="text-xs text-blue-600 mt-1 font-mono">
          {data.tableName}
        </div>
      )}
      <Handle
        type="source"
        position={Position.Right}
        id="output"
        style={{ background: '#3B82F6' }}
        isConnectable={isConnectable}
      />
    </div>
  );
};

export default DataSourceNode;