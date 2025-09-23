import React from 'react';

const DataSourceConfig = ({ node, onChange }) => {
  const handleChange = (field, value) => {
    onChange(node.id, {
      ...node.data,
      [field]: value
    });
  };

  return (
    <div className="p-4 bg-white rounded-lg shadow-lg">
      <h3 className="text-lg font-semibold mb-4">Data Source Configuration</h3>

      <div className="space-y-4">
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">
            Source Name
          </label>
          <input
            type="text"
            value={node.data.label || ''}
            onChange={(e) => handleChange('label', e.target.value)}
            className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            placeholder="Enter source name"
          />
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">
            Source Type
          </label>
          <select
            value={node.data.sourceType || 'database'}
            onChange={(e) => handleChange('sourceType', e.target.value)}
            className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
          >
            <option value="database">Database</option>
            <option value="api">API</option>
            <option value="file">File Upload</option>
            <option value="webhook">Webhook</option>
          </select>
        </div>

        {node.data.sourceType === 'database' && (
          <>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Database Type
              </label>
              <select
                value={node.data.databaseType || 'postgresql'}
                onChange={(e) => handleChange('databaseType', e.target.value)}
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
              >
                <option value="postgresql">PostgreSQL</option>
                <option value="mysql">MySQL</option>
                <option value="mongodb">MongoDB</option>
                <option value="sqlite">SQLite</option>
                <option value="mssql">SQL Server</option>
              </select>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Table/Collection
              </label>
              <input
                type="text"
                value={node.data.tableName || ''}
                onChange={(e) => handleChange('tableName', e.target.value)}
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                placeholder="Enter table or collection name"
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Query (Optional)
              </label>
              <textarea
                value={node.data.query || ''}
                onChange={(e) => handleChange('query', e.target.value)}
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 h-24 font-mono text-sm"
                placeholder="SELECT * FROM table WHERE condition"
              />
            </div>
          </>
        )}

        {node.data.sourceType === 'api' && (
          <>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                API Endpoint
              </label>
              <input
                type="text"
                value={node.data.endpoint || ''}
                onChange={(e) => handleChange('endpoint', e.target.value)}
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                placeholder="https://api.example.com/data"
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                HTTP Method
              </label>
              <select
                value={node.data.httpMethod || 'GET'}
                onChange={(e) => handleChange('httpMethod', e.target.value)}
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
              >
                <option value="GET">GET</option>
                <option value="POST">POST</option>
                <option value="PUT">PUT</option>
                <option value="DELETE">DELETE</option>
              </select>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Headers (JSON)
              </label>
              <textarea
                value={node.data.headers || '{}'}
                onChange={(e) => handleChange('headers', e.target.value)}
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 h-20 font-mono text-sm"
                placeholder='{"Authorization": "Bearer token"}'
              />
            </div>
          </>
        )}

        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">
            Refresh Interval (minutes)
          </label>
          <input
            type="number"
            value={node.data.refreshInterval || 60}
            onChange={(e) => handleChange('refreshInterval', parseInt(e.target.value))}
            className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            min="1"
          />
        </div>

        <div className="flex items-center">
          <input
            type="checkbox"
            id={`cache-${node.id}`}
            checked={node.data.enableCache || false}
            onChange={(e) => handleChange('enableCache', e.target.checked)}
            className="mr-2"
          />
          <label htmlFor={`cache-${node.id}`} className="text-sm text-gray-700">
            Enable caching
          </label>
        </div>
      </div>
    </div>
  );
};

export default DataSourceConfig;