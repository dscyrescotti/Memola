//
//  NavigationSplitViewVisibility++.swift
//  Memola
//
//  Created by Dscyre Scotti on 7/14/24.
//

import SwiftUI

extension NavigationSplitViewVisibility: RawRepresentable {
    public init?(rawValue: Int) {
        switch rawValue {
        case 0: self = .all
        case 1: self = .automatic
        case 2: self = .detailOnly
        case 3: self = .doubleColumn
        default: self = .all
        }
    }
    
    public var rawValue: Int {
        switch self {
        case .all: 0
        case .automatic: 1
        case .detailOnly: 2
        case .doubleColumn: 3
        default: -1
        }
    }
    
    public typealias RawValue = Int
}

