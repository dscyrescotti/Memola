//
//  AppWindow.swift
//  Memola
//
//  Created by Dscyre Scotti on 7/17/24.
//

import Foundation

enum AppWindow: String, Identifiable {
    var id: String { rawValue }

    case dashboard
    case settings

    var url: URL? {
        URL(string: "memola:\(id)")
    }
}
