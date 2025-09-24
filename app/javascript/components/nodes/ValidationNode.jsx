import React from 'react';
import { Handle, Position } from 'reactflow';

const ValidationNode = ({ id, data, selected }) => {
  // Get validation mode badge styling
  const getValidationModeBadgeClass = (mode) => {
    switch (mode) {
      case 'strict':
        return 'bg-red-100 text-red-800';
      case 'tolerant':
        return 'bg-yellow-100 text-yellow-800';
      default:
        return 'bg-gray-100 text-gray-800';
    }
  };

  // Get validation mode description
  const getValidationModeDescription = (mode) => {
    switch (mode) {
      case 'strict':
        return 'Stops on first error';
      case 'tolerant':
        return 'Collects all errors';
      default:
        return '';
    }
  };

  // Format validation rule display
  const formatValidationRule = (rule) => {
    const { field, type } = rule;

    switch (type) {
      case 'format':
        return `${field}: format (${rule.rule})`;
      case 'range':
        return `${field}: range (${rule.min}-${rule.max})`;
      case 'required':
        return `${field}: required`;
      case 'enum':
        return `${field}: enum (${rule.values?.length || 0} values)`;
      case 'pattern':
        return `${field}: pattern`;
      case 'custom':
        return `${field}: custom`;
      case 'composite':
        return `${field}: composite (${rule.rules?.length || 0} rules)`;
      case 'conditional':
        return `${field}: conditional`;
      default:
        return `${field}: ${type}`;
    }
  };

  // Calculate success rate
  const getSuccessRate = () => {
    if (!data.statistics?.totalRecords) return null;
    const { validRecords, totalRecords } = data.statistics;
    return ((validRecords / totalRecords) * 100).toFixed(1);
  };

  // Check if error rate is high
  const hasHighErrorRate = () => {
    if (!data.statistics?.totalRecords) return false;
    const { invalidRecords, totalRecords } = data.statistics;
    return (invalidRecords / totalRecords) > 0.2; // More than 20% errors
  };

  // Get connection indicator class
  const getConnectionIndicatorClass = () => {
    return data.inputConnected ? 'text-green-600' : 'text-gray-400';
  };

  // Get validation status icon
  const getValidationStatusIcon = () => {
    if (!data.validationStatus) return null;

    if (data.validationStatus === 'passed') {
      return <span data-testid="validation-status" className="text-green-600">✓</span>;
    } else if (data.validationStatus === 'failed') {
      return <span data-testid="validation-status" className="text-red-600">✗</span>;
    }
    return null;
  };

  return (
    <div
      className={`
        px-4 py-3 rounded-lg shadow-md border-2
        bg-gradient-to-br from-green-50 to-green-100
        border-green-300
        hover:shadow-lg transition-shadow
        min-w-[280px]
        ${selected ? 'ring-2 ring-green-500' : ''}
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

      {/* Valid output handle */}
      <Handle
        type="source"
        position={Position.Right}
        id="valid"
        style={{ top: '30%' }}
        data-testid="handle-source-valid"
        data-position="right"
      />

      {/* Invalid output handle */}
      <Handle
        type="source"
        position={Position.Right}
        id="invalid"
        style={{ top: '70%' }}
        data-testid="handle-source-invalid"
        data-position="right"
      />

      {/* Header */}
      <div className="flex items-center justify-between mb-2">
        <div className="flex items-center gap-2">
          <span className="text-lg">✅</span>
          <span className="font-semibold text-gray-800">{data.label}</span>
          {data.isProcessing && (
            <div data-testid="processing-spinner" className="animate-spin h-4 w-4 border-2 border-green-500 rounded-full border-t-transparent" />
          )}
        </div>
        <div className="flex items-center gap-2">
          {data.inputConnected !== undefined && (
            <span
              data-testid="connected-indicator"
              className={getConnectionIndicatorClass()}
            >
              ●
            </span>
          )}
          {getValidationStatusIcon()}
        </div>
      </div>

      {/* Validation Mode Badge */}
      <div className="mb-2">
        <span className={`px-2 py-1 text-xs font-medium rounded ${getValidationModeBadgeClass(data.validationMode)}`}>
          {(data.validationMode || 'strict').toUpperCase()} MODE
        </span>
        <span className="text-xs text-gray-600 ml-2">
          {getValidationModeDescription(data.validationMode)}
        </span>
      </div>

      {/* Schema Display (if using schema validation) */}
      {data.validationSchema && (
        <div className="mb-2 text-sm text-gray-700">
          <span className="font-medium">Schema: </span>
          <span>{data.validationSchema}</span>
        </div>
      )}

      {/* Validation Rules */}
      <div className="mb-2">
        {data.validationRules && data.validationRules.length > 0 ? (
          <>
            <div className="text-xs font-medium text-gray-700 mb-1">
              {data.validationRules.length} validation rules
            </div>
            <div className="space-y-1">
              {data.validationRules.slice(0, 3).map((rule) => (
                <div key={rule.id} className="text-xs text-gray-600 bg-white bg-opacity-50 px-2 py-1 rounded">
                  {formatValidationRule(rule)}
                </div>
              ))}
              {data.validationRules.length > 3 && (
                <div className="text-xs text-gray-500 italic">
                  +{data.validationRules.length - 3} more rules
                </div>
              )}
            </div>
          </>
        ) : (
          <div className="text-xs text-gray-500">No validation rules defined</div>
        )}
      </div>

      {/* Statistics */}
      {data.statistics && (
        <div className="text-xs text-gray-600 pt-2 border-t border-green-200">
          <div className="flex justify-between items-center mb-1">
            <span>
              {data.statistics.validRecords}/{data.statistics.totalRecords} valid
            </span>
            <span>({getSuccessRate()}%)</span>
          </div>

          {/* High error warning */}
          {hasHighErrorRate() && (
            <div data-testid="high-error-warning" className="text-yellow-600 font-medium">
              ⚠️ High error rate
            </div>
          )}

          {/* Error breakdown */}
          {data.statistics.errors && Object.keys(data.statistics.errors).length > 0 && (
            <div className="mt-1">
              <span className="font-medium">Errors:</span>
              <div className="ml-2">
                {Object.entries(data.statistics.errors).map(([field, count]) => (
                  <div key={field}>{field}: {count}</div>
                ))}
              </div>
            </div>
          )}
        </div>
      )}

      {/* Output Labels */}
      <div className="absolute right-8 top-[30%] -translate-y-1/2 text-xs text-green-600">
        Valid
      </div>
      <div className="absolute right-8 top-[70%] -translate-y-1/2 text-xs text-red-600">
        Invalid
      </div>
    </div>
  );
};

export default ValidationNode;