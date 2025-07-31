---
author: Cascade (AI Agent)
date: 2025-07-14
---

# SES Minimal Footprint – 2025-07-14

## Overview

This document summarizes the final state of the AWS Simple Email Service (SES) configuration after a comprehensive audit and cleanup. The primary goal was to consolidate assets, remove unused configurations, and standardize on a single US-based AWS region.

**Actions Taken:**
*   A full audit of all AWS regions was performed.
*   All existing SES assets (identities and templates) were found in the `eu-central-1` (Frankfurt) region.
*   All assets in `eu-central-1` were deleted to create a clean slate.
*   The desired domains and email addresses were re-created and verified in the `us-west-2` region.

## Final SES Configuration

All SES assets are now located exclusively in the **`us-west-2`** region.

### Verified Identities

| Type       | Identity Name         | Verification | DKIM Status |
| :--------- | :-------------------- | :----------- | :---------- |
| **Domain** | `lastapple.com`       | `SUCCESS`    | `SUCCESS`   |
| **Domain** | `email.lastapple.com` | `SUCCESS`    | `SUCCESS`   |
| **Email**  | `hank@lastapple.com`  | `SUCCESS`    | `SUCCESS`   |
| **Email**  | `seo@lastapple.com`   | `SUCCESS`    | `SUCCESS`   |

### Templates

There are currently no email templates configured.

## Next Steps & Recommendations

1.  **DNS Cleanup:** It is recommended to remove the old, now-obsolete DNS records related to the previous `eu-central-1` SES configuration to avoid confusion.
2.  **Custom MAIL-FROM:** The current setup uses the default SES MAIL-FROM domain. For improved deliverability and branding, you may consider setting up a custom MAIL-FROM domain for `lastapple.com` and `email.lastapple.com` in the `us-west-2` region.

This completes the SES audit and cleanup. The current configuration is clean, consolidated, and located in the preferred AWS region.
