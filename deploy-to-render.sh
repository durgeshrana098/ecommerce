#!/bin/bash

# Bagisto Render Deployment Script
# This script helps prepare your Bagisto project for Render deployment

echo "🚀 Preparing Bagisto for Render Deployment..."

# Check if we're in a git repository
if [ ! -d ".git" ]; then
    echo "❌ Error: Not in a Git repository. Please initialize git first:"
    echo "   git init"
    echo "   git remote add origin <your-repo-url>"
    exit 1
fi

# Check if required files exist
echo "📋 Checking deployment files..."

required_files=("Dockerfile" "render.yaml" ".dockerignore" "RENDER_DEPLOYMENT.md")
missing_files=()

for file in "${required_files[@]}"; do
    if [ ! -f "$file" ]; then
        missing_files+=("$file")
    fi
done

if [ ${#missing_files[@]} -gt 0 ]; then
    echo "❌ Missing required files:"
    printf '%s\n' "${missing_files[@]}"
    echo "Please ensure all deployment files are created."
    exit 1
fi

echo "✅ All deployment files found!"

# Build and test Docker image locally (optional)
read -p "🐳 Do you want to test the Docker build locally? (y/N): " test_build

if [[ $test_build =~ ^[Yy]$ ]]; then
    echo "🔨 Building Docker image locally..."
    
    if docker build -t bagisto-test .; then
        echo "✅ Docker build successful!"
        
        read -p "🧪 Do you want to run the container locally for testing? (y/N): " run_test
        
        if [[ $run_test =~ ^[Yy]$ ]]; then
            echo "🏃 Starting test container..."
            echo "Note: This will fail without proper database connection, but you can check if the container starts."
            docker run --rm -p 8080:80 bagisto-test &
            CONTAINER_PID=$!
            
            echo "Container started with PID: $CONTAINER_PID"
            echo "You can test at http://localhost:8080"
            echo "Press Enter to stop the container..."
            read
            
            kill $CONTAINER_PID 2>/dev/null || true
            echo "Container stopped."
        fi
    else
        echo "❌ Docker build failed. Please check the Dockerfile and try again."
        exit 1
    fi
fi

# Check git status
echo "📊 Checking Git status..."
if [ -n "$(git status --porcelain)" ]; then
    echo "📝 You have uncommitted changes:"
    git status --short
    
    read -p "💾 Do you want to commit these changes? (y/N): " commit_changes
    
    if [[ $commit_changes =~ ^[Yy]$ ]]; then
        read -p "📝 Enter commit message: " commit_message
        
        if [ -z "$commit_message" ]; then
            commit_message="Add Render deployment configuration"
        fi
        
        git add .
        git commit -m "$commit_message"
        echo "✅ Changes committed!"
    fi
else
    echo "✅ Working directory is clean!"
fi

# Push to remote
read -p "🚀 Do you want to push to remote repository? (y/N): " push_changes

if [[ $push_changes =~ ^[Yy]$ ]]; then
    echo "📤 Pushing to remote..."
    
    if git push; then
        echo "✅ Successfully pushed to remote!"
    else
        echo "❌ Failed to push. Please check your remote configuration."
        exit 1
    fi
fi

echo ""
echo "🎉 Deployment preparation complete!"
echo ""
echo "📋 Next steps:"
echo "1. Go to https://dashboard.render.com"
echo "2. Click 'New' → 'Blueprint'"
echo "3. Connect your GitHub repository"
echo "4. Render will detect the render.yaml file automatically"
echo "5. Review the configuration and click 'Apply'"
echo ""
echo "📖 For detailed instructions, see RENDER_DEPLOYMENT.md"
echo ""
echo "🔗 Useful links:"
echo "   - Render Dashboard: https://dashboard.render.com"
echo "   - Bagisto Docs: https://devdocs.bagisto.com"
echo "   - Render Docs: https://render.com/docs"
echo ""
echo "💡 Pro tip: Save your database credentials and app key securely!"
echo ""
