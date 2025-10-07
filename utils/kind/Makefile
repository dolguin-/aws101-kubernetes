.PHONY: install lb delete clean status all help

help: ## Show this help message
	@echo "Available targets:"
	@awk 'BEGIN {FS = ":.*##"} /^[a-zA-Z_-]+:.*##/ { printf "  %-15s %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

install: ## Create kind cluster with configuration
	@echo "🚀 Setting up kind cluster..."
	@if kind get clusters | grep -q "^aws101$$"; then \
		echo "⚠️  Cluster 'aws101' already exists"; \
	else \
		kind create cluster --name aws101 --config kind-cluster.yml; \
		echo "✅ Cluster created successfully"; \
	fi

lb: ## Install MetalLB load balancer
	@echo "🔧 Setting up MetalLB..."
	@./metallb/metallb.sh

delete: ## Delete kind cluster
	@echo "🗑️  Removing kind cluster..."
	@if kind get clusters | grep -q "^aws101$$"; then \
		kind delete cluster --name aws101; \
		echo "✅ Cluster deleted successfully"; \
	else \
		echo "⚠️  Cluster 'aws101' does not exist"; \
	fi

clean: delete ## Alias for delete

status: ## Show cluster status
	@echo "📊 Cluster status:"
	@if kind get clusters | grep -q "^aws101$$"; then \
		echo "✅ Cluster 'aws101' is running"; \
		kubectl cluster-info --context kind-aws101 2>/dev/null || echo "❌ kubectl context not available"; \
	else \
		echo "❌ Cluster 'aws101' not found"; \
	fi

all: install lb ## Install cluster and MetalLB
