# Version Check API Implementation

## Overview
This document provides an example of how to implement a backend API endpoint for version checking in your Woosh app.

## API Endpoint

### GET /api/app/version

**Purpose**: Returns the latest version information for the app

**Response Format**:
```json
{
  "version": "1.0.2",
  "buildNumber": "13",
  "releaseNotes": "Bug fixes and performance improvements",
  "forceUpdate": false,
  "minVersion": "1.0.0",
  "platform": "both" // "android", "ios", or "both"
}
```

**Response Fields**:
- `version`: Latest version string (e.g., "1.0.2")
- `buildNumber`: Build number (e.g., "13")
- `releaseNotes`: What's new in this version
- `forceUpdate`: Whether this update is mandatory
- `minVersion`: Minimum supported version
- `platform`: Target platform for this version

## Implementation Examples

### Node.js/Express Example
```javascript
app.get('/api/app/version', (req, res) => {
  const platform = req.query.platform || 'both';
  
  const versionInfo = {
    version: "1.0.2",
    buildNumber: "13",
    releaseNotes: "Fixed journey plan issues and improved performance",
    forceUpdate: false,
    minVersion: "1.0.0",
    platform: platform
  };
  
  res.json(versionInfo);
});
```

### PHP Example
```php
<?php
header('Content-Type: application/json');

$versionInfo = [
    'version' => '1.0.2',
    'buildNumber' => '13',
    'releaseNotes' => 'Fixed journey plan issues and improved performance',
    'forceUpdate' => false,
    'minVersion' => '1.0.0',
    'platform' => $_GET['platform'] ?? 'both'
];

echo json_encode($versionInfo);
?>
```

### Python/Flask Example
```python
from flask import Flask, jsonify, request

app = Flask(__name__)

@app.route('/api/app/version')
def get_version():
    platform = request.args.get('platform', 'both')
    
    version_info = {
        'version': '1.0.2',
        'buildNumber': '13',
        'releaseNotes': 'Fixed journey plan issues and improved performance',
        'forceUpdate': False,
        'minVersion': '1.0.0',
        'platform': platform
    }
    
    return jsonify(version_info)
```

## Update the Version Check Service

Once you have the API endpoint, update the `_getLatestVersionInfo()` method in `lib/services/version_check_service.dart`:

```dart
Future<Map<String, dynamic>?> _getLatestVersionInfo() async {
  try {
    // Replace with your actual API endpoint
    final response = await http.get(
      Uri.parse('https://your-api.com/api/app/version'),
      headers: {
        'Content-Type': 'application/json',
      },
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return {
        'version': data['version'],
        'buildNumber': data['buildNumber'],
        'releaseNotes': data['releaseNotes'],
        'forceUpdate': data['forceUpdate'] ?? false,
        'minVersion': data['minVersion'],
      };
    }

    // Fallback to app store scraping
    return await _scrapeAppStoreInfo();
  } catch (e) {
    debugPrint('Error fetching latest version info: $e');
    return null;
  }
}
```

## Benefits of Using Your Own API

1. **Real-time Updates**: Update version info without waiting for app store propagation
2. **Detailed Release Notes**: Provide comprehensive update information
3. **Force Updates**: Make certain updates mandatory
4. **Platform-specific Versions**: Different versions for Android/iOS
5. **Analytics**: Track update adoption rates
6. **A/B Testing**: Roll out updates gradually

## Security Considerations

1. **Rate Limiting**: Prevent abuse of the version check endpoint
2. **Authentication**: Consider adding API keys for production
3. **HTTPS**: Always use HTTPS in production
4. **Validation**: Validate version strings and build numbers
5. **Caching**: Implement appropriate caching headers

## Testing

Test your version check by:
1. Deploying the API endpoint
2. Updating the URL in the Flutter app
3. Incrementing the version in `pubspec.yaml`
4. Building and testing the app
5. Verifying the update dialog appears 