require 'csv'
require 'json'
require 'net/http'

class InputNodeProcessor
  def process(node, context)
    # Validate node structure
    unless node['data']
      return { success: false, error: 'Node data missing' }
    end

    source_type = node['data']['sourceType']

    # Validate source type
    if source_type.nil?
      return { success: false, error: 'Source type not specified' }
    end

    begin
      # Process based on source type
      result_data = case source_type
      when 'csv'
        process_csv(node['data'])
      when 'json'
        process_json(node['data'])
      when 'database'
        process_database(node['data'])
      when 'api'
        process_api(node['data'])
      else
        return { success: false, error: "Unsupported source type: #{source_type}" }
      end

      { success: true, data: result_data }
    rescue StandardError => e
      { success: false, error: e.message }
    end
  end

  private

  def process_csv(data)
    csv_content = data['csvContent']

    if csv_content.nil? || csv_content.empty?
      raise 'Empty CSV data'
    end

    delimiter = data['delimiter'] || ','

    # Parse CSV with proper quote handling
    rows = []
    begin
      CSV.parse(csv_content, col_sep: delimiter, liberal_parsing: true) do |row|
        rows << row
      end
    rescue CSV::MalformedCSVError
      # Try again with more lenient parsing
      CSV.parse(csv_content.gsub('""', '"'), col_sep: delimiter) do |row|
        rows << row
      end
    end

    rows
  end

  def process_json(data)
    json_content = data['jsonContent']

    begin
      parsed = JSON.parse(json_content)
    rescue JSON::ParserError
      raise 'Invalid JSON'
    end

    if parsed.empty?
      raise 'Empty JSON data'
    end

    # Convert JSON array of objects to table format
    if parsed.is_a?(Array) && parsed.first.is_a?(Hash)
      # Flatten nested objects
      flattened_data = parsed.map { |item| flatten_hash(item) }

      # Get all keys
      all_keys = flattened_data.flat_map(&:keys).uniq

      # Create header row
      result = [all_keys]

      # Add data rows
      flattened_data.each do |item|
        row = all_keys.map { |key| item[key] }
        result << row
      end

      result
    else
      raise 'Invalid JSON format - expected array of objects'
    end
  end

  def process_database(data)
    query = data['query']
    connection_id = data['connectionId']

    # Execute query (this would connect to actual database in production)
    results = execute_query(query, connection_id)

    if results.empty?
      raise 'No data returned from query'
    end

    # Convert query results to table format
    headers = results.first.keys

    result = [headers]
    results.each do |row|
      result << headers.map { |h| row[h] }
    end

    result
  end

  def process_api(data)
    endpoint = data['endpoint']
    method = data['method'] || 'GET'
    headers = data['headers'] || {}
    pagination = data['pagination']

    if pagination
      # Handle paginated API calls
      results = fetch_all_pages(endpoint, method, headers, data['pageSize'])
    else
      # Single API call
      results = fetch_from_api(endpoint, method, headers)
    end

    if results.empty?
      raise 'No data returned from API'
    end

    # Convert API response to table format
    if results.is_a?(Array) && results.first.is_a?(Hash)
      headers = results.first.keys

      result = [headers]
      results.each do |row|
        result << headers.map { |h| row[h] }
      end

      result
    else
      raise 'Invalid API response format'
    end
  end

  def flatten_hash(hash, parent_key = nil, result = {})
    hash.each do |key, value|
      new_key = parent_key ? "#{parent_key}.#{key}" : key.to_s

      if value.is_a?(Hash)
        flatten_hash(value, new_key, result)
      else
        result[new_key] = value
      end
    end

    result
  end

  def execute_query(query, connection_id)
    # This is a placeholder - in production, this would:
    # 1. Look up the database connection by connection_id
    # 2. Execute the query
    # 3. Return results

    # For testing purposes, we'll just raise an error if not mocked
    raise 'Database connection not implemented'
  end

  def fetch_from_api(endpoint, method, headers)
    # This is a placeholder - in production, this would:
    # 1. Make HTTP request to endpoint
    # 2. Parse response
    # 3. Return data

    # For testing purposes, we'll just raise an error if not mocked
    raise 'API fetching not implemented'
  end

  def fetch_all_pages(endpoint, method, headers, page_size)
    # This is a placeholder for paginated API fetching
    # In production, this would handle pagination logic

    # For testing purposes, we'll just raise an error if not mocked
    raise 'Paginated API fetching not implemented'
  end
end