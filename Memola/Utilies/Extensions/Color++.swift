//
//  Color++.swift
//  Memola
//
//  Created by Dscyre Scotti on 5/4/24.
//

import SwiftUI

extension Color {
    init(color: Platform.Color) {
        #if os(macOS)
        self = Color(nsColor: color)
        #else
        self = Color(uiColor: color)
        #endif
    }

    var components: [CGFloat] {
        let color = Platform.Color(self)
        return color.components
    }

    static func rgba(from color: [CGFloat]) -> Color {
        Color(red: color[0], green: color[1], blue: color[2]).opacity(color[3])
    }
}

extension Color {
    var hsba: (hue: Double, saturation: Double, brightness: Double, alpha: Double) {
        #if os(macOS)
        #warning("TODO: need double check")
        let nsColor = NSColor(self)
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        nsColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        return (hue, saturation, brightness, alpha)
        #else
        let uiColor = UIColor(self)
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        uiColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        return (hue, saturation, brightness, alpha)
        #endif
    }
}

extension Platform.Color {
    var components: [CGFloat] {
        #if os(macOS)
        #warning("TODO: need double check")
        let nsColor: NSColor = self
        let ciColor: CIColor = .init(color: nsColor) ?? CIColor(red: 0, green: 0, blue: 0)
        return [ciColor.red, ciColor.green, ciColor.blue, ciColor.alpha]
        #else
        let uiColor: UIColor = self
        let ciColor: CIColor = .init(color: uiColor)
        return [ciColor.red, ciColor.green, ciColor.blue, ciColor.alpha]
        #endif
    }
}
