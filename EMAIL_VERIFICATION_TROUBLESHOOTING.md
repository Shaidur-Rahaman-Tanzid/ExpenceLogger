# Email Verification Troubleshooting Guide

## 🔍 Common Reasons Why Verification Emails Don't Arrive

### 1. **Check Spam/Junk Folder**
   - Firebase verification emails sometimes get flagged as spam
   - Check your spam, junk, or promotions folder
   - Mark as "Not Spam" if found there

### 2. **Email Template Not Configured in Firebase Console**
   ⚠️ **MOST COMMON ISSUE** ⚠️
   
   **Steps to Configure:**
   1. Go to [Firebase Console](https://console.firebase.google.com)
   2. Select your project: **expence-logger**
   3. Click on **Authentication** in the left sidebar
   4. Go to **Templates** tab (top navigation)
   5. Click on **Email address verification**
   6. Customize the template:
      - **From name**: Your App Name (e.g., "Expense Logger")
      - **Reply-to email**: Your support email
      - **Subject**: Verify your email for Expense Logger
      - **Email body**: Customize the message (optional)
   7. Click **Save**

### 3. **Firebase Email Delivery Not Enabled**
   1. In Firebase Console → Authentication → Settings
   2. Scroll to **Authorized domains**
   3. Make sure your domain is listed
   4. Check **Email enumeration protection** settings

### 4. **Wait Time**
   - Emails can take 1-5 minutes to arrive
   - Sometimes up to 15 minutes during high load
   - Try resending after waiting

### 5. **Email Address Issues**
   - ✅ Verify the email address is typed correctly
   - ✅ No extra spaces before/after email
   - ✅ Email domain accepts emails (not a temporary/disposable email)
   - ✅ Check if email provider blocks automated emails

### 6. **Firebase Quota Limits**
   - Free plan has limits on emails sent per day
   - Check Firebase Console → Usage tab
   - Upgrade to Blaze plan if needed

### 7. **Testing with Gmail**
   - Gmail sometimes delays Firebase emails
   - Try with a different email provider to test
   - Check Gmail's **All Mail** folder

## 🛠️ Debugging Steps

### Step 1: Check Console Logs
When you sign up, check the debug console for:
```
✅ Verification email sent successfully to: your-email@example.com
```
Or error messages like:
```
⚠️ Error sending verification email: [error details]
```

### Step 2: Try Resend Button
1. Sign up with your email
2. Look for the **"Resend Verification"** button
3. Click it and check console logs
4. Message should say: "Verification email sent! Please check your inbox and spam folder."

### Step 3: Test with Different Email
Try signing up with different email providers:
- Gmail
- Outlook/Hotmail
- Yahoo
- ProtonMail
- Your work email

### Step 4: Verify Firebase Configuration
1. Firebase Console → Project Settings
2. Check that `expence-logger.firebaseapp.com` is in authorized domains
3. Authentication → Sign-in method → Email/Password should be **Enabled**

## 🔧 Manual Verification (For Testing Only)

If you need to test the app without email verification:

1. Go to Firebase Console
2. Authentication → Users
3. Find your user
4. Click the three dots → Edit user
5. Check "Email verified" checkbox

**Note:** This is only for testing. In production, users should verify via email.

## 📧 Email Template Configuration (Recommended)

### Customize Your Verification Email:

**Subject Line:**
```
Verify your email for Expense Logger
```

**Email Body Template:**
```
Hello %DISPLAY_NAME%,

Thank you for signing up for Expense Logger!

To complete your registration, please verify your email address by clicking the button below:

%LINK%

If you didn't create an account with Expense Logger, you can safely ignore this email.

Best regards,
The Expense Logger Team
```

## 🚨 Still Not Working?

### Contact Firebase Support:
1. Go to Firebase Console
2. Click the question mark icon (?)
3. Select "Contact Support"
4. Describe the issue

### Check Firebase Status:
- Visit: https://status.firebase.google.com/
- Check if there are any ongoing issues with Authentication

### Enable Debug Mode:
In your app, watch for these console messages:
- "✅ Verification email sent successfully"
- "⚠️ Error sending verification email"

### Alternative Solution:
Consider implementing phone number verification as a backup option.

## 📝 Notes

- Verification links expire after a certain time (usually 3 days)
- User can request multiple verification emails
- The "Check Status" button refreshes verification state after clicking link in email
- App will automatically detect when email is verified

---

**Project:** Expense Logger  
**Firebase Project:** expence-logger  
**Auth Domain:** expence-logger.firebaseapp.com
