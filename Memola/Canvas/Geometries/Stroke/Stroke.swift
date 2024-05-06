//
//  Stroke.swift
//  Memola
//
//  Created by Dscyre Scotti on 5/4/24.
//

import MetalKit
import Foundation

class Stroke: Codable {
    var color: [CGFloat]
    var style: any PenStyle
    var thickness: CGFloat
    var angle: CGFloat = 0

    var vertexIndex: Int = -1
    var keyPoints: [CGPoint] = []
    var thicknessFactor: CGFloat = 0.7

    var vertices: [QuadVertex] = []
    var vertexBuffer: MTLBuffer?
    var vertexCount: Int = 0

    let createdAt: Date = Date()

    var texture: MTLTexture?

    var isEmpty: Bool {
        vertices.isEmpty
    }

    var isEraserPenStyle: Bool {
        style is EraserPenStyle
    }

    init(color: [CGFloat], style: any PenStyle, thickness: CGFloat) {
        self.color = color
        self.style = style
        self.thickness = thickness
    }

    enum CodingKeys: CodingKey {
        case color
        case style
        case thickness
        case vertices
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        color = try container.decode([CGFloat].self, forKey: .color)
        let style: String = try container.decode(String.self, forKey: .style)
        thickness = try container.decode(CGFloat.self, forKey: .thickness)
        vertices = try container.decode([QuadVertex].self, forKey: .vertices)
        vertexCount = vertices.count
        switch style {
        case "marker":
            self.style = .marker
        case "eraser":
            self.style = .eraser
        default:
            throw DecodingError.valueNotFound(PenStyle.self, .init(codingPath: [CodingKeys.style], debugDescription: "There is no pen style called `\(style)`."))
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(color, forKey: .color)
        try container.encode(thickness, forKey: .thickness)
        try container.encode(vertices, forKey: .vertices)
        let styleName: String
        switch style {
        case is MarkerPenStyle:
            styleName = "marker"
        case is EraserPenStyle:
            styleName = "eraser"
        default:
            fatalError()
        }
        try container.encode(styleName, forKey: .style)
    }

    func begin(at point: CGPoint) {
        style.generator.begin(at: point, on: self)
    }

    func append(to point: CGPoint) {
        style.generator.append(to: point, on: self)
    }

    func finish(at point: CGPoint) {
        style.generator.finish(at: point, on: self)
    }
}

extension Stroke: Drawable {
    func prepare(device: MTLDevice) {
        if texture == nil {
            texture = style.loadTexture(on: device)
        }
        vertexBuffer = device.makeBuffer(bytes: &vertices, length: MemoryLayout<QuadVertex>.stride * vertexCount, options: .cpuCacheModeWriteCombined)
    }

    func draw(device: MTLDevice, renderEncoder: MTLRenderCommandEncoder) {
        guard !isEmpty else { return }
        prepare(device: device)
        renderEncoder.setFragmentTexture(texture, index: 0)
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertexCount)
    }
}
