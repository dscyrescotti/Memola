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

extension UIColor {
    var components: [CGFloat] {
        let uiColor: UIColor = self
        let ciColor: CIColor = .init(color: uiColor)
        return [ciColor.red, ciColor.green, ciColor.blue, ciColor.alpha]
    }
}
