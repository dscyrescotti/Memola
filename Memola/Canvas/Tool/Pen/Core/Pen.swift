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
        }
    }
    @Published var rgba: [CGFloat] {
        didSet {
            object?.color = rgba
        }
    }
    @Published var thickness: CGFloat {
        didSet {
            object?.thickness = thickness
        }
    }
    @Published var isSelected: Bool {
        didSet {
            object?.isSelected = isSelected
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
        self.style = (Stroke.Style(rawValue: object.style) ?? .marker).anyPenStyle
        self.rgba = object.color
        self.thickness = object.thickness
        self.isSelected = object.isSelected
        super.init()
    }

    var strokeStyle: Stroke.Style {
        style.strokeStyle
    }
}
