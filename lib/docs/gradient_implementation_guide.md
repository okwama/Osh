# Gold Gradient Implementation Guide

This guide provides instructions for implementing the gold gradient theme consistently across all pages in the Woosh app.

## Color Palette

### Brand Gradient
The gold gradient is defined as:
```css
linear-gradient(90deg, #AE8625, #F7EF8A, #D2AC47, #EDC967)
```

These colors are available in our theme as:
- `goldStart`: #AE8625
- `goldMiddle1`: #F7EF8A
- `goldMiddle2`: #D2AC47
- `goldEnd`: #EDC967

### Background Colors
- App Background: #F4EBD0 (cream/beige background)

## Required Imports

Add these imports to all pages where you want to use the gradient:

```dart
import 'package:woosh/utils/app_theme.dart';
import 'package:woosh/widgets/gradient_widgets.dart';
import 'package:woosh/widgets/gradient_app_bar.dart';
import 'package:woosh/widgets/cream_gradient_card.dart';
```

## Common UI Elements to Replace

### 1. AppBar Replacement

**Replace this:**
```dart
appBar: AppBar(
  title: Text('Page Title'),
  // other properties
)
```

**With this:**
```dart
appBar: GradientAppBar(
  title: 'Page Title',
  // other properties
)
```

### 2. Text with Gradient

**Replace this:**
```dart
Text(
  'Some Text',
  style: TextStyle(
    color: goldColor, // or Color(0xFFDAA520)
    // other style properties
  ),
)
```

**With this:**
```dart
GradientText(
  'Some Text',
  style: TextStyle(
    // other style properties (do not include color)
  ),
)
```

### 3. Buttons with Gradient

**Replace this:**
```dart
ElevatedButton(
  onPressed: () { /* action */ },
  style: ElevatedButton.styleFrom(
    backgroundColor: goldColor,
    // other style properties
  ),
  child: Text('Button Text'),
)
```

**With this:**
```dart
GoldGradientButton(
  onPressed: () { /* action */ },
  child: Text('Button Text'),
)
```

### 4. FloatingActionButton with Gradient

**Replace this:**
```dart
FloatingActionButton(
  onPressed: () { /* action */ },
  child: Icon(Icons.add),
)
```

**With this:**
```dart
GradientFAB(
  onPressed: () { /* action */ },
  icon: Icon(Icons.add),
)
```

### 5. Progress Indicators with Gradient

**Linear Progress Indicator:**
```dart
GradientLinearProgressIndicator(
  value: 0.7, // between 0.0 and 1.0
)
```

**Circular Progress Indicator:**
```dart
GradientCircularProgressIndicator(
  value: 0.7, // between 0.0 and 1.0
)
```

### 6. Cards with Gradient Border

**Replace this:**
```dart
Card(
  // properties
  child: /* content */,
)
```

**With this for white background:**
```dart
GradientBorderCard(
  // properties
  child: /* content */,
)
```

**With this for cream background:**
```dart
CreamGradientCard(
  // properties
  child: /* content */,
)
```

## Gradient Container Backgrounds

To add a gradient background to any container:

```dart
Container(
  decoration: BoxDecoration(
    gradient: goldGradient,
    // other decoration properties
  ),
  // other container properties
)
```

## Gradient Borders

To add a gradient border to a container:

```dart
Container(
  decoration: BoxDecoration(
    border: Border.all(
      width: 2,
      color: Colors.transparent,
    ),
    borderRadius: BorderRadius.circular(12),
    gradient: goldGradient,
  ),
  child: Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
    ),
    margin: const EdgeInsets.all(2),
    // child content
  ),
)
```

## Adding Gradient to Existing Widgets

To apply the gold gradient to any existing widget:

```dart
ShaderMask(
  shaderCallback: (bounds) => goldGradient.createShader(bounds),
  child: YourWidget(
    // Set the color to white to allow the gradient to show through
    color: Colors.white,
  ),
)
```

Or use our helper widget:

```dart
GradientWrapper(
  child: YourWidget(
    color: Colors.white,
  ),
)
```

## Page Components to Update

For each page in the app, update these common components:
- AppBar → GradientAppBar
- Text with gold color → GradientText
- ElevatedButton → GoldGradientButton
- Progress indicators → GradientLinearProgressIndicator/GradientCircularProgressIndicator
- FloatingActionButton → GradientFAB
- Cards → GradientBorderCard (or add gradient with BoxDecoration)

## Example Implementation

See these pages for reference implementations:
1. `lib/pages/targets/targets_page.dart` - for gradient AppBar, progress bars, and buttons
2. `lib/pages/login/login_page.dart` - for gradient text, buttons, and layouts 