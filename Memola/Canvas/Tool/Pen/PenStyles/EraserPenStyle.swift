//
//  EraserPenStyle.swift
//  Memola
//
//  Created by Dscyre Scotti on 5/4/24.
//

import Foundation

struct EraserPenStyle: PenStyle {
    var icon: (base: String, tip: String?) = ("eraser", nil)

    var textureName: String = "point-texture"

    var thinkness: (min: CGFloat, max: CGFloat) = (1, 120)

    var color: [CGFloat] = [1, 1, 1, 0]

    var stepRate: CGFloat = 0.2

    var generator: any StrokeGenerator {
        SolidPointStrokeGenerator(configuration: .init())
    }
}

extension PenStyle where Self == EraserPenStyle {
    static var eraser: PenStyle {
        EraserPenStyle()
    }
}
