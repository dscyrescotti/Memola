//
//  EraserStroke.swift
//  Memola
//
//  Created by Dscyre Scotti on 5/24/24.
//

import MetalKit
import Foundation

final class EraserStroke: Stroke, @unchecked Sendable {
    var id: UUID = UUID()
    var bounds: [CGFloat]
    var color: [CGFloat]
    var style: StrokeStyle
    var createdAt: Date
    var thickness: CGFloat
    var quads: [Quad]
    var penStyle: any PenStyle

    var keyPoints: [CGPoint] = []
    var movingAverage: MovingAverage = MovingAverage(windowSize: 3)

    var texture: (any MTLTexture)?
    var indexBuffer: (any MTLBuffer)?
    var vertexBuffer: (any MTLBuffer)?

    init(
        bounds: [CGFloat],
        color: [CGFloat],
        style: StrokeStyle,
        createdAt: Date,
        thickness: CGFloat,
        quads: [Quad] = []
    ) {
        self.bounds = bounds
        self.color = color
        self.style = style
        self.createdAt = createdAt
        self.thickness = thickness
        self.quads = quads
        self.penStyle = style.penStyle
    }
}
