import React, { useState, useRef, useCallback } from 'react';
import ReactFlow, {
  ReactFlowProvider,
  addEdge,
  useNodesState,
  useEdgesState,
  Controls,
  Background,
  MiniMap,
  Panel,
  useReactFlow,
  MarkerType
} from 'reactflow';
import 'reactflow/dist/style.css';

// Import custom node types
import DataSourceNode from './nodes/DataSourceNode';
import TransformNode from './nodes/TransformNode';
import FilterNode from './nodes/FilterNode';
import AggregateNode from './nodes/AggregateNode';
import OutputNode from './nodes/OutputNode';

// Import configuration panels
import DataSourceConfig from './config/DataSourceConfig';
import TransformConfig from './config/TransformConfig';
import FilterConfig from './config/FilterConfig';
import AggregateConfig from './config/AggregateConfig';
import OutputConfig from './config/OutputConfig';

// Define custom node types
const nodeTypes = {
  dataSource: DataSourceNode,
  transform: TransformNode,
  filter: FilterNode,
  aggregate: AggregateNode,
  output: OutputNode,
};

// Initial nodes for demo
const initialNodes = [
  {
    id: '1',
    type: 'dataSource',
    position: { x: 100, y: 100 },
    data: {
      label: 'Data Source',
      sourceType: 'database',
      tableName: '',
      connected: false
    },
  },
];

const initialEdges = [];

// Define edge style
const defaultEdgeOptions = {
  animated: true,
  type: 'smoothstep',
  markerEnd: {
    type: MarkerType.ArrowClosed,
  },
};

// Sidebar component for dragging new nodes
const Sidebar = () => {
  const onDragStart = (event, nodeType) => {
    event.dataTransfer.setData('application/reactflow', nodeType);
    event.dataTransfer.effectAllowed = 'move';
  };

  return (
    <aside className="w-64 bg-white border-r border-gray-200 p-4">
      <h3 className="text-lg font-semibold mb-4">Pipeline Components</h3>

      <div className="space-y-3">
        <div
          className="p-3 bg-blue-50 border border-blue-200 rounded-lg cursor-move hover:bg-blue-100 transition-colors"
          onDragStart={(event) => onDragStart(event, 'dataSource')}
          draggable
        >
          <div className="font-medium text-blue-900">📊 Data Source</div>
          <div className="text-sm text-blue-700 mt-1">Connect to database or API</div>
        </div>

        <div
          className="p-3 bg-green-50 border border-green-200 rounded-lg cursor-move hover:bg-green-100 transition-colors"
          onDragStart={(event) => onDragStart(event, 'transform')}
          draggable
        >
          <div className="font-medium text-green-900">🔄 Transform</div>
          <div className="text-sm text-green-700 mt-1">Modify data structure</div>
        </div>

        <div
          className="p-3 bg-yellow-50 border border-yellow-200 rounded-lg cursor-move hover:bg-yellow-100 transition-colors"
          onDragStart={(event) => onDragStart(event, 'filter')}
          draggable
        >
          <div className="font-medium text-yellow-900">🔍 Filter</div>
          <div className="text-sm text-yellow-700 mt-1">Filter data rows</div>
        </div>

        <div
          className="p-3 bg-purple-50 border border-purple-200 rounded-lg cursor-move hover:bg-purple-100 transition-colors"
          onDragStart={(event) => onDragStart(event, 'aggregate')}
          draggable
        >
          <div className="font-medium text-purple-900">📈 Aggregate</div>
          <div className="text-sm text-purple-700 mt-1">Group and summarize</div>
        </div>

        <div
          className="p-3 bg-red-50 border border-red-200 rounded-lg cursor-move hover:bg-red-100 transition-colors"
          onDragStart={(event) => onDragStart(event, 'output')}
          draggable
        >
          <div className="font-medium text-red-900">💾 Output</div>
          <div className="text-sm text-red-700 mt-1">Save or export results</div>
        </div>
      </div>

      <div className="mt-8">
        <h4 className="font-medium text-gray-700 mb-2">Instructions:</h4>
        <ul className="text-sm text-gray-600 space-y-1">
          <li>• Drag components to canvas</li>
          <li>• Connect nodes by dragging handles</li>
          <li>• Click nodes to configure</li>
          <li>• Save pipeline when ready</li>
        </ul>
      </div>
    </aside>
  );
};

// Main PipelineBuilder component
const PipelineBuilderFlow = ({ pipelineId, pipelineName }) => {
  const reactFlowWrapper = useRef(null);
  const [nodes, setNodes, onNodesChange] = useNodesState(initialNodes);
  const [edges, setEdges, onEdgesChange] = useEdgesState(initialEdges);
  const [selectedNode, setSelectedNode] = useState(null);
  const { project } = useReactFlow();

  let id = 2; // Node ID counter

  const getId = () => `node_${id++}`;

  // Handle connections between nodes
  const onConnect = useCallback((params) => {
    setEdges((eds) => addEdge({ ...params, ...defaultEdgeOptions }, eds));
  }, [setEdges]);

  // Handle drop event
  const onDragOver = useCallback((event) => {
    event.preventDefault();
    event.dataTransfer.dropEffect = 'move';
  }, []);

  const onDrop = useCallback(
    (event) => {
      event.preventDefault();

      const reactFlowBounds = reactFlowWrapper.current.getBoundingClientRect();
      const type = event.dataTransfer.getData('application/reactflow');

      // Check if the dropped element is valid
      if (typeof type === 'undefined' || !type) {
        return;
      }

      const position = project({
        x: event.clientX - reactFlowBounds.left,
        y: event.clientY - reactFlowBounds.top,
      });

      // Create new node based on type
      const newNode = {
        id: getId(),
        type,
        position,
        data: getNodeData(type),
      };

      setNodes((nds) => nds.concat(newNode));
    },
    [project, setNodes]
  );

  // Get initial data for different node types
  const getNodeData = (type) => {
    switch (type) {
      case 'dataSource':
        return { label: 'Data Source', sourceType: 'database', tableName: '', connected: false };
      case 'transform':
        return { label: 'Transform', transformations: [] };
      case 'filter':
        return { label: 'Filter', conditions: [] };
      case 'aggregate':
        return { label: 'Aggregate', groupBy: [], aggregations: [] };
      case 'output':
        return { label: 'Output', outputType: 'database', destination: '' };
      default:
        return { label: 'Node' };
    }
  };

  // Handle node click for configuration
  const onNodeClick = useCallback((event, node) => {
    setSelectedNode(node);
  }, []);

  // Handle node data update from configuration panel
  const handleNodeDataChange = useCallback((nodeId, newData) => {
    setNodes((nds) =>
      nds.map((node) => {
        if (node.id === nodeId) {
          return { ...node, data: newData };
        }
        return node;
      })
    );
  }, [setNodes]);

  // Save pipeline to backend
  const savePipeline = async () => {
    const pipelineData = {
      nodes,
      edges,
      name: pipelineName,
      updated_at: new Date().toISOString()
    };

    try {
      const response = await fetch(`/api/pipelines/${pipelineId || 'new'}`, {
        method: pipelineId ? 'PUT' : 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
        },
        body: JSON.stringify({ pipeline: pipelineData })
      });

      if (response.ok) {
        alert('Pipeline saved successfully!');
      } else {
        alert('Error saving pipeline');
      }
    } catch (error) {
      console.error('Error saving pipeline:', error);
      alert('Error saving pipeline');
    }
  };

  return (
    <div className="h-screen flex">
      <Sidebar />

      <div className="flex-1 flex flex-col">
        <div className="bg-white border-b border-gray-200 px-4 py-3 flex items-center justify-between">
          <h2 className="text-xl font-semibold text-gray-800">
            {pipelineName || 'New Pipeline'}
          </h2>
          <div className="flex gap-3">
            <button
              onClick={() => {
                setNodes(initialNodes);
                setEdges([]);
              }}
              className="px-4 py-2 bg-gray-200 text-gray-700 rounded-lg hover:bg-gray-300 transition-colors"
            >
              Clear
            </button>
            <button
              onClick={savePipeline}
              className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
            >
              Save Pipeline
            </button>
          </div>
        </div>

        <div className="flex-1" ref={reactFlowWrapper}>
          <ReactFlow
            nodes={nodes}
            edges={edges}
            onNodesChange={onNodesChange}
            onEdgesChange={onEdgesChange}
            onConnect={onConnect}
            onNodeClick={onNodeClick}
            onDrop={onDrop}
            onDragOver={onDragOver}
            nodeTypes={nodeTypes}
            defaultEdgeOptions={defaultEdgeOptions}
            fitView
          >
            <Background variant="dots" gap={12} size={1} />
            <Controls />
            <MiniMap
              nodeStrokeColor={(n) => {
                switch (n.type) {
                  case 'dataSource': return '#3B82F6';
                  case 'transform': return '#10B981';
                  case 'filter': return '#F59E0B';
                  case 'aggregate': return '#8B5CF6';
                  case 'output': return '#EF4444';
                  default: return '#6B7280';
                }
              }}
              nodeColor={(n) => {
                switch (n.type) {
                  case 'dataSource': return '#DBEAFE';
                  case 'transform': return '#D1FAE5';
                  case 'filter': return '#FEF3C7';
                  case 'aggregate': return '#EDE9FE';
                  case 'output': return '#FEE2E2';
                  default: return '#F3F4F6';
                }
              }}
            />
          </ReactFlow>
        </div>

        {/* Node Configuration Panel */}
        {selectedNode && (
          <div className="absolute right-0 top-0 h-full w-96 bg-gray-50 border-l border-gray-200 shadow-lg overflow-y-auto">
            <div className="sticky top-0 bg-white border-b border-gray-200 p-4 flex items-center justify-between">
              <h3 className="text-lg font-semibold">Configure Node</h3>
              <button
                onClick={() => setSelectedNode(null)}
                className="text-gray-400 hover:text-gray-600 text-2xl"
              >
                ×
              </button>
            </div>
            <div className="p-4">
              {selectedNode.type === 'dataSource' && (
                <DataSourceConfig
                  node={selectedNode}
                  onChange={handleNodeDataChange}
                />
              )}
              {selectedNode.type === 'transform' && (
                <TransformConfig
                  node={selectedNode}
                  onChange={handleNodeDataChange}
                />
              )}
              {selectedNode.type === 'filter' && (
                <FilterConfig
                  node={selectedNode}
                  onChange={handleNodeDataChange}
                />
              )}
              {selectedNode.type === 'aggregate' && (
                <AggregateConfig
                  node={selectedNode}
                  onChange={handleNodeDataChange}
                />
              )}
              {selectedNode.type === 'output' && (
                <OutputConfig
                  node={selectedNode}
                  onChange={handleNodeDataChange}
                />
              )}
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

// Export wrapped component
const PipelineBuilder = (props) => {
  return (
    <ReactFlowProvider>
      <PipelineBuilderFlow {...props} />
    </ReactFlowProvider>
  );
};

export default PipelineBuilder;