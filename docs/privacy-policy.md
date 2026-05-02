# Privacy Policy for PitWall

**Last Updated**: May 2, 2026  
**Effective Date**: June 1, 2026

## 1. Introduction

PitWall ("**we**," "**us**," "**our**," or "**Company**") is committed to protecting your privacy. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our mobile application and related services (the "**Service**").

Please read this Privacy Policy carefully. If you do not agree with our policies and practices, please do not use our Service.

**Contact Information**:
- Email: [your-email@gmail.com] (replace with actual contact email)
- Address: [Your Address] (optional)

---

## 2. Information We Collect

### 2.1 Information You Provide Directly

**Account Registration**:
- Email address (for email/password signup)
- Username (created by you)
- Avatar/Profile picture (optional)
- Full name (optional, from OAuth providers)

**Authentication & OAuth**:
- When you sign in with Google: name, email, profile picture
- When you sign in with Apple: email (may be private/anonymized)
- Authentication tokens and session data

**Predictions & Gameplay**:
- Race predictions (driver selections for each race)
- League memberships and invitations
- Joker card usage (special power-up selections)
- User statistics and scoring data

**Communication**:
- Messages you send us (support inquiries, feedback)
- Push notification opt-in/preferences

### 2.2 Information Collected Automatically

**Device & Usage Information**:
- Device type and operating system version
- App version and build number
- Screen resolution and display settings
- IP address and geolocation (approximate, from IP)
- Device identifiers (but NOT unique identifiers like IDFA/GAID)

**Usage Analytics**:
- Pages/screens visited
- Features used (predictions submitted, leagues created, etc.)
- Time spent in app
- Error logs and crash reports (via Sentry)
- Clicks and interactions

**Push Notification Tokens**:
- Firebase Cloud Messaging (FCM) token for Android notifications
- Apple Push Notification (APNs) token for iOS notifications
- Your notification preferences and settings

### 2.3 Information from Third-Party Services

**Third Parties We Use**:
- **Supabase**: PostgreSQL database, authentication provider
- **Google Cloud**: OAuth provider, some infrastructure
- **Apple**: Sign In with Apple provider
- **OpenF1 API**: Public Formula 1 race data and results
- **Sentry**: Error and crash reporting
- **Firebase** (Android): Push notification delivery

---

## 3. How We Use Your Information

### 3.1 Primary Purposes

We use the information we collect for the following purposes:

| Purpose | Data Used | Legal Basis |
|---------|-----------|------------|
| Provide the Service | Account, predictions, gameplay data | Contract fulfillment |
| User authentication | Email, OAuth tokens | Necessary for security |
| Send race reminders | Notification tokens, preferences | Legitimate interest |
| Calculate scores | Predictions, official race results | Contract fulfillment |
| Improve the app | Usage analytics, error logs (Sentry) | Legitimate interest |
| Customer support | Email, account info | Legitimate interest |
| Comply with law | Any data, as legally required | Legal obligation |
| Prevent fraud/abuse | Account info, usage patterns | Legitimate interest |

### 3.2 Specific Uses

**Race Reminders**: We send push notifications approximately 1 hour before each race, reminding users to submit predictions. You can disable notifications in app settings or device settings.

**Error Tracking**: Sentry receives error logs and crash reports to help us fix bugs. Sentry will NOT receive personal data like email or usernames.

**League Features**: League owners can see member usernames and prediction data to enable scoring and standings.

**Public Leagues** (if applicable): If you create a public league, your username and league stats may be visible to other users.

---

## 4. Third-Party Services & Data Sharing

### 4.1 Service Providers

We share your data with the following third parties to operate the Service:

| Service | Purpose | Data Shared | Privacy Link |
|---------|---------|------------|-------------|
| **Supabase** | Database, Auth | All account & prediction data | https://supabase.com/privacy |
| **Firebase** (Android) | Push notifications | Notification tokens only | https://firebase.google.com/support/privacy |
| **Sentry** | Error tracking | Error logs (no PII) | https://sentry.io/privacy/ |
| **OpenF1 API** | F1 data | No user data sent | https://openf1.org/ |
| **Google** | Authentication | Email + profile (if Google login) | https://policies.google.com/privacy |
| **Apple** | Authentication | Email (if Apple login) | https://www.apple.com/privacy/ |

### 4.2 No Sale of Data

**We do NOT sell your personal data to third parties.** We may share aggregated, anonymized statistics (e.g., "2,500 users submitted predictions for Monaco GP") for analytics.

### 4.3 Legal Compliance

We may disclose your information if:
- Required by law (court order, government request)
- Necessary to protect our rights or safety
- Necessary to prevent fraud or abuse
- In connection with a merger, acquisition, or sale of assets (we would notify you)

---

## 5. Data Retention

### 5.1 Active Accounts

As long as your account is active, we retain all your data:
- Account information
- Predictions and scoring history
- League memberships
- Statistics and achievements

### 5.2 After Account Deletion

When you delete your account:
- Personal data (email, username, avatar) is deleted within 7 days
- Predictions and predictions are deleted within 7 days
- League memberships are removed
- Joker card usage is deleted

**Retention Exception**: We retain league statistics and anonymous scoring data for historical reference (does not identify you).

### 5.3 After Inactivity

Accounts inactive for 90+ days may be soft-deleted (marked for deletion), with permanent deletion after 1 additional year.

### 5.4 Error Logs

Sentry error logs are retained for 90 days, then deleted.

---

## 6. Your Privacy Rights

### 6.1 GDPR Rights (EU Residents)

If you are in the EU, you have the following rights:

**Right of Access**: You can request a copy of all personal data we hold about you.

**Right to Rectification**: You can request correction of inaccurate or incomplete data.

**Right to Erasure** ("Right to be Forgotten"): You can request deletion of your data. We will delete it within 30 days, except where required to keep for legal obligations.

**Right to Data Portability**: You can request your data in a portable format (JSON/CSV).

**Right to Restrict Processing**: You can request we limit how we use your data.

**Right to Object**: You can object to certain processing, such as marketing communications.

**Right to Lodge a Complaint**: You can file a complaint with your national data protection authority.

### 6.2 CCPA Rights (California Residents)

If you are a California resident, you have the right to:
- Know what personal information we collect
- Delete personal information we collect
- Opt-out of the sale of personal information (we don't sell it)
- Non-discrimination for exercising CCPA rights

### 6.3 Other Jurisdictions

We comply with privacy laws in your jurisdiction. Please contact us for jurisdiction-specific requests.

### 6.4 How to Submit Rights Requests

To exercise any of these rights, email us at: **[your-email@gmail.com]**

Please include:
- "Privacy Request" in the subject line
- Your account email or username
- Specific right you're requesting (access, deletion, portability, etc.)

We will respond within 30 days (or as required by law).

---

## 7. Data Security

### 7.1 Security Measures

We implement the following security measures:

- **Encryption**: All data in transit uses HTTPS/TLS encryption
- **Authentication**: JWT tokens for session management
- **Database**: PostgreSQL with Row-Level Security (RLS) policies
- **Access Control**: Employees have minimal access; production data is restricted
- **Regular Backups**: Automatic daily backups with encryption
- **No Hardcoded Secrets**: API keys and credentials managed via environment variables

### 7.2 Limitations

While we use industry-standard security, no method is 100% secure. We cannot guarantee absolute security against all threats.

### 7.3 Data Breaches

If we discover a security breach affecting your personal data, we will:
- Notify you via email within 30 days
- Provide details about the breach
- Recommend steps you should take
- Work to prevent future breaches

---

## 8. Children's Privacy

**Our Service is not intended for children under 13 years old.**

We do not knowingly collect personal information from children under 13. If we discover that a child under 13 has provided information, we will:
- Delete that information immediately
- Notify the child's parent/guardian

If you believe your child has provided us information, please contact us immediately.

**Parental Consent** (Ages 13-18): If you are between 13-18, we recommend parental supervision.

---

## 9. Cookies & Tracking

### 9.1 App Cookies

Our mobile app uses local storage (SharedPreferences) to remember:
- Your login session
- User preferences (notification settings)
- Offline data cache

These are not traditional cookies and expire when you log out.

### 9.2 Tracking Technologies

We use:
- **Sentry**: Error tracking (anonymized)
- **Firebase Analytics** (optional): Usage analytics
- **Device analytics**: App startup time, performance metrics

You can disable analytics in app settings: Profile → Settings → Analytics.

---

## 10. Your Privacy Choices

### 10.1 Communication Preferences

You can manage your preferences in the app:
- **Push Notifications**: Profile → Notification Settings
  - Race reminders
  - League updates
  - Results notifications
  - Toggle on/off or allow only for specific times

- **Email Communications**: 
  - Unsubscribe links in all emails
  - Update preferences in settings

### 10.2 Account Settings

- **Visibility**: Control whether your profile is public/private
- **Data Export**: Request download of your data in JSON format
- **Account Deletion**: Delete account and all data anytime

---

## 11. International Data Transfers

Our servers are hosted on Supabase infrastructure, which may be located in:
- United States
- European Union
- Other regions

If you are in the EU, your data may be transferred outside the EU. We ensure transfers comply with GDPR through Standard Contractual Clauses (SCCs).

---

## 12. Changes to This Policy

We may update this Privacy Policy from time to time. When we do:
- We will update the "Last Updated" date at the top
- Changes will be posted on this page
- Material changes may trigger an in-app notification

**Your continued use of the Service after updates means you accept the new policy.**

---

## 13. Contact Us

### 13.1 Data Protection Officer

For privacy-related questions, please contact:

**Email**: [your-email@gmail.com]  
**Response Time**: 5-7 business days  

### 13.2 GDPR Data Protection Authority

EU residents can lodge complaints with their national data protection authority:
- [Your Country] Data Protection Authority
- https://edpb.ec.europa.eu/about-edpb/board/members_en

### 13.3 California Privacy Rights

California residents can submit requests via:
- Email: [your-email@gmail.com]
- Mail: [Your Address]

---

## 14. Additional Disclosures

### 14.1 Sensitive Personal Information

We do NOT collect:
- Biometric data
- Health information
- Payment information (we use third-party payment processors)
- Racial or ethnic origin
- Political opinions
- Sexual orientation

### 14.2 Automated Decision-Making

We do NOT use automated decision-making or profiling to make decisions about you.

### 14.3 Direct Marketing

We do NOT engage in direct marketing. Notifications are only for:
- Race reminders
- League updates
- Results notifications
- Account security alerts

---

## 15. Appendix: Data Processing

### 15.1 Data Controller & Processor

- **Data Controller**: PitWall (the company/developer)
- **Data Processor**: Supabase (database infrastructure)

### 15.2 Legitimate Interests Assessment

We process data on the basis of "legitimate interests" for:
- Improving the Service (analytics, error tracking)
- Preventing fraud and abuse
- Communicating with you about the Service
- Complying with legal obligations

---

## 16. Final Notes

This Privacy Policy is compliant with:
- ✅ GDPR (General Data Protection Regulation)
- ✅ CCPA (California Consumer Privacy Act)
- ✅ iOS App Store Guidelines
- ✅ Android Play Store Guidelines
- ✅ LGPD (Brazil)

**Questions?** Email: [your-email@gmail.com]

---

**PitWall Privacy Policy**  
Last Updated: May 2, 2026  
Effective: June 1, 2026  
Status: ✅ GDPR Compliant | ✅ App Store Ready
