#!/bin/zsh

echo "Creating Hive directories..."
mkdir -p lib/models/hive
mkdir -p lib/services/hive
mkdir -p lib/utils/hive

echo "Creating model files..."
touch lib/models/hive/journey_plan_model.dart
touch lib/models/hive/order_model.dart
touch lib/models/hive/client_model.dart
touch lib/models/hive/user_model.dart

echo "Creating service files..."
touch lib/services/hive/journey_plan_hive_service.dart
touch lib/services/hive/order_hive_service.dart
touch lib/services/hive/client_hive_service.dart
touch lib/services/hive/user_hive_service.dart

echo "Creating Hive initializer..."
touch lib/utils/hive/hive_initializer.dart

echo "✅ All Hive scaffolding created!"
