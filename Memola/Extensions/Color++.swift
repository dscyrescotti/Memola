//
//  Color++.swift
//  Memola
//
//  Created by Dscyre Scotti on 5/4/24.
//

import SwiftUI

extension Color {
    var components: [CGFloat] {
        let color = UIColor(self)
        return color.components
    }

    static func rgba(from color: [CGFloat]) -> Color {
        Color(red: color[0], green: color[1], blue: color[2]).opacity(color[3])
    }
}

extension Color {
    var hsba: (hue: Double, saturation: Double, brightness: Double, alpha: Double) {
        let uiColor = UIColor(self)
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        uiColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        return (hue, saturation, brightness, alpha)
    }
}

extension UIColor {
    var components: [CGFloat] {
        let uiColor: UIColor = self
        let ciColor: CIColor = .init(color: uiColor)
        return [ciColor.red, ciColor.green, ciColor.blue, ciColor.alpha]
    }
}
