source "https://rubygems.org"

ruby "3.4.3"

# Rails 8.1 Beta - Latest version with Solid Stack
gem "rails", "~> 8.1.0.beta1"

# Core Rails Components
gem "propshaft"                              # Modern asset pipeline
gem "pg", "~> 1.5"                          # PostgreSQL adapter
gem "puma", ">= 6.0"                        # Application server
gem "importmap-rails"                        # JavaScript with ESM import maps
gem "turbo-rails"                            # Hotwire's SPA-like functionality
gem "stimulus-rails"                         # Hotwire's JavaScript framework
gem "jsbundling-rails"                       # JavaScript bundling for React Flow
gem "tailwindcss-rails"                      # Tailwind CSS
gem "jbuilder"                               # JSON API builder

# Rails 8 Solid Stack
gem "solid_cache"                            # Database-backed caching
gem "solid_queue"                            # Database-backed job queue
gem "solid_cable"                            # Database-backed WebSockets

# Core Infrastructure
gem "bootsnap", require: false               # Boot time optimization
gem "kamal", require: false                  # Deployment tool
gem "thruster", require: false               # HTTP/2 proxy server
gem "tzinfo-data", platforms: %i[windows jruby]

# Database & Multi-tenancy
gem "redis", ">= 5.0"                        # Redis for additional caching
gem "connection_pool", "~> 2.4"              # Connection pooling
gem "acts_as_tenant", "~> 1.0"               # Multi-tenant support
gem "strong_migrations", "~> 1.7"            # Safe database migrations

# Authentication & Authorization
gem "bcrypt", "~> 3.1.7"                     # Password encryption
gem "devise", "~> 4.9"                       # Authentication solution
gem "pundit", "~> 2.3"                       # Authorization policies
gem "jwt", "~> 2.7"                          # JSON Web Tokens for API auth
gem "omniauth", "~> 2.1"                     # Multi-provider authentication
gem "omniauth-google-oauth2"                 # Google OAuth
gem "omniauth-rails_csrf_protection"         # CSRF protection

# API Development
gem "grape", "~> 2.0"                        # REST API framework
gem "grape-entity", "~> 1.0"                 # API entities
gem "grape-swagger", "~> 2.0"                # API documentation
gem "rack-cors", "~> 2.0"                    # CORS support
gem "jsonapi-serializer", "~> 2.2"          # Fast JSON serialization
gem "graphql", "~> 2.2"                      # GraphQL support

# Data Processing & ETL
gem "activerecord-import", "~> 1.5"          # Bulk data import
gem "parallel", "~> 1.24"                    # Parallel processing
gem "ruby-progressbar", "~> 1.13"            # Progress bars
gem "creek", "~> 2.6"                        # Fast Excel reader
gem "roo", "~> 2.10"                         # Excel/CSV processing

# Data Connectors (Essential ones)
gem "aws-sdk-s3", "~> 1.140"                 # AWS S3 integration
gem "stripe", "~> 10.0"                      # Stripe payments
gem "httparty", "~> 0.21"                    # HTTP client for APIs
gem "faraday", "~> 2.8"                      # HTTP client with middleware

# Analytics & Visualization
gem "groupdate", "~> 6.4"                    # Group temporal data
gem "chartkick", "~> 5.0"                    # Charts
gem "blazer", "~> 3.0"                       # Business intelligence
gem "ahoy_matey", "~> 5.0"                   # Analytics tracking

# Machine Learning & AI
gem "ruby-openai", "~> 6.0"                  # OpenAI integration
gem "tiktoken_ruby", "~> 0.0.7"              # Token counting
gem "neighbor", "~> 0.3"                     # Nearest neighbor search

# Search
gem "searchkick", "~> 5.3"                   # Elasticsearch integration

# File Processing
gem "image_processing", "~> 1.12"            # Image processing
gem "active_storage_validations", "~> 1.1"   # File validations

# UI Components
gem "view_component", "~> 3.7"               # Component-based views
gem "lookbook", "~> 2.2"                     # Component previews

# Admin & Monitoring
gem "rails_admin", "~> 3.1"                  # Admin interface
gem "paper_trail", "~> 15.1"                 # Audit trail
gem "lograge", "~> 0.14"                     # Better logging

# Security
gem "rack-attack", "~> 6.7"                  # Rate limiting
gem "lockbox", "~> 1.3"                      # Field encryption

# Performance
gem "oj", "~> 3.16"                          # Fast JSON parser
gem "rack-mini-profiler", "~> 3.3"           # Performance profiling

# Utilities
gem "friendly_id", "~> 5.5"                  # SEO-friendly URLs
gem "kaminari", "~> 1.2"                     # Pagination
gem "ransack", "~> 4.1"                      # Advanced search
gem "aasm", "~> 5.5"                         # State machines
gem "dry-validation", "~> 1.10"              # Data validation
gem "interactor", "~> 3.1"                   # Service objects
gem "whenever", "~> 1.0", require: false     # Cron jobs
gem "config", "~> 5.0"                       # Application configuration
gem "sitemap_generator", "~> 6.3"            # SEO sitemaps

group :development, :test do
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"
  gem "bundler-audit", require: false
  gem "brakeman", require: false
  gem "rubocop-rails-omakase", require: false

  # Testing
  gem "rspec-rails", "~> 6.1"
  gem "factory_bot_rails", "~> 6.4"
  gem "faker", "~> 3.2"
  gem "shoulda-matchers", "~> 6.0"
  gem "database_cleaner-active_record", "~> 2.1"
end

group :development do
  gem "web-console"
  gem "letter_opener", "~> 1.8"
  # gem "bullet", "~> 7.1"  # Not compatible with Rails 8.1 yet
  # gem "annotate", "~> 3.2"  # Not compatible with Rails 8.1 yet
  gem "better_errors", "~> 2.10"
  gem "binding_of_caller", "~> 1.0"
end

group :test do
  gem "capybara", "~> 3.39"
  gem "selenium-webdriver", "~> 4.16"
  gem "simplecov", "~> 0.22", require: false
  gem "webmock", "~> 3.19"
  gem "vcr", "~> 6.2"
  gem "timecop", "~> 0.9"
end
