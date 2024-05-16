//
//  Tool.swift
//  Memola
//
//  Created by Dscyre Scotti on 5/4/24.
//

import SwiftUI
import Foundation

class Tool: NSObject, ObservableObject {
    @Published var pens: [Pen]
    @Published var selectedPen: Pen?
    @Published var draggedPen: Pen?

    override init() {
        pens = [
            Pen(for: .eraser),
            Pen(for: .marker)
        ]
        super.init()
        selectedPen = pens[1]
    }

    func changePen(_ pen: Pen) {
        selectedPen = pen
    }

    func addPen(_ pen: Pen) {
        pens.append(pen)
    }
}
