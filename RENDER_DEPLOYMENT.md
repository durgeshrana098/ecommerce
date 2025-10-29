# Bagisto Deployment Guide for Render

This guide will help you deploy your Bagisto eCommerce application to Render using Docker.

## Prerequisites

1. **GitHub Repository**: Push your Bagisto project to GitHub
2. **Render Account**: Sign up at [render.com](https://render.com)
3. **Domain (Optional)**: For custom domain setup

## Files Created for Deployment

The following files have been created for your Render deployment:

- `Dockerfile` - Production Docker configuration
- `render.yaml` - Render service configuration
- `.dockerignore` - Files to exclude from Docker build
- `.env.production` - Production environment template

## Step-by-Step Deployment Process

### Step 1: Prepare Your Repository

1. **Commit all files to Git:**
   ```bash
   git add .
   git commit -m "Add Render deployment configuration"
   git push origin main
   ```

2. **Ensure your repository is public or you have Render connected to your GitHub account**

### Step 2: Deploy to Render

#### Option A: Using render.yaml (Recommended)

1. **Go to Render Dashboard**: Visit [dashboard.render.com](https://dashboard.render.com)

2. **Create New Service**: Click "New" → "Blueprint"

3. **Connect Repository**: 
   - Connect your GitHub repository
   - Select the repository containing your Bagisto project
   - Render will automatically detect the `render.yaml` file

4. **Review Configuration**: 
   - Verify the services (Web Service, Database, Redis)
   - Check environment variables
   - Modify any settings as needed

5. **Deploy**: Click "Apply" to start deployment

#### Option B: Manual Service Creation

1. **Create Database First:**
   - Go to Render Dashboard
   - Click "New" → "PostgreSQL" or "MySQL"
   - Name: `bagisto-db`
   - Plan: Choose appropriate plan
   - Region: Select your preferred region

2. **Create Redis Service:**
   - Click "New" → "Redis"
   - Name: `bagisto-redis`
   - Plan: Choose appropriate plan

3. **Create Web Service:**
   - Click "New" → "Web Service"
   - Connect your GitHub repository
   - Name: `bagisto-app`
   - Environment: Docker
   - Region: Same as database
   - Plan: Choose appropriate plan

### Step 3: Configure Environment Variables

If not using render.yaml, manually set these environment variables in your web service:

#### Required Variables:
```
APP_NAME=Bagisto
APP_ENV=production
APP_DEBUG=false
APP_URL=https://your-service-name.onrender.com
APP_KEY=base64:your-generated-key
DB_CONNECTION=mysql
DB_HOST=[Your Database Host]
DB_PORT=3306
DB_DATABASE=[Your Database Name]
DB_USERNAME=[Your Database User]
DB_PASSWORD=[Your Database Password]
```

#### Optional Variables:
```
MAIL_MAILER=smtp
MAIL_HOST=smtp.gmail.com
MAIL_PORT=587
MAIL_USERNAME=your-email@gmail.com
MAIL_PASSWORD=your-app-password
MAIL_ENCRYPTION=tls
REDIS_HOST=[Your Redis Host]
REDIS_PORT=6379
REDIS_PASSWORD=[Your Redis Password]
```

### Step 4: Generate Application Key

After deployment, you need to generate an application key:

1. **Access Shell**: In your Render web service, go to "Shell" tab
2. **Generate Key**: Run `php artisan key:generate --show`
3. **Update Environment**: Add the generated key to `APP_KEY` environment variable

### Step 5: Run Initial Setup

In the Render shell, run these commands:

```bash
# Clear caches
php artisan config:clear
php artisan cache:clear
php artisan view:clear

# Run migrations and seed database
php artisan migrate --force
php artisan db:seed --force

# Create storage link
php artisan storage:link

# Cache for production
php artisan config:cache
php artisan route:cache
php artisan view:cache
```

## Service Configuration Details

### Web Service Specifications:
- **Runtime**: Docker
- **Build Command**: Automatic (uses Dockerfile)
- **Start Command**: Handled by Dockerfile entrypoint
- **Health Check**: `/` endpoint
- **Port**: 80 (internal)

### Database Specifications:
- **Type**: MySQL 8.0
- **Storage**: Persistent SSD storage
- **Backups**: Automatic daily backups
- **Connection**: Internal network

### Redis Specifications:
- **Type**: Redis 6+
- **Memory Policy**: allkeys-lru
- **Persistence**: Available on paid plans

## Post-Deployment Configuration

### 1. Admin Access
- **Admin URL**: `https://your-app.onrender.com/admin`
- **Default Credentials**: Set during initial setup

### 2. Email Configuration
Update these environment variables for email functionality:
```
MAIL_USERNAME=your-smtp-username
MAIL_PASSWORD=your-smtp-password
MAIL_FROM_ADDRESS=noreply@yourdomain.com
```

### 3. File Storage (Optional)
For production file storage, configure AWS S3:
```
FILESYSTEM_DISK=s3
AWS_ACCESS_KEY_ID=your-access-key
AWS_SECRET_ACCESS_KEY=your-secret-key
AWS_DEFAULT_REGION=us-east-1
AWS_BUCKET=your-bucket-name
```

### 4. Custom Domain
1. Go to your web service settings
2. Add your custom domain
3. Configure DNS records as instructed by Render

## Monitoring and Maintenance

### Logs
- **Application Logs**: Available in Render dashboard
- **Error Tracking**: Configure external service like Sentry

### Performance
- **Caching**: Redis is configured for session and cache storage
- **Database**: Monitor query performance in Render dashboard
- **CDN**: Consider using Cloudflare for static assets

### Updates
1. Push changes to your GitHub repository
2. Render will automatically rebuild and deploy
3. Monitor deployment logs for any issues

## Troubleshooting

### Common Issues:

1. **Database Connection Errors**
   - Verify database environment variables
   - Check database service status
   - Ensure proper network connectivity

2. **File Permission Issues**
   - Storage directories are configured in Dockerfile
   - Check if storage link was created properly

3. **Memory Issues**
   - Upgrade to higher plan if needed
   - Optimize application caching

4. **Build Failures**
   - Check Dockerfile syntax
   - Verify all dependencies are available
   - Review build logs for specific errors

### Support Resources:
- **Render Documentation**: [render.com/docs](https://render.com/docs)
- **Bagisto Documentation**: [devdocs.bagisto.com](https://devdocs.bagisto.com)
- **Community Support**: [forums.bagisto.com](https://forums.bagisto.com)

## Cost Estimation

### Starter Configuration:
- **Web Service**: $7/month
- **MySQL Database**: $7/month  
- **Redis**: $7/month
- **Total**: ~$21/month

### Production Configuration:
- **Web Service**: $25/month (Standard)
- **MySQL Database**: $15/month (Standard)
- **Redis**: $15/month (Standard)
- **Total**: ~$55/month

## Security Considerations

1. **Environment Variables**: Never commit sensitive data to Git
2. **HTTPS**: Render provides free SSL certificates
3. **Database**: Use strong passwords and restrict access
4. **Updates**: Keep dependencies updated regularly
5. **Monitoring**: Set up alerts for unusual activity

---

**Note**: This deployment configuration is optimized for production use. Make sure to test thoroughly before going live with your eCommerce store.
