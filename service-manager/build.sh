#!/bin/bash

# Build script for Service Manager

echo "Building Service Manager..."

# Clean previous builds
rm -f service-manager

# Build the application
/usr/local/go/bin/go build -o service-manager main.go

if [ $? -eq 0 ]; then
    echo "Build successful!"
    echo "Run with: sudo ./service-manager"
    
    # Make executable
    chmod +x service-manager
    
    echo "Executable permissions set."
else
    echo "Build failed!"
    exit 1
fi
