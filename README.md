# ShowTime

Lightweight iOS library that displays circular touch indicators on screen. Useful for demos, presentations, and screen recordings.

**Disabled by default** -- zero performance impact until explicitly enabled.

## Installation

Add via Swift Package Manager:

```
https://github.com/hekulis-org/ShowTime.git
```

## Usage

```swift
import ShowTime

// Enable touch visualization
ShowTime.enabled = .always      // always show
ShowTime.enabled = .debugOnly   // only in DEBUG builds
ShowTime.enabled = .never       // disable (default)
```

### Configuration

```swift
ShowTime.strokeColor = UIColor(red: 0.21, green: 0.61, blue: 0.92, alpha: 1) // default
ShowTime.strokeWidth = 3        // stroke thickness (default: 3pt)
ShowTime.fillColor = nil        // nil = auto (stroke color at 50% opacity)
ShowTime.fillColor = .red       // or set an explicit color
ShowTime.size = 44              // circle diameter (default: 44pt)
ShowTime.disappearDelay = 0.2   // seconds before fade-out starts
ShowTime.disappearAnimation = .standard   // .standard, .scaleDown, .scaleUp
ShowTime.shouldIgnoreApplePencilEvents = true // default
```

## How it works

ShowTime uses method swizzling on `UIWindow.sendEvent(_:)` to intercept touch events and render `CAShapeLayer` circles at touch locations. Swizzling is only activated when `enabled` is set to `.always` or `.debugOnly` (in debug builds), and is fully reversed when set back to `.never`.

## Run Tests

```
xcodebuild test -scheme ShowTime -sdk iphonesimulator -destination "platform=iOS Simulator,name=iPhone 17 Pro"
```

## License

MIT. See LICENSE file.
