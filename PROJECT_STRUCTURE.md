# DataFixPro - Enterprise Analytics Platform

## Project Overview

DataFixPro is a comprehensive enterprise analytics platform built with Ruby on Rails 8, featuring:
- Multi-tenant SaaS architecture
- Visual and code-based ETL/ELT pipeline builders
- 100+ data source connectors
- Real-time dashboards with drag-and-drop interface
- AI-powered predictive analytics
- White-label capabilities
- Mobile app support

## Technology Stack

### Backend
- **Framework**: Ruby on Rails 8.1.0.beta1 (with Solid Stack)
- **Database**: PostgreSQL (primary) + TimescaleDB (time-series data)
- **Cache**: Redis + Solid Cache (disk-based)
- **Background Jobs**: Solid Queue (database-backed)
- **WebSockets**: Solid Cable (database-backed)
- **Search**: Elasticsearch via Searchkick
- **File Storage**: Active Storage with S3

### Frontend
- **JavaScript**: Hotwire (Turbo + Stimulus) with Import Maps
- **CSS**: Tailwind CSS
- **Components**: ViewComponent + Lookbook
- **Charts**: Chartkick
- **Visual Builder**: React Flow (for ETL pipelines)

### ETL/ELT Engine
- **Processing**: Custom Ruby workers with parallel processing
- **Scheduling**: Whenever + Rufus Scheduler
- **Data Import**: ActiveRecord Import, Roo, Creek
- **Transformations**: Custom transformation operators

### AI/ML
- **Integration**: OpenAI API
- **Vector Search**: Neighbor + pgvector
- **Token Counting**: Tiktoken

### Deployment
- **Tool**: Kamal 2.0
- **Proxy**: Thruster (HTTP/2)
- **Server**: Puma
- **Monitoring**: Skylight, Rollbar, New Relic

## Project File Structure

```
DataFixPro/
├── app/
│   ├── controllers/
│   │   ├── api/
│   │   │   ├── v1/
│   │   │   │   ├── base_controller.rb
│   │   │   │   ├── auth_controller.rb
│   │   │   │   ├── data_sources_controller.rb
│   │   │   │   ├── dashboards_controller.rb
│   │   │   │   ├── pipelines_controller.rb
│   │   │   │   ├── webhooks_controller.rb
│   │   │   │   └── organizations_controller.rb
│   │   │   └── v2/
│   │   ├── admin/
│   │   │   ├── base_controller.rb
│   │   │   ├── tenants_controller.rb
│   │   │   ├── users_controller.rb
│   │   │   └── subscriptions_controller.rb
│   │   ├── application_controller.rb
│   │   ├── dashboards_controller.rb
│   │   ├── data_sources_controller.rb
│   │   ├── pipelines_controller.rb
│   │   ├── reports_controller.rb
│   │   ├── settings_controller.rb
│   │   └── webhooks_controller.rb
│   │
│   ├── models/
│   │   ├── concerns/
│   │   │   ├── tenantable.rb
│   │   │   ├── auditable.rb
│   │   │   ├── encryptable.rb
│   │   │   └── searchable.rb
│   │   ├── tenant.rb
│   │   ├── organization.rb
│   │   ├── user.rb
│   │   ├── role.rb
│   │   ├── permission.rb
│   │   ├── data_source.rb
│   │   ├── connector.rb
│   │   ├── connection.rb
│   │   ├── pipeline.rb
│   │   ├── pipeline_step.rb
│   │   ├── transformation.rb
│   │   ├── schedule.rb
│   │   ├── dashboard.rb
│   │   ├── widget.rb
│   │   ├── chart.rb
│   │   ├── metric.rb
│   │   ├── alert.rb
│   │   ├── report.rb
│   │   ├── subscription.rb
│   │   ├── plan.rb
│   │   ├── invoice.rb
│   │   ├── webhook.rb
│   │   ├── audit_log.rb
│   │   ├── api_key.rb
│   │   └── white_label_config.rb
│   │
│   ├── services/
│   │   ├── etl/
│   │   │   ├── pipeline_executor.rb
│   │   │   ├── data_extractor.rb
│   │   │   ├── data_transformer.rb
│   │   │   ├── data_loader.rb
│   │   │   ├── schedule_manager.rb
│   │   │   └── error_handler.rb
│   │   ├── connectors/
│   │   │   ├── base_connector.rb
│   │   │   ├── salesforce_connector.rb
│   │   │   ├── hubspot_connector.rb
│   │   │   ├── google_analytics_connector.rb
│   │   │   ├── stripe_connector.rb
│   │   │   ├── shopify_connector.rb
│   │   │   ├── quickbooks_connector.rb
│   │   │   ├── database_connector.rb
│   │   │   ├── api_connector.rb
│   │   │   ├── csv_connector.rb
│   │   │   └── s3_connector.rb
│   │   ├── analytics/
│   │   │   ├── metric_calculator.rb
│   │   │   ├── aggregation_service.rb
│   │   │   ├── forecasting_service.rb
│   │   │   ├── anomaly_detector.rb
│   │   │   └── report_generator.rb
│   │   ├── ai/
│   │   │   ├── prediction_service.rb
│   │   │   ├── natural_language_processor.rb
│   │   │   ├── insight_generator.rb
│   │   │   ├── roi_optimizer.rb
│   │   │   └── data_quality_analyzer.rb
│   │   ├── auth/
│   │   │   ├── authentication_service.rb
│   │   │   ├── jwt_service.rb
│   │   │   ├── oauth_service.rb
│   │   │   └── permission_service.rb
│   │   └── billing/
│   │       ├── subscription_service.rb
│   │       ├── invoice_service.rb
│   │       ├── usage_tracker.rb
│   │       └── payment_processor.rb
│   │
│   ├── jobs/
│   │   ├── application_job.rb
│   │   ├── etl/
│   │   │   ├── pipeline_job.rb
│   │   │   ├── data_sync_job.rb
│   │   │   ├── transformation_job.rb
│   │   │   └── cleanup_job.rb
│   │   ├── analytics/
│   │   │   ├── metric_calculation_job.rb
│   │   │   ├── report_generation_job.rb
│   │   │   └── alert_check_job.rb
│   │   ├── notifications/
│   │   │   ├── email_notification_job.rb
│   │   │   ├── webhook_delivery_job.rb
│   │   │   └── push_notification_job.rb
│   │   └── maintenance/
│   │       ├── data_cleanup_job.rb
│   │       ├── cache_warming_job.rb
│   │       └── backup_job.rb
│   │
│   ├── views/
│   │   ├── components/
│   │   │   ├── dashboard/
│   │   │   ├── charts/
│   │   │   ├── forms/
│   │   │   ├── navigation/
│   │   │   └── shared/
│   │   ├── layouts/
│   │   │   ├── application.html.erb
│   │   │   ├── admin.html.erb
│   │   │   ├── authentication.html.erb
│   │   │   └── white_label.html.erb
│   │   └── [controller_views]/
│   │
│   ├── javascript/
│   │   ├── controllers/
│   │   │   ├── dashboard_controller.js
│   │   │   ├── chart_controller.js
│   │   │   ├── pipeline_builder_controller.js
│   │   │   ├── drag_drop_controller.js
│   │   │   ├── filter_controller.js
│   │   │   └── realtime_controller.js
│   │   └── application.js
│   │
│   ├── assets/
│   │   ├── stylesheets/
│   │   │   ├── application.tailwind.css
│   │   │   └── components/
│   │   └── images/
│   │
│   └── api/
│       ├── base.rb
│       ├── v1/
│       │   ├── root.rb
│       │   ├── auth.rb
│       │   ├── data_sources.rb
│       │   ├── pipelines.rb
│       │   └── dashboards.rb
│       └── entities/
│           ├── user_entity.rb
│           ├── dashboard_entity.rb
│           └── pipeline_entity.rb
│
├── config/
│   ├── application.rb
│   ├── database.yml
│   ├── routes.rb
│   ├── cable.yml
│   ├── storage.yml
│   ├── environments/
│   │   ├── development.rb
│   │   ├── test.rb
│   │   └── production.rb
│   ├── initializers/
│   │   ├── acts_as_tenant.rb
│   │   ├── devise.rb
│   │   ├── cors.rb
│   │   ├── solid_queue.rb
│   │   ├── solid_cache.rb
│   │   ├── solid_cable.rb
│   │   ├── grape.rb
│   │   ├── searchkick.rb
│   │   ├── rack_attack.rb
│   │   └── sidekiq.rb
│   ├── locales/
│   └── schedule.rb (whenever)
│
├── db/
│   ├── migrate/
│   │   ├── 001_enable_extensions.rb
│   │   ├── 002_create_tenants.rb
│   │   ├── 003_create_organizations.rb
│   │   ├── 004_create_users.rb
│   │   ├── 005_create_roles_and_permissions.rb
│   │   ├── 006_create_data_sources.rb
│   │   ├── 007_create_connectors.rb
│   │   ├── 008_create_pipelines.rb
│   │   ├── 009_create_dashboards.rb
│   │   ├── 010_create_widgets.rb
│   │   ├── 011_create_subscriptions.rb
│   │   └── [more migrations...]
│   ├── schema.rb
│   └── seeds/
│       ├── development.rb
│       ├── production.rb
│       └── demo_data.rb
│
├── lib/
│   ├── etl/
│   │   ├── operators/
│   │   ├── transformers/
│   │   └── validators/
│   ├── connectors/
│   │   └── adapters/
│   ├── analytics/
│   │   └── algorithms/
│   └── tasks/
│       ├── etl.rake
│       ├── analytics.rake
│       └── maintenance.rake
│
├── spec/ (or test/)
│   ├── models/
│   ├── controllers/
│   ├── services/
│   ├── jobs/
│   ├── api/
│   ├── features/
│   ├── support/
│   └── factories/
│
├── docker/
│   ├── Dockerfile
│   ├── docker-compose.yml
│   ├── docker-compose.production.yml
│   └── .dockerignore
│
├── .kamal/
│   ├── config.yml
│   └── hooks/
│
├── public/
│   ├── assets/
│   └── uploads/
│
├── vendor/
│   └── javascript/
│       └── react-flow/ (for visual builder)
│
├── Gemfile
├── Gemfile.lock
├── package.json
├── Procfile.dev
├── README.md
├── .env.example
├── .rubocop.yml
├── .rspec
└── .gitignore
```

## Key Features Implementation

### 1. Multi-Tenant Architecture
- Database-level isolation using `acts_as_tenant`
- Tenant-specific subdomains
- Data segregation and security
- Resource usage tracking per tenant

### 2. ETL/ELT Pipeline System
- **Visual Builder**: Drag-and-drop interface using React Flow
- **Code Builder**: Ruby DSL for pipeline definitions
- **100+ Connectors**: Pre-built integrations
- **Transformations**: 50+ built-in operators
- **Scheduling**: Cron-based and event-driven
- **Error Handling**: Retry mechanisms and alerting

### 3. Real-Time Dashboards
- **Drag-and-Drop**: Visual dashboard builder
- **20+ Chart Types**: Line, bar, pie, heatmap, etc.
- **Live Updates**: WebSocket-based real-time data
- **Filters**: Interactive filtering and drill-down
- **Export**: PDF, Excel, CSV exports

### 4. AI/ML Integration
- **Predictive Analytics**: Sales forecasting, churn prediction
- **Anomaly Detection**: Automatic outlier identification
- **Natural Language**: Query data using plain English
- **Insights**: Automated insight generation
- **ROI Optimization**: Budget allocation recommendations

### 5. Security & Compliance
- **Encryption**: Bank-level encryption at rest and in transit
- **GDPR**: Full compliance with data privacy regulations
- **SOC2**: Compliance framework implementation
- **RBAC**: Role-based access control
- **Audit Logs**: Complete activity tracking
- **API Security**: Rate limiting, JWT authentication

### 6. White-Label System
- **Custom Branding**: Logo, colors, fonts
- **Custom Domains**: Tenant-specific domains
- **Theme Engine**: Customizable UI themes
- **Email Templates**: Branded email communications

### 7. Subscription & Billing
- **Plans**: Starter ($99), Professional ($299), Enterprise (Custom)
- **Usage Tracking**: API calls, data volume, users
- **Invoicing**: Automated billing and receipts
- **Payment Processing**: Stripe integration

## API Structure

### RESTful API
```
/api/v1/
  /auth
    POST /login
    POST /logout
    POST /refresh
  /data_sources
    GET /
    POST /
    GET /:id
    PUT /:id
    DELETE /:id
    POST /:id/test_connection
  /pipelines
    GET /
    POST /
    GET /:id
    PUT /:id
    DELETE /:id
    POST /:id/run
    GET /:id/logs
  /dashboards
    GET /
    POST /
    GET /:id
    PUT /:id
    DELETE /:id
    GET /:id/widgets
  /reports
    GET /
    POST /generate
    GET /:id/download
```

### GraphQL API
```graphql
type Query {
  user(id: ID!): User
  dashboard(id: ID!): Dashboard
  pipelines(status: PipelineStatus): [Pipeline!]!
  metrics(dashboardId: ID!, timeRange: TimeRange): [Metric!]!
}

type Mutation {
  createPipeline(input: PipelineInput!): Pipeline!
  runPipeline(id: ID!): PipelineRun!
  updateDashboard(id: ID!, input: DashboardInput!): Dashboard!
}

type Subscription {
  dashboardUpdates(id: ID!): DashboardUpdate!
  pipelineStatus(id: ID!): PipelineStatus!
}
```

## Database Schema (Key Tables)

### Core Tables
- `tenants` - Multi-tenant isolation
- `organizations` - Company accounts
- `users` - User accounts
- `roles` - User roles
- `permissions` - Granular permissions

### Data Pipeline Tables
- `data_sources` - External data connections
- `connectors` - Connector configurations
- `pipelines` - ETL/ELT pipeline definitions
- `pipeline_steps` - Individual pipeline steps
- `pipeline_runs` - Execution history
- `transformations` - Data transformation rules

### Analytics Tables
- `dashboards` - Dashboard configurations
- `widgets` - Dashboard widgets
- `charts` - Chart configurations
- `metrics` - Calculated metrics
- `reports` - Generated reports
- `alerts` - Alert configurations

### Subscription Tables
- `plans` - Subscription plans
- `subscriptions` - Active subscriptions
- `invoices` - Billing invoices
- `usage_records` - Resource usage tracking

## Environment Variables

```env
# Database
DATABASE_URL=postgresql://user:pass@localhost/dataflow_pro
REDIS_URL=redis://localhost:6379

# Rails
RAILS_ENV=production
RAILS_MASTER_KEY=xxx
SECRET_KEY_BASE=xxx

# AWS
AWS_ACCESS_KEY_ID=xxx
AWS_SECRET_ACCESS_KEY=xxx
AWS_REGION=us-east-1
S3_BUCKET=dataflow-pro

# External Services
STRIPE_PUBLISHABLE_KEY=xxx
STRIPE_SECRET_KEY=xxx
OPENAI_API_KEY=xxx
ELASTICSEARCH_URL=http://localhost:9200

# OAuth
GOOGLE_CLIENT_ID=xxx
GOOGLE_CLIENT_SECRET=xxx

# Email
SMTP_ADDRESS=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=xxx
SMTP_PASSWORD=xxx

# Monitoring
SKYLIGHT_AUTHENTICATION=xxx
ROLLBAR_ACCESS_TOKEN=xxx
NEW_RELIC_LICENSE_KEY=xxx
```

## Development Setup

```bash
# Clone repository
git clone https://github.com/your-org/dataflow-pro.git
cd dataflow-pro

# Install dependencies
bundle install
yarn install

# Setup database
rails db:create
rails db:migrate
rails db:seed

# Start services
docker-compose up -d redis elasticsearch postgres

# Start application
bin/dev

# Run tests
bundle exec rspec
```

## Deployment

### Using Kamal 2.0

```bash
# Setup servers
kamal setup

# Deploy
kamal deploy

# Rollback
kamal rollback

# Console access
kamal app exec 'rails console'
```

### Docker Deployment

```bash
# Build image
docker build -t dataflow-pro .

# Run container
docker run -p 3000:3000 dataflow-pro
```

## Testing Strategy

### Test Coverage Goals
- Models: 95%+
- Services: 90%+
- Controllers: 85%+
- API: 90%+
- Integration: 80%+

### Test Types
- Unit Tests (RSpec)
- Integration Tests (Capybara)
- API Tests (RSpec + Committee)
- Performance Tests (Apache Bench)
- Security Tests (Brakeman)

## Performance Optimization

### Caching Strategy
- Database queries: Solid Cache
- API responses: Redis
- Static assets: CDN
- Fragment caching: Russian Doll

### Database Optimization
- Indexes on foreign keys
- Composite indexes for queries
- Partitioning for time-series data
- Read replicas for analytics

### Background Processing
- Solid Queue for job processing
- Priority queues for critical jobs
- Scheduled jobs with Whenever
- Batch processing for large datasets

## Security Best Practices

### Application Security
- CSRF protection enabled
- Strong parameters enforced
- SQL injection prevention
- XSS protection headers
- Content Security Policy

### API Security
- JWT authentication
- API rate limiting
- Request signing
- IP whitelisting (optional)
- OAuth 2.0 support

### Data Security
- Encryption at rest (Lockbox)
- Encryption in transit (TLS 1.3)
- PII data masking
- Audit logging
- Regular security audits

## Monitoring & Observability

### Application Monitoring
- Skylight for performance
- Rollbar for error tracking
- New Relic for APM
- Custom dashboards

### Infrastructure Monitoring
- Server metrics (CPU, memory, disk)
- Database performance
- Redis metrics
- Elasticsearch health

### Business Metrics
- User activity tracking
- Feature usage analytics
- Revenue metrics
- Churn analysis

## Support & Documentation

### User Documentation
- Getting Started Guide
- API Documentation
- Video Tutorials
- Knowledge Base

### Developer Documentation
- Code Documentation (YARD)
- API Reference (Swagger)
- Architecture Diagrams
- Contribution Guidelines

## License & Legal

- License: Proprietary
- Terms of Service: /terms
- Privacy Policy: /privacy
- Data Processing Agreement: Available

## Contact

- Website: https://dataflowpro.com
- Support: support@dataflowpro.com
- Sales: sales@dataflowpro.com
- Documentation: https://docs.dataflowpro.com

---

This document serves as the comprehensive reference for the DataFixPro platform architecture and implementation.