# Gharsewa Documentation

Welcome to the Gharsewa documentation. This directory contains comprehensive guides for users, developers, and operators.

## Documentation Overview

### For End Users

- **[AI Visual Assistant User Guide](AI_VISUAL_ASSISTANT_USER_GUIDE.md)**
  - How to use the AI Visual Assistant feature
  - Step-by-step consultation creation
  - Understanding AI recommendations
  - Managing consultation history
  - Troubleshooting common user issues

### For Developers

- **[Flutter Integration Guide](AI_VISUAL_ASSISTANT_FLUTTER_GUIDE.md)**
  - Flutter architecture and design patterns
  - Data models and API services
  - State management with Riverpod
  - Custom widgets (AnnotationCanvas)
  - Testing strategies
  - Performance optimization

- **[Backend API Reference](../backend/AI_VISUAL_ASSISTANT_API_REFERENCE.md)**
  - Complete API endpoint documentation
  - Request/response formats
  - Authentication requirements
  - Error codes and handling
  - Rate limiting details

- **[Backend Testing Guide](../backend/AI_VISUAL_ASSISTANT_TESTING_GUIDE.md)**
  - Backend testing procedures
  - Unit and feature tests
  - Integration testing
  - Test data setup

### For DevOps/Operations

- **[Deployment Guide](AI_VISUAL_ASSISTANT_DEPLOYMENT_GUIDE.md)**
  - Production deployment steps
  - Backend configuration
  - Ollama service setup
  - Flutter app building
  - App store submission
  - Monitoring and alerts
  - Backup strategies

- **[Troubleshooting Guide](AI_VISUAL_ASSISTANT_TROUBLESHOOTING_GUIDE.md)**
  - Common issues and solutions
  - Backend troubleshooting
  - Flutter app issues
  - Database problems
  - Performance optimization
  - Log collection

## Quick Links

### Getting Started
1. [Setup Instructions](../HOW_TO_RUN.md)
2. [Provider Registration](../HOW_TO_REGISTER_AS_PROVIDER.md)
3. [API Reference](../backend/AI_VISUAL_ASSISTANT_API_REFERENCE.md)

### Feature Documentation
- AI Visual Assistant (this directory)
- Multi-Panel Architecture (coming soon)
- Booking System (coming soon)
- Payment Integration (coming soon)

### Technical Specifications
- [Requirements](../.kiro/specs/ai-visual-assistant/requirements.md)
- [Design Document](../.kiro/specs/ai-visual-assistant/design.md)
- [Task List](../.kiro/specs/ai-visual-assistant/tasks.md)

## Documentation Structure

```
docs/
├── README.md (this file)
├── AI_VISUAL_ASSISTANT_USER_GUIDE.md
├── AI_VISUAL_ASSISTANT_FLUTTER_GUIDE.md
├── AI_VISUAL_ASSISTANT_DEPLOYMENT_GUIDE.md
└── AI_VISUAL_ASSISTANT_TROUBLESHOOTING_GUIDE.md

backend/
├── AI_VISUAL_ASSISTANT_API_REFERENCE.md
└── AI_VISUAL_ASSISTANT_TESTING_GUIDE.md

.kiro/specs/ai-visual-assistant/
├── requirements.md
├── design.md
└── tasks.md
```

## Key Concepts

### AI Visual Assistant

The AI Visual Assistant is a feature that allows customers to:
1. Capture or select images of home service issues
2. Mark defects on images with visual annotations
3. Add text descriptions for each defect
4. Receive AI-powered diagnosis and recommendations
5. Get cost estimates and provider suggestions
6. Book services directly from recommendations

### Technology Stack

- **Backend**: Laravel 11, MySQL, Ollama (qwen3-vl:2b)
- **Frontend**: Flutter 3.x, Riverpod
- **Infrastructure**: Docker, Nginx, Redis

### Architecture

- **Clean Architecture**: Separation of concerns
- **State Management**: Riverpod for reactive state
- **API Communication**: RESTful with JWT authentication
- **Image Processing**: Client-side compression, server-side storage

## Common Tasks

### For Users
- [Creating a consultation](AI_VISUAL_ASSISTANT_USER_GUIDE.md#creating-a-new-consultation)
- [Viewing history](AI_VISUAL_ASSISTANT_USER_GUIDE.md#viewing-consultation-history)
- [Booking a service](AI_VISUAL_ASSISTANT_USER_GUIDE.md#step-5-book-a-service-optional)

### For Developers
- [Setting up development environment](../HOW_TO_RUN.md)
- [Running tests](AI_VISUAL_ASSISTANT_FLUTTER_GUIDE.md#testing)
- [Adding new features](AI_VISUAL_ASSISTANT_FLUTTER_GUIDE.md#architecture)

### For Operations
- [Deploying to production](AI_VISUAL_ASSISTANT_DEPLOYMENT_GUIDE.md)
- [Monitoring services](AI_VISUAL_ASSISTANT_DEPLOYMENT_GUIDE.md#step-2-performance-monitoring)
- [Troubleshooting issues](AI_VISUAL_ASSISTANT_TROUBLESHOOTING_GUIDE.md)

## Support

### Getting Help

1. **Check Documentation**: Start with the relevant guide above
2. **Search Issues**: Look for similar problems in GitHub Issues
3. **Check Logs**: Review application logs for errors
4. **Contact Support**: Email support@gharsewa.com

### Reporting Issues

When reporting issues, include:
- What you were trying to do
- What happened instead
- Error messages or screenshots
- Steps to reproduce
- Environment details (OS, app version, etc.)

### Contributing to Documentation

We welcome documentation improvements! To contribute:

1. Fork the repository
2. Make your changes
3. Submit a pull request
4. Describe what you changed and why

## Version History

- **v1.0.0** (January 2024): Initial release
  - AI Visual Assistant feature complete
  - Backend API with 108 passing tests
  - Flutter UI with 6 screens
  - Comprehensive documentation

## License

This documentation is part of the Gharsewa project and is proprietary software. All rights reserved.

---

**Last Updated**: January 2024  
**Maintained By**: Gharsewa Development Team
