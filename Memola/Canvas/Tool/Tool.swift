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

    override init() {
        pens = [
            Pen(for: .marker),
            Pen(for: .eraser)
        ]
        super.init()
        selectedPen = pens.first
    }

    func changePen(_ pen: Pen) {
        selectedPen = pen
    }
}
