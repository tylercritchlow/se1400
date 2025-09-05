#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

if [ $# -eq 0 ]; then
    echo "Usage: $0 <directory>"
    echo "Example: $0 milestone1"
    exit 1
fi

TARGET_DIR="$SCRIPT_DIR/$1"

if [ ! -d "$TARGET_DIR" ]; then
    echo "Error: Directory '$1' does not exist in $SCRIPT_DIR"
    exit 1
fi

echo "Validating HTML files in $1..."
echo "================================"

for file in "$TARGET_DIR"/*.html; do
    if [ -f "$file" ]; then
        echo "Validating: $(basename "$file")"
        response=$(curl -s -H "Content-Type: text/html; charset=utf-8" \
            --data-binary @"$file" \
            "https://validator.w3.org/nu/?out=json")
        
        message_count=$(echo "$response" | python3 -c "import sys, json; data = json.load(sys.stdin); print(len(data.get('messages', [])))" 2>/dev/null)
        
        if [ "$message_count" = "0" ]; then
            echo "✓ Valid - No errors or warnings"
        else
            echo "$response" | python3 -m json.tool | grep -E '"(type|message)"' | sed 's/^/  /'
        fi
        echo "--------------------------------"
    fi
done

echo ""
echo "Validating CSS files in $1..."
echo "================================"

for file in "$TARGET_DIR"/*.css; do
    if [ -f "$file" ]; then
        echo "Validating: $(basename "$file")"
        response=$(curl -s -H "Content-Type: text/css; charset=utf-8" \
            --data-binary @"$file" \
            "https://jigsaw.w3.org/css-validator/validator?output=json&warning=0")
        
        error_count=$(echo "$response" | python3 -c "import sys, json; data = json.load(sys.stdin); print(data.get('cssvalidation', {}).get('result', {}).get('errorcount', 0))" 2>/dev/null)
        
        if [ "$error_count" = "0" ] || [ -z "$error_count" ]; then
            echo "✓ Valid - No errors"
        else
            echo "$response" | python3 -c "import sys, json; data = json.load(sys.stdin); errors = data.get('cssvalidation', {}).get('errors', []); [print(f\"  Error: {e.get('message', 'Unknown error')}\") for e in errors]" 2>/dev/null
        fi
        echo "--------------------------------"
    fi
done

echo "Validation complete!"
