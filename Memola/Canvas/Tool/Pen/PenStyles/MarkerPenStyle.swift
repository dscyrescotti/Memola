//
//  MarkerPenStyle.swift
//  Memola
//
//  Created by Dscyre Scotti on 5/4/24.
//

import Foundation

struct MarkerPenStyle: PenStyle {
    var icon: (base: String, tip: String?) = ("marker-base", "marker-tip")

    var textureName: String = "point-texture"

    var thickness: (min: CGFloat, max: CGFloat) = (0.5, 125)

    var thicknessSteps: [CGFloat] = [0.5, 1, 2, 5, 10, 20, 50, 75, 100, 120]

    var color: [CGFloat] = [1, 0.38, 0.38, 1]

    var stepRate: CGFloat = 0.2

    var generator: any StrokeGenerator {
        SolidPointStrokeGenerator(configuration: .init())
    }
}

extension PenStyle where Self == MarkerPenStyle {
    static var marker: PenStyle {
        MarkerPenStyle()
    }
}
