# Playbook: The HubSpot to AWS SES Integration Journey

## Introduction
This document chronicles the end-to-end process of building and debugging a critical n8n workflow designed to send templated emails via AWS SES to contacts retrieved from HubSpot. The journey involved significant cleanup, meticulous security configuration, and iterative debugging. This playbook serves as the single source of truth for understanding, maintaining, and extending this workflow.

---

## Chapter 1: The Great AWS Cleanup

**The Challenge:** The project began with AWS SES assets, including verified identities and email templates, scattered across multiple AWS regions, primarily `eu-central-1` (Frankfurt). This decentralized setup created confusion and was a potential source of regional policy conflicts.

**The Solution:** A systematic cleanup and consolidation effort was undertaken.

1.  **Audit:** Using a dedicated IAM user (`n8n-ses-admin`) and the AWS CLI, a complete inventory of all SES assets was performed across all regions.
2.  **Consolidation:** All legacy assets were deleted from the Frankfurt region.
3.  **Re-creation:** All necessary identities (`lastapple.com`, `hank@lastapple.com`, `seo@lastapple.com`) were re-created and verified in a single target region: **`us-west-2` (Oregon)**. This established a clean, predictable foundation for the project.

**Key Takeaway:** Centralizing cloud resources in a single, dedicated region is paramount for maintainability, security, and avoiding configuration errors.

---

## Chapter 2: Forging the Connections

With a clean AWS environment, the next step was to establish secure connections for the n8n workflow.

### HubSpot Connectivity

- **Initial Approach:** An OAuth2-based connection was attempted but proved unreliable due to persistent scope and handshake issues.
- **Final Solution:** The connection was successfully and robustly established using a **HubSpot Private App Token**. This method provided direct, secure access without the complexities of OAuth2.
- **Credential Used:** `HubSpot Token 4 Last Apple Biz`

### AWS SES IAM Security

A dedicated, minimal-permission IAM user (`n8n-ses-sender`) was created to ensure the n8n workflow had only the permissions it absolutely required.

**Final IAM Policy (`n8n-SES-Send-and-List-Policy`):**
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ses:SendEmail",
                "ses:SendRawEmail",
                "ses:ListTemplates",
                "ses:SendTemplatedEmail"
            ],
            "Resource": "*",
            "Condition": {
                "StringEquals": {
                    "aws:RequestedRegion": "us-west-2"
                }
            }
        }
    ]
}
```

---

## Chapter 3: The Workflow - Debugging a Saga

This section details the final, working configuration of the n8n workflow and the iterative debugging process that led to it.

### Final Workflow Structure

The workflow consists of three nodes connected in sequence:
1.  **HubSpot Trigger:** Initiates the workflow when a contact property changes.
2.  **Get a contact:** Uses the contact ID from the trigger to fetch the full contact details.
3.  **Send an email based on a template:** Sends the email using the contact's information.

### The Troubleshooting Playbook

This is a log of the errors encountered and their definitive solutions.

| Error Message | Cause | Solution |
| :--- | :--- | :--- |
| `Illegal address` | The `To Addresses` field was receiving a full JSON object from HubSpot instead of a simple email string. | Use the expression `{{ $json.properties.email.value }}` to extract the email string from the object. |
| `ValidationError: templateData must not be null` | The `Template Data` field was empty. AWS requires this field to be a valid JSON string, even if the template has no variables. | Use the expression `{{ JSON.stringify({}) }}` in the `Template Data` field. |
| `AccessDenied: ... not authorized to perform ses:SendTemplatedEmail` | The IAM policy for the `n8n-ses-sender` user was missing the specific permission for sending *templated* emails. | Add `"ses:SendTemplatedEmail"` to the `Action` array in the IAM policy. |
| `MessageRejected: Email address is not verified` | The AWS SES account for the `us-west-2` region was in the sandbox, restricting sending to only verified recipient addresses. | Submitted a request to AWS to move the account to production. This was approved, lifting the restriction. |

---

## Appendix: Final Node Configuration

*Extracted from `HubSpot to AWS SES.json`*

**HubSpot 'Get a contact' Node:**
- **Authentication:** `Private App Token`
- **Contact ID:** `{{ $('HubSpot Trigger').item.json.contactId }}`

**AWS SES 'Send an email' Node:**
- **Operation:** `Send Template`
- **From Email:** `hank@lastapple.com`
- **To Addresses:** `{{ $json.properties.email.value }}`
- **Template Data:** `{{ JSON.stringify({}) }}`
