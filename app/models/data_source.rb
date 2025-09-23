class DataSource < ApplicationRecord
  acts_as_tenant :tenant

  belongs_to :tenant
  has_many :pipelines, dependent: :destroy

  validates :name, presence: true
  validates :connection_type, presence: true, inclusion: { in: %w[postgresql mysql sqlite redis elasticsearch] }
  validates :host, presence: true
  validates :database_name, presence: true

  scope :connected, -> { where(connection_status: 'connected') }
  scope :disconnected, -> { where(connection_status: 'disconnected') }

  def connected?
    connection_status == 'connected'
  end

  def disconnected?
    connection_status == 'disconnected'
  end

  def connector
    @connector ||= case connection_type
                   when 'postgresql'
                     PostgresqlConnector.new(self)
                   when 'mysql'
                     MysqlConnector.new(self)
                   when 'sqlite'
                     SqliteConnector.new(self)
                   when 'redis'
                     RedisConnector.new(self)
                   when 'elasticsearch'
                     ElasticsearchConnector.new(self)
                   else
                     raise "Unsupported connection type: #{connection_type}"
                   end
  end

  def test_connection
    connector.test_connection
  rescue => e
    update(
      connection_status: 'disconnected',
      connection_errors: [e.message]
    )
    false
  end
end