//
//  ContentView.swift
//  ShowTimeExample
//
//  Created by Kane Cheshire on 14/01/2023.
//

import SwiftUI
import ShowTime

private let numberFormatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.maximumFractionDigits = 2
    return formatter
}()

struct ContentView: View {
    @State private var enabled: ShowTime.Enabled = ShowTime.enabled
    @State private var disappearAnimation: Animation = .init(ShowTime.disappearAnimation)
    @State private var disappearDelay: Double = ShowTime.disappearDelay
    @State private var strokeColor: CGColor = ShowTime.strokeColor.cgColor
    @State private var strokeWidth: CGFloat = ShowTime.strokeWidth
    @State private var fillColor: CGColor = (ShowTime.fillColor ?? ShowTime.strokeColor.withAlphaComponent(0.5)).cgColor
    @State private var fillColorIsAuto: Bool = ShowTime.fillColor == nil
    @State private var size: CGFloat = ShowTime.size
    @State private var ignoreApplePencilEvents: Bool = ShowTime.shouldIgnoreApplePencilEvents

    var body: some View {
        ScrollView {
            Text("ShowTime is disabled by default. Set ShowTime.enabled = .always to activate touch visualization.")
                .bold()
            VStack(alignment: .leading) {
                Row(
                    title: "Enabled",
                    description: "When and if ShowTime is enabled.",
                    codeExample: "ShowTime.enabled = \(enabled.stringValue)"
                ) {
                    Picker("\(enabled.stringValue)", selection: $enabled) {
                        ForEach(ShowTime.Enabled.allCases, id: \.self) { enabled in
                            Button(enabled.stringValue) { self.enabled = enabled }
                        }
                    }
                }

                Row(
                    title: "Animation",
                    description: "The animation to perform to hide touch indicators.",
                    codeExample: "ShowTime.disappearAnimation = \(disappearAnimation.stringValue)"
                ) {
                    Picker("\(disappearAnimation.stringValue)", selection: $disappearAnimation) {
                        ForEach(Animation.allCases, id: \.self) { animation in
                            Button(animation.stringValue) { disappearAnimation = animation }
                        }
                    }
                }

                Row(
                    title: "Animation delay",
                    description: "The delay until the disappearing animation is performed.",
                    codeExample: "ShowTime.disappearDelay = \(numberFormatter.string(from: disappearDelay as NSNumber)!)"
                ) {
                    VStack(alignment: .trailing) {
                        Text(disappearDelay, format: .number)
                        Stepper("\(disappearDelay)", value: $disappearDelay, in: 0 ... 10, step: 0.1)
                    }
                }

                Row(
                    title: "Stroke color",
                    description: "The color of the stroke around touch indicators.",
                    codeExample: "ShowTime.strokeColor = \(strokeColor.uicolorCodeExample)"
                ) {
                    ColorPicker("", selection: $strokeColor, supportsOpacity: true)
                }

                Row(
                    title: "Stroke width",
                    description: "The width of the stroke around touch indicators.",
                    codeExample: "ShowTime.strokeWidth = \(numberFormatter.string(from: strokeWidth as NSNumber)!)"
                ) {
                    VStack(alignment: .trailing) {
                        Text(strokeWidth, format: .number)
                        Stepper("\(strokeWidth)", value: $strokeWidth, in: 0 ... 100, step: 1)
                    }
                }

                Row(
                    title: fillColorIsAuto ? "Fill color (auto)" : "Fill color",
                    description: "The fill color of touch indicators. When nil (default), derived from stroke color at 50% opacity.",
                    codeExample: fillColorIsAuto ? "ShowTime.fillColor = nil" : "ShowTime.fillColor = \(fillColor.uicolorCodeExample)"
                ) {
                    ColorPicker("", selection: $fillColor, supportsOpacity: true)
                }

                Row(
                    title: "Size",
                    description: "The diameter of touch indicators.",
                    codeExample: "ShowTime.size = \(Int(size))"
                ) {
                    VStack(alignment: .trailing) {
                        Text(size, format: .number)
                        Stepper("\(size)", value: $size, in: 0 ... 100, step: 1)
                    }
                }

                Row(
                    title: "Ignore Apple Pencil events",
                    description: "Whether touch indicators should be hidden for Apple Pencil events.",
                    codeExample: "ShowTime.shouldIgnoreApplePencilEvents = \(ignoreApplePencilEvents)"
                ) {
                    Toggle(isOn: $ignoreApplePencilEvents) { Text("") }
                }
            }
            .padding()
        }
        .onChange(of: enabled) { ShowTime.enabled = $0 }
        .onChange(of: disappearAnimation) { ShowTime.disappearAnimation = $0.mapped }
        .onChange(of: disappearDelay) { ShowTime.disappearDelay = $0 }
        .onChange(of: strokeColor) { ShowTime.strokeColor = UIColor(cgColor: $0) }
        .onChange(of: strokeWidth) { ShowTime.strokeWidth = $0 }
        .onChange(of: fillColor) {
            fillColorIsAuto = false
            ShowTime.fillColor = UIColor(cgColor: $0)
        }
        .onChange(of: size) { ShowTime.size = $0 }
        .onChange(of: ignoreApplePencilEvents) { ShowTime.shouldIgnoreApplePencilEvents = $0 }
    }
}

private enum Animation: Hashable, CaseIterable {
    case standard, scaleDown, scaleUp

    var mapped: ShowTime.Animation {
        switch self {
        case .standard: return .standard
        case .scaleDown: return .scaleDown
        case .scaleUp: return .scaleUp
        }
    }

    var stringValue: String {
        switch self {
        case .standard: return ".standard"
        case .scaleDown: return ".scaleDown"
        case .scaleUp: return ".scaleUp"
        }
    }

    init(_ animation: ShowTime.Animation) {
        switch animation {
        case .standard: self = .standard
        case .scaleDown: self = .scaleDown
        case .scaleUp: self = .scaleUp
        }
    }
}

private extension ShowTime.Enabled {
    var stringValue: String {
        switch self {
        case .never: return ".never"
        case .always: return ".always"
        case .debugOnly: return ".debugOnly"
        }
    }
}

private extension CGColor {
    var rgba: (r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat) {
        let color = UIColor(cgColor: self)
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        return (r, g, b, a)
    }

    var uicolorCodeExample: String {
        let computedRGBA = rgba
        let formattedR = numberFormatter.string(from: computedRGBA.r as NSNumber)!
        let formattedG = numberFormatter.string(from: computedRGBA.g as NSNumber)!
        let formattedB = numberFormatter.string(from: computedRGBA.b as NSNumber)!
        let formattedA = numberFormatter.string(from: computedRGBA.a as NSNumber)!
        return "UIColor(red: \(formattedR), green: \(formattedG), blue: \(formattedB), alpha: \(formattedA))"
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
