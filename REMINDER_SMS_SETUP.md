# Firebase Cloud Functions - Reminder SMS Implementation Guide

## ✅ What We've Done

### 1. **Created Cloud Function** (`functions/src/functions/sendReminderSMS.js`)
   - Scheduled to run **every 5 minutes**
   - Queries rentals ending in next **15 minutes**
   - Sends reminder SMS via Beem Africa API
   - Marks reminder as sent in Firestore

### 2. **Updated Flutter App** 
   - `rented_power_bank_service.dart`: Added fields for Cloud Function:
     - `rentalEndTime`: For Cloud Function to query
     - `reminderSMSSent`: To track if reminder was sent
     - `userPhoneNumber`: User's phone for SMS
     - `userName`: User's name for SMS

### 3. **Updated Functions Index**
   - Exported `sendReminderSMSFunction` (scheduled)
   - Exported `sendReminderSMSManual` (for testing)

---

## 🚀 Deployment Steps

### Step 1: Install Firebase CLI
```bash
npm install -g firebase-tools
```

### Step 2: Login to Firebase
```bash
firebase login
```

### Step 3: Deploy Functions
```bash
cd /Users/beginnertech/Documents/Code/Project/SMARTCHAJA/SMARTCHAJA-V2/functions
npm install
firebase deploy --only functions
```

---

## 📊 How It Works

### **Timeline:**
1. **User rents power bank** (e.g., 2:00 PM)
   - Rental ends at: 6:00 PM
   - Reminder triggers at: 5:45 PM (15 mins before)

2. **Cloud Function runs every 5 minutes**
   - Checks Firestore for rentals ending in next 15 mins
   - Finds the rental ending at 6:00 PM
   - Sends reminder SMS to user
   - Marks `reminderSMSSent = true`

3. **User receives SMS:**
   ```
   SmartChaja Reminder: Your rental time is almost over. 
   Please return the power bank to any SmartChaja station 
   to avoid extra charges.
   ```

4. **When user returns power bank**
   - Return SMS sent: "Power bank returned successfully..."

---

## 🧪 Testing Manually

### Option A: Via Cloud Functions Console
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project
3. Go to **Functions**
4. Find `sendReminderSMSFunction`
5. Click **Testing** tab

### Option B: Call the Function from Flutter App
```dart
import 'package:cloud_functions/cloud_functions.dart';

Future<void> testReminderSMS() async {
  try {
    final callable = FirebaseFunctions.instance.httpsCallable('sendReminderSMSManual');
    final result = await callable.call({
      'phoneNumber': '0778412125',
      'deviceId': 'PB-001',
    });
    print('Result: ${result.data}');
  } catch (e) {
    print('Error: $e');
  }
}
```

---

## 📋 Firestore Document Structure

When user rents power bank, document looks like:

```json
{
  "userId": "firebase_auth_uid",
  "deviceId": "PB-001",
  "tradeNo": "TXN123456",
  "planName": "30 min rental",
  "rentStartDate": "2026-01-15T14:00:00Z",
  "rentEndDate": "2026-01-15T14:30:00Z",
  "rentalEndTime": "2026-01-15T14:30:00Z",
  "reminderSMSSent": false,
  "userPhoneNumber": "0778412125",
  "userName": "John Doe",
  "status": "rented"
}
```

Cloud Function will:
- ✅ Find rentals where `remindS MSSent == false`
- ✅ And `rentalEndTime` is between now and 15 minutes from now
- ✅ Send SMS
- ✅ Update `reminderSMSSent = true`

---

## ⚙️ Configuration

### Reminder Timing
Edit `functions/src/functions/sendReminderSMS.js`:

```javascript
// Change this line to adjust reminder timing
const fifteenMinutesFromNow = new Date(now.getTime() + 15 * 60 * 1000);
// 15 * 60 * 1000 = 15 minutes
// 30 * 60 * 1000 = 30 minutes before rental ends
```

### Execution Frequency
Edit `functions/src/functions/sendReminderSMS.js`:

```javascript
// Change this schedule
.schedule("every 5 minutes")  // Run every 5 minutes
// Options: every 1 minutes, every 15 minutes, every hour, etc.
```

---

## 💰 Cost Estimation

- **Invocation cost**: ~$0.40 per 1 million invocations
- **Running every 5 minutes**: ~288 invocations per day
- **Monthly cost**: ~$3-5 for all rentals

---

## 🔍 Monitoring & Logs

### View Function Logs:
```bash
firebase functions:log
```

### Or in Firebase Console:
1. Go to **Functions** → **Logs**
2. Filter by function name: `sendReminderSMSFunction`
3. View real-time logs

---

## ⚠️ Important Notes

1. **Firestore Rules**: Ensure your security rules allow Cloud Functions to read/write:
   ```
   match /rented_power_banks/{document=**} {
     allow read: if request.auth != null;
     allow write: if request.auth.uid == resource.data.userId;
   }
   ```

2. **SMS Cost**: Each reminder SMS costs money. Check Beem Africa pricing.

3. **Time Zones**: Cloud Functions use UTC. Adjust if needed.

4. **Errors**: Check logs if SMS not sending. Could be:
   - Phone number not formatted correctly
   - No Beem Africa API key
   - User doesn't have phone number saved

---

## 📱 Next Steps

1. **Deploy**: `firebase deploy --only functions`
2. **Test**: Rent a power bank and wait 15 mins before end
3. **Monitor**: Check logs for any errors
4. **Adjust**: Fine-tune reminder timing based on user feedback

---

**Need help?** Check Firebase Functions documentation or Cloud Function logs for errors.
