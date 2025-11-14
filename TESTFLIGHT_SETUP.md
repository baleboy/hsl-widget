# TestFlight CI/CD Setup Guide

This guide will help you complete the setup for automatic TestFlight deployment on every commit to `main`.

## What's Been Created

- ✅ `fastlane/Fastfile` - Fastlane automation script
- ✅ `fastlane/Appfile` - Fastlane app configuration
- ✅ `Gemfile` - Ruby dependencies
- ✅ `.github/workflows/testflight.yml` - GitHub Actions workflow
- ✅ `.gitignore` - Updated to exclude sensitive files

## Setup Steps

### 1. Update Fastlane Configuration

Edit `fastlane/Appfile` and replace `YOUR_APPLE_ID_EMAIL` with your actual Apple ID email.

### 2. Create App Store Connect API Key

1. Go to [App Store Connect](https://appstoreconnect.apple.com/)
2. Navigate to: Users and Access → Integrations → App Store Connect API
3. Click "+" to create a new key
4. Name: "GitHub Actions CI"
5. Access: Select "Admin" or "App Manager"
6. Click "Generate"
7. **Download the `.p8` file** (you can only do this once!)
8. Note the **Key ID** (e.g., `ABC123DEF`)
9. Note the **Issuer ID** (UUID format, shown at the top of the page)

### 3. Prepare Code Signing Materials

#### Export Distribution Certificate:

1. Open **Keychain Access**
2. Go to "My Certificates"
3. Find "Apple Distribution: [Your Name]"
4. Right-click → Export "Apple Distribution..."
5. Save as `.p12` format
6. Set a password (remember it!)

#### Get Provisioning Profiles:

You should have downloaded two `.mobileprovision` files from Apple Developer:
- `HslWidget App Store.mobileprovision` (main app)
- `HslWidget stopInfo App Store.mobileprovision` (widget extension)

### 4. Base64 Encode Files for GitHub Secrets

Run these commands in Terminal:

```bash
# Certificate
base64 -i /path/to/your-certificate.p12 | pbcopy
# Paste into GitHub Secret: CERTIFICATES_P12

# Main app provisioning profile
base64 -i /path/to/HslWidget\ App\ Store.mobileprovision | pbcopy
# Paste into GitHub Secret: MAIN_PROVISIONING_PROFILE

# Widget provisioning profile
base64 -i /path/to/HslWidget\ stopInfo\ App\ Store.mobileprovision | pbcopy
# Paste into GitHub Secret: WIDGET_PROVISIONING_PROFILE

# App Store Connect API Key
base64 -i /path/to/AuthKey_ABC123DEF.p8 | pbcopy
# Paste into GitHub Secret: APP_STORE_CONNECT_API_KEY
```

### 5. Configure GitHub Secrets

Go to your GitHub repository → Settings → Secrets and variables → Actions

Click "New repository secret" for each of these:

| Secret Name | Value | Description |
|-------------|-------|-------------|
| `CERTIFICATES_P12` | Base64-encoded .p12 | Distribution certificate |
| `CERTIFICATE_PASSWORD` | Your password | Password for the .p12 file |
| `MAIN_PROVISIONING_PROFILE` | Base64-encoded file | Main app provisioning profile |
| `WIDGET_PROVISIONING_PROFILE` | Base64-encoded file | Widget provisioning profile |
| `APP_STORE_CONNECT_API_KEY` | Base64-encoded .p8 | App Store Connect API key |
| `APP_STORE_CONNECT_KEY_ID` | e.g., ABC123DEF | Key ID from App Store Connect |
| `APP_STORE_CONNECT_ISSUER_ID` | UUID format | Issuer ID from App Store Connect |
| `KEYCHAIN_PASSWORD` | Any secure password | Temporary keychain password for CI |

### 6. Test the Workflow

#### Option A: Test on a branch first

1. Create a test branch:
   ```bash
   git checkout -b test-ci
   ```

2. Commit and push:
   ```bash
   git add .
   git commit -m "Add TestFlight CI/CD workflow"
   git push -u origin test-ci
   ```

3. Manually trigger the workflow:
   - Go to GitHub → Actions tab
   - Select "Deploy to TestFlight"
   - Click "Run workflow" → Select your test branch

#### Option B: Merge to main

Once you're confident:
```bash
git checkout main
git merge test-ci
git push
```

The workflow will automatically run on every push to `main`.

### 7. Monitor the Build

1. Go to your GitHub repository
2. Click the "Actions" tab
3. Watch the workflow run
4. If it succeeds, check TestFlight in App Store Connect for your new build

## Workflow Behavior

- **Trigger:** Automatically runs on every push to `main`
- **Build number:** Automatically increments based on latest TestFlight build
- **Commit:** Pushes the build number increment back to the repo
- **TestFlight:** Uploads build but doesn't auto-distribute to testers (you control that in App Store Connect)

## Troubleshooting

### Build fails with signing errors
- Double-check that provisioning profile names in `Fastfile` match exactly what you named them in Apple Developer Portal
- Verify all GitHub Secrets are set correctly
- Ensure the certificate isn't expired

### "Keychain password incorrect"
- The `KEYCHAIN_PASSWORD` secret can be any value - it's just for the temporary CI keychain

### Build succeeds but doesn't appear in TestFlight
- Check App Store Connect → TestFlight
- It can take 5-10 minutes for Apple to process the build
- Check for email from Apple about processing status

## Next Steps

After your first successful build:
- Set up external testing groups in App Store Connect
- Enable automatic distribution if desired
- Consider adding Slack/email notifications to the workflow
- Add version bumping for marketing versions (not just build numbers)

## Useful Commands

Run Fastlane locally to test:
```bash
bundle install
fastlane beta
```

Check GitHub Actions logs:
```bash
gh run list --workflow=testflight.yml
gh run view <run-id>
```
