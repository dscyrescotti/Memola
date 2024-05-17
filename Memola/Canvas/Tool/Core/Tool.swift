//
//  Tool.swift
//  Memola
//
//  Created by Dscyre Scotti on 5/4/24.
//

import SwiftUI
import CoreData
import Foundation

public class Tool: NSObject, ObservableObject {
    let object: ToolObject

    @Published var pens: [Pen] = []
    @Published var selectedPen: Pen?
    @Published var draggedPen: Pen?

    init(object: ToolObject) {
        self.object = object
    }

    func load() {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            pens = object.pens.sortedArray(using: [NSSortDescriptor(key: "orderIndex", ascending: true)]).compactMap {
                guard let pen = $0 as? PenObject else { return nil }
                return Pen(object: pen)
            }
            if let selectedPen = pens.first(where: { $0.isSelected }) {
                selectPen(selectedPen)
            }
        }
    }

    func selectPen(_ pen: Pen) {
        if let selectedPen {
            unselectPen(selectedPen)
        }
        withAnimation {
            selectedPen = pen
        }
        selectedPen?.isSelected = true
    }

    func unselectPen(_ pen: Pen) {
        pen.isSelected = false
    }

    func addPen(_ pen: Pen) {
        withAnimation {
            pens.append(pen)
        }
        selectPen(pen)
        if let _pen = pen.object {
            object.pens.add(_pen)
        }
    }
}
