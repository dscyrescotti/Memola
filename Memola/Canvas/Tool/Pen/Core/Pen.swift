//
//  Pen.swift
//  Memola
//
//  Created by Dscyre Scotti on 5/4/24.
//

import SwiftUI
import Foundation
import UniformTypeIdentifiers

class Pen: NSObject, ObservableObject, Identifiable {
    var object: PenObject?

    let id: String
    @Published var style: any PenStyle {
        didSet {
            object?.style = strokeStyle.rawValue
            object?.tool?.memo?.updatedAt = .now
        }
    }
    @Published var rgba: [CGFloat] {
        didSet {
            object?.color = rgba
            object?.tool?.memo?.updatedAt = .now
        }
    }
    @Published var thickness: CGFloat {
        didSet {
            object?.thickness = thickness
            object?.tool?.memo?.updatedAt = .now
        }
    }
    @Published var isSelected: Bool {
        didSet {
            object?.isSelected = isSelected
            object?.tool?.memo?.updatedAt = .now
        }
    }
    var color: Color {
        get { Color.rgba(from: rgba) }
        set {
            rgba = newValue.components
        }
    }

    init(object: PenObject) {
        self.object = object
        self.id = object.objectID.uriRepresentation().absoluteString
        self.style = (StrokeStyle(rawValue: object.style) ?? .marker).penStyle
        self.rgba = object.color
        self.thickness = object.thickness
        self.isSelected = object.isSelected
        super.init()
    }

    var strokeStyle: StrokeStyle {
        style.strokeStyle
    }
}
