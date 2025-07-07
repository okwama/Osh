# 🚗 MOTORGAS App - How We Handle Data (Simple Guide)

## 📖 What This Guide Is About

This guide explains how our MOTORGAS app talks to the database (like a giant digital filing cabinet) to get and save information, without using traditional APIs. Think of it like having a direct phone line to the database!

---

## 🎯 What You'll Learn

1. **How we connect to the database** (like plugging in a phone)
2. **How we get information** (like asking questions)
3. **How we save information** (like writing in a notebook)
4. **How we handle different devices** (phones vs computers)
5. **How we keep things safe** (like using a secret password)

---

## 🔌 Part 1: How We Connect to the Database

### What is a Database?
Think of a database like a giant digital filing cabinet that stores all the information for our app:
- User accounts (like who works at the company)
- Leave requests (when someone wants time off)
- Notices (important messages for everyone)
- Orders (what customers want to buy)
- And much more!

### How We Connect
```dart
// This is like dialing a phone number to talk to the database
static const String _host = '102.218.215.35';  // The database's "phone number"
static const String _user = 'citlogis_bryan';   // Our username (like our name)
static const String _password = '@bo9511221.qwerty';  // Our secret password
static const String _database = 'citlogis_forecourt'; // Which filing cabinet to use
static const int _port = 3306;  // Which "door" to use
```

**In Simple Terms:** 
- We have the database's address (like a house address)
- We have our special username and password (like keys to the house)
- We connect directly to the database (like walking into the house)

---

## 📱 Part 2: How We Handle Different Devices

### Mobile Phones vs Web Browsers
Our app works differently depending on what device you're using:

#### 📱 On Mobile Phones (Android/iOS):
- We connect directly to the MySQL database
- It's like having a direct phone line to the database
- We can do everything: read, write, update, delete

#### 🌐 On Web Browsers:
- We can't connect directly to MySQL (browsers don't allow it)
- We use a simple "fake" system that works with stored data
- It's like having a local copy of the important information

```dart
// This code checks what device we're using
if (kIsWeb) {
  // We're on a web browser - use simple local storage
  print('🌐 Using simple storage for web browser');
} else {
  // We're on a mobile phone - connect to real database
  print('📱 Using real database for mobile phone');
}
```

---

## 📥 Part 3: How We Get Information (Fetching Data)

### Getting User Information
When someone logs in, here's what happens:

```dart
// 1. User enters phone number and password
// 2. We ask the database: "Is this person real?"
final sql = '''
  SELECT id, name, phone, password, role_id, role, 
         empl_no, id_no, photo_url, status, created_at
  FROM staff 
  WHERE phone = ? AND status = 1
''';

// 3. Database sends back the answer
final result = await _db.query(sql, [phoneNumber]);
```

**In Simple Terms:**
1. User types their phone number and password
2. We send a message to the database: "Hey, is this person real?"
3. Database checks its records and sends back: "Yes, here's their information" or "No, I don't know them"
4. If they're real, we let them into the app!

### Getting Leave Requests
When we want to see someone's leave requests:

```dart
// Ask database: "Show me all leave requests for this person"
const sql = '''
  SELECT 
    sl.id, sl.staff_id, sl.leave_type_id, sl.start_date, sl.end_date,
    sl.is_half_day, sl.reason, sl.status, sl.approved_by, sl.attachment_url,
    sl.applied_at, sl.updated_at,
    lt.name as leave_type_name
  FROM staff_leaves sl
  JOIN leave_types lt ON sl.leave_type_id = lt.id
  WHERE sl.staff_id = ?
  ORDER BY sl.applied_at DESC
''';

final results = await _db.query(sql, [staffId]);
```

**In Simple Terms:**
1. We ask: "Show me all the times this person asked for time off"
2. Database sends back a list of all their leave requests
3. We show this list to the user

### Getting Notices
When we want to see company notices:

```dart
// Ask database: "Show me all the important messages"
const sql = '''
  SELECT 
    id, title, content, created_at, updated_at, created_by
  FROM notices 
  ORDER BY created_at DESC
''';

final results = await _db.query(sql);
```

**In Simple Terms:**
1. We ask: "What important messages does the company want everyone to see?"
2. Database sends back all the notices
3. We show them to the user

---

## 📤 Part 4: How We Save Information (Posting Data)

### Creating a New Leave Request
When someone wants to request time off:

```dart
// 1. User fills out a form with their leave details
// 2. We save this information to the database
const sql = '''
  INSERT INTO staff_leaves (
    staff_id, leave_type_id, start_date, end_date,
    is_half_day, reason, status, applied_at
  )
  VALUES (?, ?, ?, ?, ?, ?, 'pending', CURRENT_TIMESTAMP)
''';

final affectedRows = await _db.execute(sql, [
  staffId, leaveTypeId, startDate, endDate, isHalfDay, reason
]);
```

**In Simple Terms:**
1. User fills out a form: "I want time off from this date to that date"
2. We send this information to the database
3. Database saves it in its records
4. Now everyone can see this leave request

### Creating a New Notice
When someone wants to post a company notice:

```dart
// 1. User writes a notice title and content
// 2. We save it to the database
const sql = '''
  INSERT INTO notices (title, content, created_by)
  VALUES (?, ?, ?)
''';

final affectedRows = await _db.execute(sql, [
  notice.title, notice.content, notice.createdBy
]);
```

**In Simple Terms:**
1. User writes: "Important: Company meeting tomorrow!"
2. We send this message to the database
3. Database saves it
4. Now everyone in the app can see this notice

### Updating Information
When we want to change something:

```dart
// Update a leave request status (approve or reject)
const sql = '''
  UPDATE staff_leaves 
  SET status = ?, approved_by = ?, updated_at = CURRENT_TIMESTAMP
  WHERE id = ?
''';

final affectedRows = await _db.execute(sql, [newStatus, approverId, leaveId]);
```

**In Simple Terms:**
1. Manager decides: "I approve this leave request"
2. We tell the database: "Change this leave request status to 'approved'"
3. Database updates its records
4. Now the leave request shows as approved

---

## 🔒 Part 5: How We Keep Things Safe

### Password Protection
We don't store passwords as plain text (that would be like writing your password on a piece of paper for everyone to see). Instead, we use something called "hashing":

```dart
// When someone creates a password, we scramble it
static String _hashPassword(String password) {
  return BCrypt.hashpw(password, BCrypt.gensalt());
}

// When someone logs in, we check if their password matches
static bool _verifyPassword(String password, String storedHash) {
  return BCrypt.checkpw(password, storedHash);
}
```

**In Simple Terms:**
1. User creates password: "mypassword123"
2. We scramble it into something like: "a1b2c3d4e5f6..."
3. We save the scrambled version
4. When they log in, we scramble their input and compare
5. If they match, we let them in!

### Connection Safety
We make sure our connection to the database is safe:

```dart
// We try to connect multiple times if it fails
static const int _maxRetries = 3;
static const Duration _connectionTimeout = Duration(seconds: 15);
static const Duration _retryDelay = Duration(seconds: 2);
```

**In Simple Terms:**
1. If the connection fails, we try again (up to 3 times)
2. We don't wait forever (15 seconds max)
3. We wait a bit between tries (2 seconds)
4. This makes sure the app doesn't crash if there's a temporary problem

---

## 🔄 Part 6: How We Handle Problems

### What Happens When Things Go Wrong?

#### Connection Problems
```dart
try {
  // Try to connect to database
  _connection = await MySqlConnection.connect(settings);
} catch (e) {
  // If it fails, try again
  print('❌ Connection failed: $e');
  // Try again up to 3 times
}
```

**In Simple Terms:**
- If we can't reach the database, we try again
- We don't give up after one failure
- We tell the user what's happening

#### Data Problems
```dart
try {
  // Try to get data
  final results = await _db.query(sql, params);
  return results;
} catch (e) {
  // If it fails, show an error
  print('❌ Query failed: $e');
  return []; // Return empty list instead of crashing
}
```

**In Simple Terms:**
- If we can't get the data, we show an empty list
- We don't crash the app
- We tell the user there was a problem

---

## 📊 Part 7: Real Examples

### Example 1: User Login
**What the user sees:**
1. User opens the app
2. User types phone number: "0706166875"
3. User types password: "admin"
4. User taps "Login"

**What happens behind the scenes:**
1. App connects to database
2. App asks: "Is there a user with phone 0706166875?"
3. Database checks and finds: "Yes, here's their info"
4. App checks: "Does the password match?"
5. App says: "Welcome, Benjamin Okwama!"

### Example 2: Requesting Leave
**What the user sees:**
1. User goes to Leave section
2. User taps "Request Leave"
3. User fills out form:
   - Leave type: "Annual Leave"
   - Start date: "2024-01-15"
   - End date: "2024-01-17"
   - Reason: "Family vacation"
4. User taps "Submit"

**What happens behind the scenes:**
1. App connects to database
2. App sends: "Save this leave request"
3. Database saves: "Benjamin wants 3 days off for family vacation"
4. App shows: "Leave request submitted successfully!"

### Example 3: Reading Notices
**What the user sees:**
1. User goes to Notice Board
2. User sees list of notices

**What happens behind the scenes:**
1. App connects to database
2. App asks: "Show me all notices"
3. Database sends back all notices
4. App displays them in a nice list

---

## 🎯 Summary

### What We Learned:
1. **Direct Connection**: Our app talks directly to the database (no middleman API)
2. **Different Devices**: Works differently on phones vs web browsers
3. **Getting Data**: We ask the database questions and get answers back
4. **Saving Data**: We send information to the database to store it
5. **Safety**: We protect passwords and handle problems gracefully
6. **Real Examples**: We saw how login, leave requests, and notices work

### Key Benefits:
- ✅ **Fast**: Direct connection means faster responses
- ✅ **Reliable**: We handle problems and retry when needed
- ✅ **Safe**: Passwords are protected and connections are secure
- ✅ **Flexible**: Works on different devices in different ways

### Think of it Like:
- **Database** = Giant digital filing cabinet
- **Our App** = Smart assistant that can read and write in the filing cabinet
- **Connection** = Direct phone line to the filing cabinet
- **Queries** = Questions we ask the filing cabinet
- **Results** = Answers the filing cabinet sends back

This is how our MOTORGAS app handles all its data without needing traditional APIs! 🚗✨ 