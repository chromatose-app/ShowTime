//
//  ShowTime.swift
//  ShowTime
//
//  Created by Kane Cheshire on 11/11/2016.
//  Copyright (c) 2016 Kane Cheshire. All rights reserved.
//

import UIKit

/// Displays circular touch indicators on screen when enabled.
/// Disabled by default -- set `ShowTime.enabled = .always` to activate.
public enum ShowTime {

    // MARK: - Types

    public enum Enabled: Int, CaseIterable, Sendable {
        case always, never, debugOnly
    }

    public enum Animation: Sendable {
        case standard, scaleDown, scaleUp
    }

    // MARK: - Configuration

    /// Whether ShowTime is enabled. Disabled by default.
    /// Setting to `.always` or `.debugOnly` activates touch visualization.
    nonisolated(unsafe) public static var enabled: Enabled = .never {
        didSet { MainActor.assumeIsolated { updateSwizzleState() } }
    }

    /// The fill color of touch indicators.
    /// When `nil` (default), uses the stroke color at 50% opacity.
    nonisolated(unsafe) public static var fillColor: UIColor?

    /// The stroke color of touch indicators.
    nonisolated(unsafe) public static var strokeColor = UIColor(red: 0.21, green: 0.61, blue: 0.92, alpha: 1)

    /// The stroke width of touch indicators.
    nonisolated(unsafe) public static var strokeWidth: CGFloat = 3

    /// The diameter of touch indicators.
    nonisolated(unsafe) public static var size: CGFloat = 44

    /// The animation style when touch indicators disappear.
    nonisolated(unsafe) public static var disappearAnimation: Animation = .standard

    /// The delay before the disappear animation begins.
    nonisolated(unsafe) public static var disappearDelay: TimeInterval = 0.2

    /// Whether to ignore Apple Pencil touch events.
    nonisolated(unsafe) public static var shouldIgnoreApplePencilEvents = true

    // MARK: - Internal

    nonisolated(unsafe) static var touches = [UITouch: TouchIndicatorLayer]()

    static var shouldEnable: Bool {
        switch enabled {
        case .always: return true
        case .never: return false
        case .debugOnly:
            #if DEBUG
            return true
            #else
            return false
            #endif
        }
    }

    // MARK: - Swizzle Management

    nonisolated(unsafe) private static var isSwizzled = false

    @MainActor private static func updateSwizzleState() {
        if shouldEnable {
            swizzle()
        } else {
            removeAllTouchIndicators()
            unswizzle()
        }
    }

    private static func swizzle() {
        guard !isSwizzled else { return }
        isSwizzled = true
        guard let original = class_getInstanceMethod(UIWindow.self, #selector(UIWindow.sendEvent(_:))),
              let swizzled = class_getInstanceMethod(UIWindow.self, #selector(UIWindow.showTime_sendEvent(_:)))
        else { return }
        method_exchangeImplementations(original, swizzled)
    }

    private static func unswizzle() {
        guard isSwizzled else { return }
        isSwizzled = false
        guard let original = class_getInstanceMethod(UIWindow.self, #selector(UIWindow.sendEvent(_:))),
              let swizzled = class_getInstanceMethod(UIWindow.self, #selector(UIWindow.showTime_sendEvent(_:)))
        else { return }
        method_exchangeImplementations(original, swizzled)
    }

    // MARK: - Touch Handling

    @MainActor fileprivate static func touchBegan(_ touch: UITouch, in window: UIWindow) {
        guard touches[touch] == nil else { return }
        let indicator = TouchIndicatorLayer(touch: touch, relativeTo: window)
        window.layer.addSublayer(indicator)
        touches[touch] = indicator
    }

    @MainActor fileprivate static func touchMoved(_ touch: UITouch, in window: UIWindow) {
        guard let indicator = touches[touch] else { return }
        indicator.update(with: touch, relativeTo: window)
    }

    @MainActor fileprivate static func touchEnded(_ touch: UITouch) {
        guard let indicator = touches[touch] else { return }
        indicator.disappear()
        touches[touch] = nil
    }

    @MainActor static func removeAllTouchIndicators() {
        for touch in touches.keys {
            touchEnded(touch)
        }
    }
}

// MARK: - Touch Indicator

@MainActor final class TouchIndicatorLayer: CAShapeLayer {

    convenience init(touch: UITouch, relativeTo window: UIWindow) {
        self.init()
        let location = touch.location(in: window)
        let s = ShowTime.size
        frame = CGRect(x: location.x - s / 2, y: location.y - s / 2, width: s, height: s)
        path = UIBezierPath(ovalIn: bounds).cgPath
        fillColor = (ShowTime.fillColor ?? ShowTime.strokeColor.withAlphaComponent(0.5)).cgColor
        strokeColor = ShowTime.strokeColor.cgColor
        lineWidth = ShowTime.strokeWidth
        zPosition = 10000
    }

    override init() {
        super.init()
    }

    override init(layer: Any) {
        super.init(layer: layer)
    }

    required init?(coder: NSCoder) {
        fatalError("Not supported")
    }

    func update(with touch: UITouch, relativeTo window: UIWindow) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        position = touch.location(in: window)
        CATransaction.commit()
    }

    func disappear() {
        let group = CAAnimationGroup()
        group.duration = 0.2
        group.beginTime = CACurrentMediaTime() + ShowTime.disappearDelay
        group.fillMode = .forwards
        group.isRemovedOnCompletion = false
        group.delegate = self

        switch ShowTime.disappearAnimation {
        case .standard:
            let fade = CABasicAnimation(keyPath: "opacity")
            fade.toValue = 0
            let scale = CABasicAnimation(keyPath: "transform.scale")
            scale.toValue = 0.85
            group.animations = [fade, scale]
        case .scaleDown:
            let scale = CABasicAnimation(keyPath: "transform.scale")
            scale.toValue = 0.01
            group.animations = [scale]
        case .scaleUp:
            let fade = CABasicAnimation(keyPath: "opacity")
            fade.toValue = 0
            let scale = CABasicAnimation(keyPath: "transform.scale")
            scale.toValue = 1.5
            group.animations = [fade, scale]
        }

        add(group, forKey: "disappear")
    }

}

extension TouchIndicatorLayer: @preconcurrency CAAnimationDelegate {
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        removeFromSuperlayer()
    }
}

// MARK: - UIWindow Swizzling

extension UIWindow {
    @objc fileprivate func showTime_sendEvent(_ event: UIEvent) {
        showTime_sendEvent(event)
        guard ShowTime.shouldEnable else {
            ShowTime.removeAllTouchIndicators()
            return
        }
        event.allTouches?.forEach { touch in
            if ShowTime.shouldIgnoreApplePencilEvents && touch.type == .stylus { return }
            switch touch.phase {
            case .began: ShowTime.touchBegan(touch, in: self)
            case .moved, .stationary: ShowTime.touchMoved(touch, in: self)
            case .cancelled, .ended: ShowTime.touchEnded(touch)
            default: return
            }
        }
    }
}
