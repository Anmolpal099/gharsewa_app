# Presentation Layer

This directory contains UI components, screens, and presentation logic.

## Structure

### Panels
- **panels/customer/** - Customer mobile panel
  - **screens/** - Customer screens (home, bookings, profile)
  - **widgets/** - Customer-specific widgets
  - **controllers/** - Customer panel controllers/providers

- **panels/provider/** - Service Provider mobile panel
  - **screens/** - Provider screens (dashboard, services, bookings)
  - **widgets/** - Provider-specific widgets
  - **controllers/** - Provider panel controllers/providers

- **panels/admin/** - Admin web dashboard
  - **screens/** - Admin screens (dashboard, users, bookings)
  - **widgets/** - Admin-specific widgets
  - **controllers/** - Admin panel controllers/providers

### Shared
- **shared/widgets/** - Reusable widgets across all panels
- **shared/layouts/** - Common layouts and scaffolds
- **router/** - Navigation and routing configuration
