//
//  Shortcut.swift
//  Memola
//
//  Created by Dscyre Scotti on 7/12/24.
//

import Combine
import Foundation

class Shortcut: ObservableObject {
    static let shared: Shortcut = .init()

    private let shortcutPublisher = PassthroughSubject<Shortcuts, Never>()

    private init() { }

    func trigger(_ shortcut: Shortcuts) {
        shortcutPublisher.send(shortcut)
    }

    func publisher() -> AnyPublisher<Shortcuts, Never> {
        shortcutPublisher.eraseToAnyPublisher()
    }
}
