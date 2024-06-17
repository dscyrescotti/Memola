//
//  StrokeStyle.swift
//  Memola
//
//  Created by Dscyre Scotti on 5/24/24.
//

import Foundation

enum StrokeStyle: Int16 {
    case marker
    case eraser

    var penStyle: any PenStyle {
        switch self {
        case .marker:
            MarkerPenStyle.marker
        case .eraser:
            EraserPenStyle.eraser
        }
    }
}
