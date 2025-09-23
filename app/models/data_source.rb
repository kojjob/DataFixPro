class DataSource < ApplicationRecord
  belongs_to :tenant

  acts_as_tenant :tenant

  # Validations
  validates :name, presence: true
  validates :connection_type, presence: true, inclusion: { in: %w[postgresql mysql] }
  validates :host, presence: true
  validates :database_name, presence: true

  # Encrypt password using Rails built-in encryption
  encrypts :password, deterministic: false

  # Default values
  after_initialize :set_defaults, if: :new_record?

  # Scopes
  scope :postgresql, -> { where(connection_type: 'postgresql') }
  scope :mysql, -> { where(connection_type: 'mysql') }
  scope :connected, -> { where(connection_status: 'connected') }
  scope :failed, -> { where(connection_status: 'failed') }

  # Instance methods
  def connected?
    connection_status == 'connected'
  end

  def failed?
    connection_status == 'failed'
  end

  def disconnected?
    connection_status == 'disconnected'
  end

  # Get the appropriate connector based on connection type
  def connector
    case connection_type
    when 'postgresql'
      Connectors::PostgresqlConnector.new(self)
    when 'mysql'
      Connectors::MysqlConnector.new(self)
    else
      raise NotImplementedError, "Connector not implemented for #{connection_type}"
    end
  end

  private

  def set_defaults
    self.connection_status ||= 'disconnected'
    self.connection_errors ||= []
    self.connection_options ||= {}
  end
end