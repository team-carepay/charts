# Spot/On-Demand Splitting Guide

This chart supports splitting workloads between spot and on-demand instances using Karpenter's capacity-spread labels and Kubernetes topology spread constraints.

## Configuration

### 1. Create NodePools with capacity-spread labels

```yaml
nodepools:
  - name: spot
    nodeClassName: general
    capacityTypes: ["spot"]
    capacitySpreadLabels: ["1-s", "2-s", "3-s", "4-s", "5-s"]
    instanceCategories: ["c", "m", "r"]
    instanceGeneration:
      operator: Gt
      values: ["4"]
    consolidationPolicy: WhenEmptyOrUnderutilized
    consolidateAfter: 1m
    limits:
      cpu: "1000"

  - name: ondemand
    nodeClassName: general
    capacityTypes: ["on-demand"]
    capacitySpreadLabels: ["1-od", "2-od", "3-od", "4-od", "5-od"]
    instanceCategories: ["c", "m", "r"]
    instanceGeneration:
      operator: Gt
      values: ["4"]
    consolidationPolicy: WhenEmptyOrUnderutilized
    consolidateAfter: 1m
    limits:
      cpu: "1000"
```

### 2. Configure your Deployment with topology spread constraints

#### 50/50 Split (Spot/On-Demand)

```yaml
spec:
  template:
    spec:
      topologySpreadConstraints:
        - maxSkew: 1
          topologyKey: capacity-spread
          whenUnsatisfiable: DoNotSchedule
          labelSelector:
            matchLabels:
              app: your-app
```

#### 60/40 Split (60% Spot, 40% On-Demand)

```yaml
spec:
  template:
    spec:
      topologySpreadConstraints:
        - maxSkew: 1
          topologyKey: capacity-spread
          whenUnsatisfiable: DoNotSchedule
          labelSelector:
            matchLabels:
              app: your-app
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
              - matchExpressions:
                  - key: capacity-spread
                    operator: In
                    values:
                      - 1-s
                      - 2-s
                      - 3-s
                      - 1-od
                      - 2-od
```

#### 80/20 Split (80% On-Demand, 20% Spot)

```yaml
spec:
  template:
    spec:
      topologySpreadConstraints:
        - maxSkew: 1
          topologyKey: capacity-spread
          whenUnsatisfiable: DoNotSchedule
          labelSelector:
            matchLabels:
              app: your-app
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
              - matchExpressions:
                  - key: capacity-spread
                    operator: In
                    values:
                      - 1-od
                      - 2-od
                      - 3-od
                      - 4-od
                      - 1-s
```

## How It Works

- Each NodePool gets labeled with capacity-spread values (e.g., `1-s`, `2-s` for spot)
- `topologySpreadConstraints` ensures even distribution across all capacity-spread values
- `nodeAffinity` limits which capacity-spread values are used, controlling the ratio
- More labels = higher proportion in the split
