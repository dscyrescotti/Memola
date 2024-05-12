//
//  Pen.swift
//  Memola
//
//  Created by Dscyre Scotti on 5/4/24.
//

import SwiftUI
import Foundation

class Pen: NSObject, ObservableObject, Identifiable {
    @Published var style: any PenStyle
    @Published var color: [CGFloat]
    @Published var thickness: CGFloat

    init(style: any PenStyle, color: [CGFloat], thickness: CGFloat) {
        self.style = style
        self.color = color
        self.thickness = thickness
    }

    var strokeStyle: Stroke.Style {
        switch style {
        case is MarkerPenStyle:
            return .marker
        case is EraserPenStyle:
            return .eraser
        default:
            return .marker
        }
    }
}

extension Pen {
    convenience init(for style: any PenStyle) {
        self.init(style: style, color: style.color, thickness: style.thinkness.min)
    }
}
