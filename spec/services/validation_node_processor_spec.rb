require 'rails_helper'

RSpec.describe ValidationNodeProcessor do
  let(:processor) { described_class.new }

  describe '#process' do
    context 'with format validation' do
      let(:node) do
        {
          'id' => 'validation-1',
          'type' => 'validation',
          'data' => {
            'validationMode' => 'strict',
            'validationRules' => [
              {
                'id' => '1',
                'field' => 'email',
                'type' => 'format',
                'rule' => 'email',
                'message' => 'Invalid email format'
              },
              {
                'id' => '2',
                'field' => 'phone',
                'type' => 'format',
                'rule' => 'phone',
                'message' => 'Invalid phone format'
              }
            ]
          }
        }
      end

      let(:input_data) do
        [
          ['id', 'email', 'phone', 'name'],
          ['1', 'alice@example.com', '123-456-7890', 'Alice'],
          ['2', 'invalid-email', '555-1234', 'Bob'],
          ['3', 'charlie@test.com', 'not-a-phone', 'Charlie'],
          ['4', 'david@example.org', '987-654-3210', 'David']
        ]
      end

      let(:context) do
        { 'input-1' => input_data }
      end

      it 'validates email format' do
        result = processor.process(node, context)

        expect(result[:success]).to be true

        valid_data = result[:outputs]['valid']
        invalid_data = result[:outputs]['invalid']

        # Valid emails: alice@example.com, charlie@test.com, david@example.org
        valid_emails = valid_data[1..].map { |row| row[1] }
        expect(valid_emails).to contain_exactly('alice@example.com', 'david@example.org')

        # Invalid emails: invalid-email
        invalid_emails = invalid_data[1..].map { |row| row[1] }
        expect(invalid_emails).to include('invalid-email')
      end

      it 'validates phone format' do
        result = processor.process(node, context)

        # Valid phones: 123-456-7890, 987-654-3210
        valid_data = result[:outputs]['valid']
        valid_rows = valid_data[1..].map { |row| row[0] }
        expect(valid_rows).to contain_exactly('1', '4')
      end

      it 'reports validation statistics' do
        result = processor.process(node, context)

        expect(result[:statistics]).to include(
          totalRecords: 4,
          validRecords: 2,
          invalidRecords: 2
        )

        expect(result[:statistics][:errors]).to include(
          'email' => 1,
          'phone' => 2
        )
      end
    end

    context 'with range validation' do
      let(:node) do
        {
          'id' => 'validation-1',
          'type' => 'validation',
          'data' => {
            'validationMode' => 'tolerant',
            'validationRules' => [
              {
                'id' => '1',
                'field' => 'age',
                'type' => 'range',
                'min' => 18,
                'max' => 65,
                'message' => 'Age must be between 18 and 65'
              },
              {
                'id' => '2',
                'field' => 'score',
                'type' => 'range',
                'min' => 0,
                'max' => 100,
                'message' => 'Score must be between 0 and 100'
              }
            ]
          }
        }
      end

      let(:input_data) do
        [
          ['id', 'name', 'age', 'score'],
          ['1', 'Alice', '25', '85'],
          ['2', 'Bob', '17', '95'],   # Age too low
          ['3', 'Charlie', '45', '105'], # Score too high
          ['4', 'David', '70', '75'],   # Age too high
          ['5', 'Eve', '30', '50']
        ]
      end

      let(:context) do
        { 'input-1' => input_data }
      end

      it 'validates numeric ranges' do
        result = processor.process(node, context)

        valid_data = result[:outputs]['valid']
        invalid_data = result[:outputs]['invalid']

        # Only Alice and Eve pass all validations
        valid_names = valid_data[1..].map { |row| row[1] }
        expect(valid_names).to contain_exactly('Alice', 'Eve')

        # Bob, Charlie, David fail
        invalid_names = invalid_data[1..].map { |row| row[1] }
        expect(invalid_names).to contain_exactly('Bob', 'Charlie', 'David')
      end

      it 'tolerant mode collects all errors' do
        result = processor.process(node, context)

        # In tolerant mode, all rows are processed even if they have errors
        expect(result[:statistics][:totalRecords]).to eq(5)
        expect(result[:statistics][:errors]).to include(
          'age' => 2,  # Bob and David
          'score' => 1  # Charlie
        )
      end
    end

    context 'with required validation' do
      let(:node) do
        {
          'id' => 'validation-1',
          'type' => 'validation',
          'data' => {
            'validationMode' => 'strict',
            'validationRules' => [
              {
                'id' => '1',
                'field' => 'name',
                'type' => 'required',
                'message' => 'Name is required'
              },
              {
                'id' => '2',
                'field' => 'email',
                'type' => 'required',
                'message' => 'Email is required'
              }
            ]
          }
        }
      end

      let(:input_data) do
        [
          ['id', 'name', 'email'],
          ['1', 'Alice', 'alice@example.com'],
          ['2', '', 'bob@example.com'],      # Missing name
          ['3', 'Charlie', ''],               # Missing email
          ['4', 'David', 'david@example.com']
        ]
      end

      let(:context) do
        { 'input-1' => input_data }
      end

      it 'validates required fields' do
        result = processor.process(node, context)

        valid_data = result[:outputs]['valid']
        invalid_data = result[:outputs]['invalid']

        # Only Alice and David have all required fields
        valid_ids = valid_data[1..].map { |row| row[0] }
        expect(valid_ids).to contain_exactly('1', '4')

        invalid_ids = invalid_data[1..].map { |row| row[0] }
        expect(invalid_ids).to contain_exactly('2', '3')
      end
    end

    context 'with enum validation' do
      let(:node) do
        {
          'id' => 'validation-1',
          'type' => 'validation',
          'data' => {
            'validationMode' => 'tolerant',
            'validationRules' => [
              {
                'id' => '1',
                'field' => 'status',
                'type' => 'enum',
                'values' => ['active', 'inactive', 'pending'],
                'message' => 'Invalid status'
              },
              {
                'id' => '2',
                'field' => 'role',
                'type' => 'enum',
                'values' => ['admin', 'user', 'guest'],
                'message' => 'Invalid role'
              }
            ]
          }
        }
      end

      let(:input_data) do
        [
          ['id', 'status', 'role'],
          ['1', 'active', 'admin'],
          ['2', 'inactive', 'superuser'], # Invalid role
          ['3', 'archived', 'user'],      # Invalid status
          ['4', 'pending', 'guest']
        ]
      end

      let(:context) do
        { 'input-1' => input_data }
      end

      it 'validates enum values' do
        result = processor.process(node, context)

        valid_data = result[:outputs]['valid']
        invalid_data = result[:outputs]['invalid']

        valid_ids = valid_data[1..].map { |row| row[0] }
        expect(valid_ids).to contain_exactly('1', '4')

        invalid_ids = invalid_data[1..].map { |row| row[0] }
        expect(invalid_ids).to contain_exactly('2', '3')
      end
    end

    context 'with pattern validation' do
      let(:node) do
        {
          'id' => 'validation-1',
          'type' => 'validation',
          'data' => {
            'validationMode' => 'tolerant',
            'validationRules' => [
              {
                'id' => '1',
                'field' => 'code',
                'type' => 'pattern',
                'pattern' => '^[A-Z]{3}-\d{4}$',
                'message' => 'Code must match pattern XXX-0000'
              }
            ]
          }
        }
      end

      let(:input_data) do
        [
          ['id', 'code', 'name'],
          ['1', 'ABC-1234', 'Valid'],
          ['2', 'abc-1234', 'Invalid lowercase'],
          ['3', 'AB-1234', 'Invalid too short'],
          ['4', 'XYZ-9999', 'Valid']
        ]
      end

      let(:context) do
        { 'input-1' => input_data }
      end

      it 'validates against regex pattern' do
        result = processor.process(node, context)

        valid_data = result[:outputs]['valid']
        valid_codes = valid_data[1..].map { |row| row[1] }
        expect(valid_codes).to contain_exactly('ABC-1234', 'XYZ-9999')
      end
    end

    context 'with custom validation' do
      let(:node) do
        {
          'id' => 'validation-1',
          'type' => 'validation',
          'data' => {
            'validationMode' => 'tolerant',
            'validationRules' => [
              {
                'id' => '1',
                'field' => 'password',
                'type' => 'custom',
                'expression' => 'value.length >= 8 && /[A-Z]/.test(value) && /[0-9]/.test(value)',
                'message' => 'Password must be 8+ chars with uppercase and number'
              }
            ]
          }
        }
      end

      let(:input_data) do
        [
          ['id', 'password'],
          ['1', 'Password123'],  # Valid
          ['2', 'short'],        # Too short
          ['3', 'password123'],  # No uppercase
          ['4', 'PasswordABC']   # No number
        ]
      end

      let(:context) do
        { 'input-1' => input_data }
      end

      it 'validates using custom expression' do
        result = processor.process(node, context)

        valid_data = result[:outputs]['valid']
        expect(valid_data.size).to eq(2) # Header + 1 valid row
        expect(valid_data[1][1]).to eq('Password123')
      end
    end

    context 'with strict vs tolerant mode' do
      let(:node) do
        {
          'id' => 'validation-1',
          'type' => 'validation',
          'data' => {
            'validationMode' => 'strict',
            'validationRules' => [
              {
                'id' => '1',
                'field' => 'value',
                'type' => 'range',
                'min' => 0,
                'max' => 100
              }
            ]
          }
        }
      end

      let(:input_data) do
        [
          ['id', 'value'],
          ['1', '50'],
          ['2', '150'],  # Invalid
          ['3', '75'],
          ['4', '200']   # Invalid
        ]
      end

      let(:context) do
        { 'input-1' => input_data }
      end

      it 'strict mode stops on first error' do
        result = processor.process(node, context)

        # In strict mode, should process until first error
        # Row 1 is valid, Row 2 is invalid and triggers stop
        valid_data = result[:outputs]['valid']
        invalid_data = result[:outputs]['invalid']

        expect(valid_data.size).to eq(2) # Header + row 1
        expect(invalid_data.size).to eq(2) # Header + row 2
        expect(result[:statistics][:totalRecords]).to eq(2) # Only processed 2 rows
      end

      it 'tolerant mode processes all rows' do
        node['data']['validationMode'] = 'tolerant'
        result = processor.process(node, context)

        # In tolerant mode, processes all rows
        expect(result[:statistics][:totalRecords]).to eq(4)
        expect(result[:statistics][:validRecords]).to eq(2)
        expect(result[:statistics][:invalidRecords]).to eq(2)
      end
    end

    context 'error handling' do
      let(:node) do
        {
          'id' => 'validation-1',
          'type' => 'validation',
          'data' => {
            'validationMode' => 'strict',
            'validationRules' => []
          }
        }
      end

      it 'handles missing input data' do
        result = processor.process(node, {})

        expect(result[:success]).to be false
        expect(result[:error]).to include('Missing input data')
      end

      it 'handles empty validation rules' do
        context = { 'input-1' => [['id'], ['1']] }
        result = processor.process(node, context)

        expect(result[:success]).to be false
        expect(result[:error]).to include('No validation rules specified')
      end

      it 'handles missing field' do
        node['data']['validationRules'] = [
          {
            'id' => '1',
            'field' => 'non_existent',
            'type' => 'required'
          }
        ]
        context = { 'input-1' => [['id', 'name'], ['1', 'Test']] }

        result = processor.process(node, context)

        expect(result[:success]).to be false
        expect(result[:error]).to include('Field not found')
      end

      it 'handles invalid validation type' do
        node['data']['validationRules'] = [
          {
            'id' => '1',
            'field' => 'value',
            'type' => 'invalid_type'
          }
        ]
        context = { 'input-1' => [['value'], ['test']] }

        result = processor.process(node, context)

        expect(result[:success]).to be false
        expect(result[:error]).to include('Unsupported validation type')
      end
    end
  end
end