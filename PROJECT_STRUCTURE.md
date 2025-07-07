# Whoosh Flutter App Structure

## Project Overview
Whoosh is a Flutter application focused on merchandising operations, order management, and manager oversight features. The app follows a well-organized structure using the GetX pattern for state management.

## Directory Structure

### Root Directory
```
whoosh/
├── android/           # Android platform-specific code
├── ios/               # iOS platform-specific code
├── lib/               # Main application code
├── assets/            # Static assets like images
├── test/              # Test files
├── web/               # Web platform-specific code
├── windows/           # Windows platform-specific code
├── macos/             # MacOS platform-specific code
├── linux/             # Linux platform-specific code
├── api/               # API-related files
├── pubspec.yaml       # Package dependencies and configuration
└── README.md          # Project documentation
```

### Main Application Code (lib/)
```
lib/
├── main.dart          # Application entry point
├── components/        # Reusable UI components
├── controllers/       # GetX controllers for state management
├── models/            # Data models
├── pages/             # Application screens/pages
├── routes/            # Navigation routes
├── services/          # API and other services
├── utils/             # Utility functions and constants
├── widgets/           # Common widgets
└── docs/              # Documentation files
```

### Pages Structure
```
pages/
├── 404/               # Error pages
├── Leave/             # Leave management
├── client/            # Client-related pages
├── home/              # Home screen pages
├── journeyplan/       # Journey planning pages
├── login/             # Authentication pages
├── managers/          # Manager-specific pages
├── notice/            # Notice board pages
├── order/             # Order management pages
├── profile/           # User profile pages
└── targets/           # Target-related pages
```

### Models
The app contains several data models including:
- JourneyPlan
- User
- Client
- Order
- Product
- Target
- Leave
- Notice Board
- Checkin Status
- Manager
- Office
- Token

## Key Features
Based on the file structure, this app appears to include:

1. **Authentication System**
   - Login functionality
   - Role-based access control (Merchandisers, Managers)

2. **Journey Plan Management**
   - Creation and management of visit/journey plans
   - Check-in/Check-out functionality for merchandising locations
   - Location tracking

3. **User Management**
   - User profiles
   - Leave management
   - Role-based permissions

4. **Client Management**
   - Client information
   - Outlet tracking

5. **Order System**
   - Product management
   - Order tracking

6. **Notice Board**
   - Communications system

7. **Merchandising Operations**
   - Product placement
   - Inventory tracking
   - Sales target management

## Application Flow
The application starts in `main.dart` which initializes key services and controllers. Authentication is handled first, and based on the user's role, they are directed to the appropriate home page (Manager Home or Regular Home).

## Technology Stack
- **Framework**: Flutter
- **State Management**: GetX
- **Local Storage**: GetStorage
- **UI Components**: Custom Material Theme with Google Fonts
- **Networking**: HTTP/Dio packages
- **Location Services**: Geolocator
- **Media Handling**: Camera, Image Picker

## Dependencies
Key dependencies include:
- get: ^4.6.5 - State management
- get_storage: ^2.1.1 - Local storage
- http: ^1.3.0 - API communication
- flutter_svg: ^2.0.5 - SVG rendering
- google_fonts: ^6.2.1 - Typography
- permission_handler: ^11.0.1 - Permissions
- geolocator: ^13.0.3 - Location services
- camera: ^0.11.1 - Camera functionality
- path_provider: ^2.1.5 - File system access
- dio: ^5.8.0+1 - HTTP client

## Theme
The application uses a custom theme with:
- Primary color: Gold
- Background: Light color
- Custom typography: Google's Quicksand font
- Rounded corners for cards and buttons
- Consistent input field styling

## Navigation
The app uses GetX routing system with named routes defined in `routes/app_routes.dart`.

## Security Features
The app implements:
- User authentication
- Inactivity timer for automatic logout
- Role-based access control

## Development Notes
- The app follows the GetX pattern for state management and dependency injection
- UI components are designed to be reusable
- The app appears to implement responsive design principles 
#Aded HIve
lib/
  ├── models/
  │   └── hive/
  │       ├── journey_plan_model.dart
  │       ├── order_model.dart
  │       ├── client_model.dart
  │       └── user_model.dart
  ├── services/
  │   └── hive/
  │       ├── journey_plan_hive_service.dart
  │       ├── order_hive_service.dart
  │       ├── client_hive_service.dart
  │       └── user_hive_service.dart
  └── utils/
      └── hive/
          └── hive_initializer.dart