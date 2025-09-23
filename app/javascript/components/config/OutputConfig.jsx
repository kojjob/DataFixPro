import React from 'react';

const OutputConfig = ({ node, onChange }) => {
  const handleChange = (field, value) => {
    onChange(node.id, {
      ...node.data,
      [field]: value
    });
  };

  return (
    <div className="p-4 bg-white rounded-lg shadow-lg">
      <h3 className="text-lg font-semibold mb-4">Output Configuration</h3>

      <div className="space-y-4">
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">
            Output Name
          </label>
          <input
            type="text"
            value={node.data.label || ''}
            onChange={(e) => handleChange('label', e.target.value)}
            className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-red-500"
            placeholder="Enter output name"
          />
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">
            Output Type
          </label>
          <select
            value={node.data.outputType || 'database'}
            onChange={(e) => handleChange('outputType', e.target.value)}
            className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-red-500"
          >
            <option value="database">Database</option>
            <option value="file">File Export</option>
            <option value="api">API Endpoint</option>
            <option value="webhook">Webhook</option>
            <option value="email">Email Report</option>
            <option value="dashboard">Dashboard Widget</option>
          </select>
        </div>

        {node.data.outputType === 'database' && (
          <>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Database Type
              </label>
              <select
                value={node.data.databaseType || 'postgresql'}
                onChange={(e) => handleChange('databaseType', e.target.value)}
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-red-500"
              >
                <option value="postgresql">PostgreSQL</option>
                <option value="mysql">MySQL</option>
                <option value="mongodb">MongoDB</option>
                <option value="sqlite">SQLite</option>
                <option value="mssql">SQL Server</option>
                <option value="redshift">Amazon Redshift</option>
                <option value="bigquery">Google BigQuery</option>
                <option value="snowflake">Snowflake</option>
              </select>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Table Name
              </label>
              <input
                type="text"
                value={node.data.tableName || ''}
                onChange={(e) => handleChange('tableName', e.target.value)}
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-red-500"
                placeholder="Enter destination table name"
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Write Mode
              </label>
              <select
                value={node.data.writeMode || 'append'}
                onChange={(e) => handleChange('writeMode', e.target.value)}
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-red-500"
              >
                <option value="append">Append to existing data</option>
                <option value="replace">Replace entire table</option>
                <option value="upsert">Upsert (Update or Insert)</option>
                <option value="merge">Merge with existing data</option>
              </select>
            </div>

            {(node.data.writeMode === 'upsert' || node.data.writeMode === 'merge') && (
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Key Columns (comma-separated)
                </label>
                <input
                  type="text"
                  value={node.data.keyColumns || ''}
                  onChange={(e) => handleChange('keyColumns', e.target.value)}
                  className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-red-500"
                  placeholder="e.g., id, user_id"
                />
              </div>
            )}
          </>
        )}

        {node.data.outputType === 'file' && (
          <>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                File Format
              </label>
              <select
                value={node.data.fileFormat || 'csv'}
                onChange={(e) => handleChange('fileFormat', e.target.value)}
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-red-500"
              >
                <option value="csv">CSV</option>
                <option value="json">JSON</option>
                <option value="jsonl">JSON Lines</option>
                <option value="parquet">Parquet</option>
                <option value="excel">Excel (XLSX)</option>
                <option value="xml">XML</option>
                <option value="avro">Avro</option>
              </select>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                File Path/Pattern
              </label>
              <input
                type="text"
                value={node.data.filePath || ''}
                onChange={(e) => handleChange('filePath', e.target.value)}
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-red-500"
                placeholder="e.g., /exports/data_{date}.csv"
              />
              <p className="text-xs text-gray-500 mt-1">
                Use {'{date}'}, {'{time}'}, {'{datetime}'} for dynamic naming
              </p>
            </div>

            <div className="flex items-center">
              <input
                type="checkbox"
                id={`compress-${node.id}`}
                checked={node.data.compressFile || false}
                onChange={(e) => handleChange('compressFile', e.target.checked)}
                className="mr-2"
              />
              <label htmlFor={`compress-${node.id}`} className="text-sm text-gray-700">
                Compress file (gzip)
              </label>
            </div>
          </>
        )}

        {node.data.outputType === 'api' && (
          <>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                API Endpoint
              </label>
              <input
                type="text"
                value={node.data.apiEndpoint || ''}
                onChange={(e) => handleChange('apiEndpoint', e.target.value)}
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-red-500"
                placeholder="https://api.example.com/data"
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                HTTP Method
              </label>
              <select
                value={node.data.httpMethod || 'POST'}
                onChange={(e) => handleChange('httpMethod', e.target.value)}
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-red-500"
              >
                <option value="POST">POST</option>
                <option value="PUT">PUT</option>
                <option value="PATCH">PATCH</option>
              </select>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Headers (JSON)
              </label>
              <textarea
                value={node.data.headers || '{"Content-Type": "application/json"}'}
                onChange={(e) => handleChange('headers', e.target.value)}
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-red-500 h-20 font-mono text-sm"
                placeholder='{"Authorization": "Bearer token", "Content-Type": "application/json"}'
              />
            </div>
          </>
        )}

        {node.data.outputType === 'email' && (
          <>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Recipients (comma-separated)
              </label>
              <input
                type="text"
                value={node.data.recipients || ''}
                onChange={(e) => handleChange('recipients', e.target.value)}
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-red-500"
                placeholder="user@example.com, team@example.com"
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Email Subject
              </label>
              <input
                type="text"
                value={node.data.emailSubject || ''}
                onChange={(e) => handleChange('emailSubject', e.target.value)}
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-red-500"
                placeholder="Data Pipeline Report - {date}"
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Attachment Format
              </label>
              <select
                value={node.data.attachmentFormat || 'csv'}
                onChange={(e) => handleChange('attachmentFormat', e.target.value)}
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-red-500"
              >
                <option value="csv">CSV</option>
                <option value="excel">Excel</option>
                <option value="pdf">PDF Report</option>
                <option value="none">No attachment (inline data)</option>
              </select>
            </div>
          </>
        )}

        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">
            Batch Size
          </label>
          <input
            type="number"
            value={node.data.batchSize || 1000}
            onChange={(e) => handleChange('batchSize', parseInt(e.target.value))}
            className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-red-500"
            min="1"
            placeholder="1000"
          />
          <p className="text-xs text-gray-500 mt-1">
            Number of records to process at once
          </p>
        </div>

        <div className="flex items-center">
          <input
            type="checkbox"
            id={`error-handling-${node.id}`}
            checked={node.data.continueOnError || false}
            onChange={(e) => handleChange('continueOnError', e.target.checked)}
            className="mr-2"
          />
          <label htmlFor={`error-handling-${node.id}`} className="text-sm text-gray-700">
            Continue processing on errors
          </label>
        </div>

        <div>
          <label className="block text-sm font-medium text-gray-700 mb-1">
            Description
          </label>
          <textarea
            value={node.data.description || ''}
            onChange={(e) => handleChange('description', e.target.value)}
            className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-red-500 h-16"
            placeholder="Describe what this output does..."
          />
        </div>
      </div>
    </div>
  );
};

export default OutputConfig;