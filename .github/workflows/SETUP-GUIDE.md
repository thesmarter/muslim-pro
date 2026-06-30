# Google Play CI/CD Setup Guide

## Overview

This guide explains how to configure the GitHub Actions workflow for building and publishing your Flutter app to Google Play Store.

## Required GitHub Secrets

You need to configure the following secrets in your GitHub repository:

### 1. KEYSTORE_BASE64

The Android signing keystore encoded in Base64.

```bash
# Encode your keystore to Base64
base64 -i android/DetaTech.jks | tr -d '\n'
```

Copy the output and add it as a secret named `KEYSTORE_BASE64`.

### 2. KEY_STORE_PASSWORD

The password for your keystore.

```
bencolMBC3$
```

### 3. KEY_ALIAS

The key alias in your keystore.

```
DetaTech
```

### 4. KEY_PASSWORD

The password for your key.

```
bencolMBC3$
```

### 5. GOOGLE_PLAY_SERVICE_ACCOUNT_JSON

The Google Play service account JSON file for API access.

#### Steps to create:

1. Go to [Google Play Console](https://play.google.com/console)
2. Navigate to **Setup** → **API access**
3. Click **Create Service Account**
4. Follow the guide to create a service account in Google Cloud Console
5. Enable the **Google Play Android Developer API**
6. Create a JSON key file for the service account
7. Back in Google Play Console, grant the service account permissions:
   - **Release Manager** or **Production** track access
8. Download the JSON key file
9. Copy the entire JSON content and add it as a secret named `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON`

## Setting up GitHub Secrets

1. Go to your GitHub repository
2. Navigate to **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Add each secret with the name and value specified above

## Workflow Triggers

The workflow runs automatically when:
- Changes are **pushed** to the `play` branch

**Note:** Updates to any other branch will NOT trigger this workflow.

## Release Tracks

### Internal Track (Default)
- The workflow automatically publishes to the **Internal** track
- Suitable for testing before production release
- Requires manual promotion in Google Play Console

### Production Track (Optional)
- Uncomment the `publish-production` job in the workflow
- Add a GitHub environment named `production` with protection rules
- Consider adding manual approval before production releases

## Workflow Jobs

1. **validate** - Runs tests and code analysis
2. **build** - Builds the signed AAB
3. **publish-internal** - Uploads to Google Play Internal track
4. **publish-production** - (Optional) Publishes to Production track
5. **notify** - Sends success notification

## Customizing Release Notes

Edit files in the `whatsnew/` directory:
- `whatsnew/en-US` - English release notes
- `whatsnew/ar` - Arabic release notes

## Troubleshooting

### Build Fails
- Ensure Flutter SDK is installed and configured
- Check that all dependencies are resolved
- Verify the keystore is correctly encoded

### Upload Fails
- Verify the service account has proper permissions
- Check that the package name matches (`sd.elteyab.fxapp`)
- Ensure the version code is incremented

### Signing Issues
- Verify the keystore Base64 encoding is correct
- Check that key.properties values match your secrets
- Ensure the keystore file is not corrupted
