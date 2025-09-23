# MCP (Model Context Protocol) Server Configuration

## Overview
This document tracks all MCP servers configured globally for enhanced development capabilities.

## Active MCP Servers

### 1. Firecrawl
- **Purpose**: Web scraping and data extraction
- **Status**: ✅ Connected
- **API Key**: Configured (fc-709770a6e3fe4fe68009dda5c2ec6a9d)
- **Use Cases**:
  - Scraping data sources for ETL pipelines
  - Extracting structured data from websites
  - Automated data collection

### 2. PostgreSQL
- **Purpose**: Direct database access and management
- **Status**: ✅ Connected
- **Connection**: postgres://localhost/
- **Use Cases**:
  - Database schema management
  - Query optimization
  - Data migration testing
  - Multi-tenant architecture management

### 3. GitHub
- **Purpose**: Repository management and automation
- **Status**: ✅ Connected
- **Use Cases**:
  - Automated PR creation
  - Issue tracking
  - Code review automation
  - Repository statistics

### 4. Memory
- **Purpose**: Persistent context across sessions
- **Status**: ✅ Connected
- **Use Cases**:
  - Maintaining project context
  - Remembering configurations
  - Tracking development decisions
  - Cross-session continuity

### 5. Filesystem
- **Purpose**: Enhanced file operations
- **Status**: ✅ Connected
- **Root Path**: /Users/kojo
- **Use Cases**:
  - Bulk file operations
  - Project navigation
  - File search and analysis
  - Code generation

### 6. Puppeteer
- **Purpose**: Browser automation and testing
- **Status**: ✅ Connected
- **Use Cases**:
  - E2E testing
  - Web scraping for connectors
  - UI automation
  - Screenshot generation

### 7. Brave Search
- **Purpose**: Web search capabilities
- **Status**: ✅ Connected
- **API Key**: BSASurPy8OQ7yaEBoL24GLzQtLrCPw7
- **Use Cases**:
  - Documentation search
  - Solution research
  - API documentation lookup
  - Competitive analysis

## Configuration Commands

### Adding MCP Servers Globally
```bash
# Add to global user configuration (available in all projects)
claude mcp add --scope user <name> <command> [options]

# With environment variables
claude mcp add --scope user <name> <command> -e KEY=value

# With specific transport
claude mcp add --scope user <name> <command> -t http
```

### Managing MCP Servers
```bash
# List all configured servers
claude mcp list

# Remove a server
claude mcp remove --scope user <name>

# Check server health
claude mcp list  # Shows connection status
```

## Removed/Unused Servers

### Fetch
- **Reason**: Failed to connect without specific configuration
- **Alternative**: Use Puppeteer or Brave Search for web requests

### Slack
- **Reason**: Requires Slack bot token and team ID
- **Future**: Can be added when Slack integration is needed

## Best Practices

1. **Global vs Local Configuration**
   - Use `--scope user` for tools needed across all projects
   - Use default (local) scope for project-specific tools

2. **Security**
   - Store API keys in environment variables when possible
   - Never commit API keys to version control
   - Rotate keys regularly

3. **Performance**
   - Only add MCPs that you actively use
   - Remove non-functioning MCPs to reduce overhead
   - Monitor connection status regularly

## Troubleshooting

### Server Won't Connect
1. Check if required dependencies are installed
2. Verify API keys or credentials
3. Check network connectivity
4. Review server logs with `--verbose` flag

### Performance Issues
1. Remove unused MCP servers
2. Check for duplicate configurations
3. Restart Claude Code after configuration changes

## Future Additions

Consider adding these MCPs based on project needs:
- **Docker**: For container management
- **Kubernetes**: For orchestration
- **AWS**: For cloud services integration
- **Elasticsearch**: For search functionality
- **Redis**: For caching operations

---

*Last Updated: September 2025*
*Maintained by: Kojo's Development Environment*