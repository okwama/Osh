#!/bin/bash

# Script to update import statements from 'glamour_queen' to 'woosh'

echo "Updating import statements from 'glamour_queen' to 'woosh'..."

# Function to update imports in a single file
update_imports_in_file() {
    local file_path="$1"
    
    if [[ ! -f "$file_path" ]]; then
        return 1
    fi
    
    # Create backup
    cp "$file_path" "$file_path.backup"
    
    # Update package imports
    sed -i 's|import '\''package:glamour_queen/|import '\''package:woosh/|g' "$file_path"
    
    # Update relative imports
    sed -i 's|import '\''../../glamour_queen/|import '\''../../woosh/|g' "$file_path"
    sed -i 's|import '\''../glamour_queen/|import '\''../woosh/|g' "$file_path"
    sed -i 's|import '\''glamour_queen/|import '\''woosh/|g' "$file_path"
    
    if ! cmp -s "$file_path" "$file_path.backup"; then
        echo "Updated: $file_path"
        rm "$file_path.backup"
        return 0
    else
        rm "$file_path.backup"
        return 1
    fi
}

# Function to update pubspec.yaml
update_pubspec_yaml() {
    local pubspec_path="pubspec.yaml"
    
    if [[ ! -f "$pubspec_path" ]]; then
        return 1
    fi
    
    cp "$pubspec_path" "$pubspec_path.backup"
    
    sed -i 's/name: glamour_queen/name: woosh/' "$pubspec_path"
    sed -i 's/description: "Glamour Queen - A Flutter project."/description: "Woosh- A Flutter project."/' "$pubspec_path"
    
    if ! cmp -s "$pubspec_path.backup" "$pubspec_path"; then
        echo "Updated: $pubspec_path"
        rm "$pubspec_path.backup"
        return 0
    else
        rm "$pubspec_path.backup"
        return 1
    fi
}

# Function to update test file
update_test_files() {
    local test_path="test/widget_test.dart"
    
    if [[ ! -f "$test_path" ]]; then
        return 1
    fi
    
    cp "$test_path" "$test_path.backup"
    
    sed -i "s|import 'package:glamour_queen/main.dart';|import 'package:woosh/main.dart';|g" "$test_path"
    
    if ! cmp -s "$test_path.backup" "$test_path"; then
        echo "Updated: $test_path"
        rm "$test_path.backup"
        return 0
    else
        rm "$test_path.backup"
        return 1
    fi
}

# Function to update Android package name
update_android_files() {
    local android_files=(
        "android/app/src/main/kotlin/com/example/glamour_queen/MainActivity.kt"
        "android/app/src/main/java/com/example/glamour_queen/MainActivity.java"
    )
    
    for file in "${android_files[@]}"; do
        if [[ -f "$file" ]]; then
            cp "$file" "$file.backup"
            
            sed -i 's/package com\.example\.glamour_queen/package com.example.woosh/g' "$file"
            sed -i 's/import com\.example\.glamour_queen/import com.example.woosh/g' "$file"
            
            if ! cmp -s "$file.backup" "$file"; then
                echo "Updated: $file"
                rm "$file.backup"
            else
                rm "$file.backup"
            fi
        fi
    done
}

# Main logic
updated_files=0
total_files=0

if update_pubspec_yaml; then
    ((updated_files++))
fi
((total_files++))

if update_test_files; then
    ((updated_files++))
fi
((total_files++))

update_android_files

echo "Scanning Dart files to update..."
while IFS= read -r -d '' file; do
    ((total_files++))
    if update_imports_in_file "$file"; then
        ((updated_files++))
    fi
done < <(find lib test -name "*.dart" -type f -print0 2>/dev/null)

echo ""
echo "Update completed!"
echo "Files processed: $total_files"
echo "Files updated: $updated_files"

if [[ $updated_files -gt 0 ]]; then
    echo ""
    echo "Next steps:"
    echo "1. Run 'flutter clean'"
    echo "2. Run 'flutter pub get'"
    echo "3. Test your application thoroughly"
else
    echo ""
    echo "No files were updated. All may already be correct."
fi
