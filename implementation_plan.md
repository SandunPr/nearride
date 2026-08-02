# Implementation Plan — Issues Fix & Optimizations (File Handling, User Registrations, List Creations)

The goal of this task is to review the NearRide codebase, fix critical bugs/issues, and optimize three core areas—**File Handling**, **User Registrations**, and **List Creations**—for both the Node.js Express backend API and the Flutter mobile application, strictly preserving the existing folder structure.

---

## User Review Required

> [!IMPORTANT]
> **No Folder Structure Changes**: All modifications will be strictly confined within existing files and directories. No new folders will be created or restructured.
> **Image Upload for Listings**: A new image upload and deletion API endpoint will be enabled on the backend (`/provider/listings/:publicId/images`) to allow providers to upload vehicle listing photos, matching the database schema (`listing_images` table).

---

## Proposed Changes

### Backend API (`src/`)

#### [MODIFY] [auth.controller.js](file:///c:/Users/EK/Desktop/Codex/nearride/src/controllers/auth.controller.js)
- **User Registration**:
  - Add input trimming (`value.email.trim().toLowerCase()`, `value.fullName.trim()`).
  - Strengthen validation for phone numbers and passwords.
- **Avatar File Handling Optimization**:
  - In `updateAvatar`, check if the user previously had a custom avatar stored on disk and delete old avatar files using `fs.unlink` to prevent disk space leaks.
  - Standardize error handling and buffer validation for image processing with `sharp`.

#### [MODIFY] [token.service.js](file:///c:/Users/EK/Desktop/Codex/nearride/src/services/token.service.js)
- Compute dynamic `expiresIn` seconds matching `cfg.accessExpires` instead of hardcoded `900`.

#### [MODIFY] [provider.controller.js](file:///c:/Users/EK/Desktop/Codex/nearride/src/controllers/provider.controller.js)
- **Listing Creation Optimization**:
  - Expand `create` handler with detailed validation for mandatory and optional fields (category ID validation, coordinate ranges `[-90, 90]`, `[-180, 180]`, price units, passenger/load capacity, year).
- **Listing Image Handling**:
  - Implement `uploadImages`: accepts image uploads via Multer, resizes/compresses image and thumbnail using `sharp`, stores files in `public/uploads/listings/`, and inserts into `listing_images` table.
  - Implement `deleteImage`: deletes specified listing image from database and unlinks image files from disk.
  - In `remove` (listing soft/hard deletion), clean up stored image files.

#### [MODIFY] [listing.controller.js](file:///c:/Users/EK/Desktop/Codex/nearride/src/controllers/listing.controller.js)
- Optimize `nearby` and `search` query parameters, ensuring accurate total pagination counts and proper distance rounding.

#### [MODIFY] [routes/index.js](file:///c:/Users/EK/Desktop/Codex/nearride/src/routes/index.js)
- Register listing image upload (`POST /provider/listings/:publicId/images`) and deletion (`DELETE /provider/listings/:publicId/images/:imageId`) routes with Multer configuration.

---

### Flutter Application (`nearride_app/lib/`)

#### [MODIFY] [register_screen.dart](file:///c:/Users/EK/Desktop/Codex/nearride/nearride_app/lib/features/auth/presentation/register_screen.dart)
- Trim email, full name, and phone input strings before sending to API.
- Provide clear field-specific error messages.

#### [MODIFY] [provider_screen.dart](file:///c:/Users/EK/Desktop/Codex/nearride/nearride_app/lib/features/provider/presentation/provider_screen.dart)
- **List Creation Enhancements**:
  - Add GPS location detection using `LocationService` to acquire current latitude and longitude coordinates.
  - Add fields for vehicle category selection, description, manufacturer, model, year, capacity, starting price, and negotiable/pricing unit options.
  - Implement multi-image picker and upload step connected to the listing image upload endpoint.
  - Add form validation per step before proceeding to prevent incomplete submissions.

---

## Verification Plan

### Automated Verification
- Run backend tests to verify health and route handling:
  ```powershell
  cmd /c npm test
  ```

### Manual Verification
- Test user registration with edge-case emails and passwords.
- Verify profile avatar upload and verify old avatar file cleanup on disk.
- Test multi-step provider listing creation with real GPS detection, category selection, and image uploading.
