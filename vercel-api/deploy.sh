#!/bin/bash

echo "🚀 Deploying Woosh API to Vercel..."

# Check if Vercel CLI is installed
if ! command -v vercel &> /dev/null; then
    echo "📦 Installing Vercel CLI..."
    npm install -g vercel
fi

# Install dependencies
echo "📦 Installing dependencies..."
npm install

# Deploy to Vercel
echo "🌐 Deploying to Vercel..."
vercel --prod

echo "✅ Deployment complete!"
echo "🔗 Your API URL will be shown above"
echo "📝 Don't forget to update lib/config/database_config.dart with your API URL" 