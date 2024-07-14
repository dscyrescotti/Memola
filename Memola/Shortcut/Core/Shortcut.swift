//
//  Shortcut.swift
//  Memola
//
//  Created by Dscyre Scotti on 7/12/24.
//

import Combine
import Foundation

final class Shortcut {
    static let shared: Shortcut = .init()

    private let _publisher = PassthroughSubject<Shortcuts, Never>()

    lazy var publisher: AnyPublisher<Shortcuts, Never> = {
        _publisher.eraseToAnyPublisher()
    }()

    private init() { }

    func trigger(_ shortcut: Shortcuts) {
        _publisher.send(shortcut)
    }
}
