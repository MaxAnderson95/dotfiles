---
name: dash0-querying
description: Create Dash0 dashboards, alerts, and PromQL queries for OpenTelemetry metrics. Covers PersesDashboard YAML format, Dash0FilterVariable syntax, panel types (TimeSeriesChart, GaugeChart, StatChart), and OTel metric naming conventions.
---

## What I do

- Create Dash0 dashboards in PersesDashboard YAML format
- Write PromQL queries for OpenTelemetry metrics using `otel_metric_name` selectors
- Configure dashboard variables using `Dash0FilterVariable` (NOT standard Perses `ListVariable`)
- Build panels: TimeSeriesChart, GaugeChart, StatChart, Markdown
- Define alert rules with proper thresholds and annotations
- Query Kubernetes metrics (k8s.node.*, k8s.pod.*), system metrics (system.*), and Azure metrics (azure_*)

## When to use me

Use this skill when:
- Creating or modifying Dash0 dashboards
- Writing PromQL queries for OpenTelemetry-collected metrics
- Setting up alerts in Dash0
- Troubleshooting why dashboard variables or queries aren't working
- Converting Grafana dashboards to Dash0 format

Do NOT use standard Perses documentation - Dash0 has custom extensions that differ significantly.

---

# Dash0 Querying Skill

This skill covers creating dashboards, alerts, and PromQL queries in Dash0.

## Overview

Dash0 uses a modified version of [Perses](https://perses.dev/) for dashboards with custom extensions. The key differences from standard Perses:

1. **Variables**: Use `Dash0FilterVariable` instead of standard Perses `ListVariable`
2. **Metric Selection**: Use `otel_metric_name` and `otel_metric_type` label selectors
3. **Variable Interpolation**: Use `$variable_name` directly in PromQL queries

---

## Dashboard Structure

Dash0 dashboards are defined as `PersesDashboard` resources in YAML:

```yaml
apiVersion: perses.dev/v1alpha1
kind: PersesDashboard
metadata:
  name: my-dashboard
spec:
  duration: 1h          # Default time range
  display:
    name: My Dashboard  # Display name in UI
  variables: []         # Dashboard variables (filters)
  layouts: []           # Panel layout grid
  panels: {}            # Panel definitions
```

---

## Variables (Dash0FilterVariable)

**IMPORTANT**: Dash0 uses `Dash0FilterVariable`, NOT standard Perses `ListVariable`.

### Syntax

```yaml
variables:
  - kind: Dash0FilterVariable
    spec:
      attributeKey: k8s_cluster_name    # The OTel attribute to filter on
      capturingRegexp: ""               # Optional regex for value extraction
      display:
        description: ""
        hidden: false
        name: "Cluster"                 # Display label in UI
      name: k8s_cluster_name            # Variable name (used in queries as $k8s_cluster_name)
      operator: is_any                  # Filter operator
      values: []                        # Pre-selected values (empty = all)
```

### Using Variables in Queries

Reference variables with `$variable_name` directly in the label selector:

```promql
{otel_metric_name="k8s.node.cpu.usage", $k8s_cluster_name}
```

This automatically expands to the appropriate label matcher based on user selection.

### Common Variable Patterns

```yaml
# Cluster filter
- kind: Dash0FilterVariable
  spec:
    attributeKey: k8s_cluster_name
    name: k8s_cluster_name
    operator: is_any
    values: []

# Namespace filter
- kind: Dash0FilterVariable
  spec:
    attributeKey: k8s_namespace_name
    name: k8s_namespace_name
    operator: is_any
    values: []

# Service filter
- kind: Dash0FilterVariable
  spec:
    attributeKey: service_name
    name: service_name
    operator: is_any
    values: []
```

---

## Layouts (Grid System)

Dashboards use a 24-column grid system:

```yaml
layouts:
  - kind: Grid
    spec:
      items:
        - content:
            $ref: "#/spec/panels/my-panel"  # Reference to panel definition
          height: 8    # Height in grid units
          width: 12    # Width (out of 24 columns)
          x: 0         # X position (0-23)
          "y": 0       # Y position (quote "y" to avoid YAML issues)
```

### Common Layout Patterns

```yaml
# Full-width panel
- content:
    $ref: "#/spec/panels/panel-name"
  height: 8
  width: 24
  x: 0
  "y": 0

# Two panels side by side
- content:
    $ref: "#/spec/panels/left-panel"
  height: 8
  width: 12
  x: 0
  "y": 0
- content:
    $ref: "#/spec/panels/right-panel"
  height: 8
  width: 12
  x: 12
  "y": 0

# Four panels in a row (stat cards)
- content:
    $ref: "#/spec/panels/stat1"
  height: 4
  width: 6
  x: 0
  "y": 0
- content:
    $ref: "#/spec/panels/stat2"
  height: 4
  width: 6
  x: 6
  "y": 0
# ... etc
```

---

## Panel Types

### TimeSeriesChart

For time-series line/area charts:

```yaml
panels:
  cpu-usage:
    kind: Panel
    spec:
      display:
        name: CPU Usage
      plugin:
        kind: TimeSeriesChart
        spec:
          visual:
            areaOpacity: 0.3        # 0 = line only, 1 = solid fill
            display: line           # line, bar
            lineWidth: 1.5
            palette:
              mode: auto
          yAxis:
            format:
              unit: percent         # percent, bytes, decimal, etc.
              decimalPlaces: 2
            min: 0
            max: 100               # Optional max
      queries:
        - kind: TimeSeriesQuery
          spec:
            plugin:
              kind: PrometheusTimeSeriesQuery
              spec:
                query: '{otel_metric_name="system.cpu.utilization", $k8s_cluster_name} * 100'
                seriesNameFormat: "{{k8s_node_name}}"
```

### GaugeChart

For single-value gauges with thresholds:

```yaml
panels:
  memory-gauge:
    kind: Panel
    spec:
      display:
        name: Memory Usage
      plugin:
        kind: GaugeChart
        spec:
          calculation: last        # last, mean, max, min, sum
          format:
            unit: percent
            decimalPlaces: 0
          max: 100                 # Gauge maximum
          thresholds:
            steps:
              - color: "#22c55e"   # Green
                value: 0
              - color: "#eab308"   # Yellow
                value: 70
              - color: "#ef4444"   # Red
                value: 90
      queries:
        - kind: TimeSeriesQuery
          spec:
            plugin:
              kind: PrometheusTimeSeriesQuery
              spec:
                query: 'avg({otel_metric_name="system.memory.utilization", $k8s_cluster_name}) * 100'
                seriesNameFormat: "Memory"
```

### StatChart

For simple single-value statistics:

```yaml
panels:
  node-count:
    kind: Panel
    spec:
      display:
        name: Node Count
      plugin:
        kind: StatChart
        spec:
          calculation: last
          format:
            unit: decimal
      queries:
        - kind: TimeSeriesQuery
          spec:
            plugin:
              kind: PrometheusTimeSeriesQuery
              spec:
                query: 'count({otel_metric_name="k8s.node.condition_ready", $k8s_cluster_name})'
                seriesNameFormat: "Nodes"
```

### Markdown

For section headers and documentation:

```yaml
panels:
  section-header:
    kind: Panel
    spec:
      display:
        name: "Section Title"
      plugin:
        kind: Markdown
        spec:
          text: |
            Description text here. Supports **markdown** formatting.
```

---

## Unit Formats

Common unit values for `format.unit`:

| Unit | Description |
|------|-------------|
| `percent` | Percentage (0-100) |
| `percentunit` | Percentage as decimal (0-1) |
| `bytes` | Bytes (auto-scales to KB, MB, GB) |
| `decbytes` | Decimal bytes |
| `bits` | Bits |
| `decimal` | Plain number |
| `short` | Short number format |
| `seconds` | Duration in seconds |
| `milliseconds` | Duration in milliseconds |

---

## PromQL for OpenTelemetry Metrics

### Metric Selection

OTel metrics are stored with special labels. Always use `otel_metric_name` to select metrics:

```promql
# Basic metric selection
{otel_metric_name="k8s.node.cpu.usage"}

# With metric type filter (useful when metric names collide)
{otel_metric_name="k8s.node.cpu.usage", otel_metric_type="gauge"}

# With variable filter
{otel_metric_name="k8s.node.cpu.usage", $k8s_cluster_name}
```

### Label Naming

OTel attributes become Prometheus labels with dots replaced by underscores:

| OTel Attribute | Prometheus Label |
|----------------|------------------|
| `k8s.cluster.name` | `k8s_cluster_name` |
| `k8s.node.name` | `k8s_node_name` |
| `k8s.namespace.name` | `k8s_namespace_name` |
| `k8s.pod.name` | `k8s_pod_name` |
| `service.name` | `service_name` |
| `system.filesystem.mountpoint` | `system_filesystem_mountpoint` |

### Common Metric Sources

#### Kubelet Stats Receiver (`k8s.*` metrics)
From the Kubernetes Kubelet API:

```promql
# Node CPU
{otel_metric_name="k8s.node.cpu.usage"}           # CPU cores used
{otel_metric_name="k8s.node.cpu.time"}            # Cumulative CPU time (use rate())

# Node Memory
{otel_metric_name="k8s.node.memory.usage"}        # Memory bytes used
{otel_metric_name="k8s.node.memory.available"}    # Memory bytes available
{otel_metric_name="k8s.node.memory.working_set"}  # Working set bytes

# Node Filesystem
{otel_metric_name="k8s.node.filesystem.usage"}    # Filesystem bytes used
{otel_metric_name="k8s.node.filesystem.capacity"} # Filesystem total capacity
{otel_metric_name="k8s.node.filesystem.available"}# Filesystem bytes available

# Node Network
{otel_metric_name="k8s.node.network.io"}          # Network bytes (has direction label)
{otel_metric_name="k8s.node.network.errors"}      # Network errors (has direction label)

# Node Conditions
{otel_metric_name="k8s.node.condition_ready"}     # 1 = ready, 0 = not ready

# Pod metrics
{otel_metric_name="k8s.pod.cpu.usage"}
{otel_metric_name="k8s.pod.memory.usage"}

# Container metrics
{otel_metric_name="k8s.container.cpu.usage"}
{otel_metric_name="k8s.container.memory.usage"}
```

#### Host Metrics Receiver (`system.*` metrics)
From direct host scraping:

```promql
# CPU (as ratio 0-1)
{otel_metric_name="system.cpu.utilization"}       # Multiply by 100 for percentage

# Memory (as ratio 0-1)
{otel_metric_name="system.memory.utilization"}

# Filesystem (as ratio 0-1, has mountpoint label)
{otel_metric_name="system.filesystem.utilization"}

# Network
{otel_metric_name="system.network.io"}
{otel_metric_name="system.network.errors"}
```

#### Azure Monitor Receiver (`azure_*` metrics)
From Azure Monitor API:

```promql
# AKS API Server
{otel_metric_name="azure_apiserver_cpu_usage_percentage_average"}
{otel_metric_name="azure_apiserver_memory_usage_percentage_average"}
{otel_metric_name="azure_apiserver_current_inflight_requests_average"}

# AKS etcd
{otel_metric_name="azure_etcd_cpu_usage_percentage_average"}
{otel_metric_name="azure_etcd_memory_usage_percentage_average"}
{otel_metric_name="azure_etcd_database_usage_percentage_average"}
```

### Common Query Patterns

```promql
# Rate of counter metrics
rate({otel_metric_name="k8s.node.cpu.time", $k8s_cluster_name}[$__rate_interval])

# Aggregation across series
sum by (k8s_cluster_name) ({otel_metric_name="k8s.node.memory.usage", $k8s_cluster_name})
avg by (k8s_node_name) ({otel_metric_name="system.cpu.utilization", $k8s_cluster_name})

# Percentage calculation
sum({otel_metric_name="k8s.node.memory.usage", $k8s_cluster_name}) / 
(sum({otel_metric_name="k8s.node.memory.usage", $k8s_cluster_name}) + 
 sum({otel_metric_name="k8s.node.memory.available", $k8s_cluster_name})) * 100

# Count unique series
count({otel_metric_name="k8s.node.condition_ready", $k8s_cluster_name})

# Convert ratio to percentage
{otel_metric_name="system.cpu.utilization", $k8s_cluster_name} * 100
```

### Series Name Formatting

Use `seriesNameFormat` with `{{label_name}}` to customize legend labels:

```yaml
seriesNameFormat: "{{k8s_node_name}}"
seriesNameFormat: "{{k8s_node_name}} - {{direction}}"
seriesNameFormat: "{{k8s_cluster_name}}"
seriesNameFormat: "{{k8s_node_name}} ({{system_filesystem_mountpoint}})"
```

---

## Alerting

### Alert Rule Structure

```yaml
apiVersion: perses.dev/v1alpha1
kind: PersesAlert
metadata:
  name: high-cpu-usage
spec:
  display:
    name: High CPU Usage Alert
  rules:
    - name: high-cpu
      expr: 'avg({otel_metric_name="system.cpu.utilization"}) * 100 > 90'
      for: 5m
      labels:
        severity: warning
      annotations:
        summary: "High CPU usage detected"
        description: "CPU usage is above 90% for more than 5 minutes"
```

### Common Alert Patterns

```yaml
# Node not ready
- name: node-not-ready
  expr: '{otel_metric_name="k8s.node.condition_ready"} == 0'
  for: 5m
  labels:
    severity: critical
  annotations:
    summary: "Kubernetes node not ready"
    description: "Node {{ $labels.k8s_node_name }} is not ready"

# High memory usage
- name: high-memory
  expr: |
    sum by (k8s_node_name) ({otel_metric_name="k8s.node.memory.usage"}) /
    (sum by (k8s_node_name) ({otel_metric_name="k8s.node.memory.usage"}) +
     sum by (k8s_node_name) ({otel_metric_name="k8s.node.memory.available"})) * 100 > 90
  for: 10m
  labels:
    severity: warning

# Filesystem nearly full
- name: filesystem-full
  expr: '{otel_metric_name="system.filesystem.utilization"} * 100 > 85'
  for: 15m
  labels:
    severity: warning
  annotations:
    summary: "Filesystem nearly full"
    description: "Filesystem on {{ $labels.k8s_node_name }} mount {{ $labels.system_filesystem_mountpoint }} is {{ $value }}% full"

# High network errors
- name: network-errors
  expr: 'rate({otel_metric_name="k8s.node.network.errors"}[5m]) > 10'
  for: 5m
  labels:
    severity: warning
```

---

## Complete Dashboard Example

See `/Users/max/Projects/tries/2026-01-26-dash0-dashboards/kubernetes-cluster-dashboard.yaml` for a complete working example with:

- Cluster overview gauges (CPU, Memory, Filesystem utilization)
- Control plane metrics (API Server, etcd)
- Node metrics (CPU, Memory, Network, Filesystem)
- Proper variable filtering
- Threshold-based color coding

---

## Discovering Available Metrics

Use the Dash0 MCP tools to discover metrics:

```
# Get metric catalog
mcp_dash0_getMetricCatalog(timeRange: {from: "...", to: "..."})

# Get metric details (attributes, type)
mcp_dash0_getMetricDetails(metricName: "k8s.node.cpu.usage", metricType: "gauge", timeRange: {...})

# Get attribute keys for filtering
mcp_dash0_getAttributeKeys(scope: "metrics", timeRange: {...})

# Get attribute values
mcp_dash0_getAttributeValues(attributeKey: "k8s_cluster_name", scope: "metrics", timeRange: {...})
```

---

## Troubleshooting

### Variables Not Populating
- Ensure using `Dash0FilterVariable`, not `ListVariable`
- Check `attributeKey` matches the actual label name (underscores, not dots)

### Duplicate Series in Charts
- Add aggregation: `sum by (label) (...)` or `avg by (label) (...)`
- Check for multiple metric sources reporting the same data

### No Data Displayed
- Verify metric name with `mcp_dash0_getMetricCatalog`
- Check time range is appropriate
- Verify variable filter syntax: `$variable_name` (not `${variable_name}`)

### Gauge Not Showing Correct Value
- Ensure `calculation: last` for current value
- Check if query returns single series (use aggregation if multiple)
