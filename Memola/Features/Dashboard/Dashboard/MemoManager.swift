//
//  MemoManager.swift
//  Memola
//
//  Created by Dscyre Scotti on 7/7/24.
//

import SwiftUI
import Foundation

#warning("TODO: use environmnet instead of singleton")
class MemoManager: ObservableObject {
    static let shared: MemoManager = .init()

    @Published var memoObject: MemoObject?

    private init() { }

    func openMemo(_ memoObject: MemoObject?) {
        #if os(macOS)
        withAnimation(.easeOut) {
            self.memoObject = memoObject
        }
        #else
        self.memoObject = memoObject
        #endif
    }

    func closeMemo() {
        #if os(macOS)
        withAnimation(.easeOut) {
            self.memoObject = nil
        }
        #else
        self.memoObject = nil
        #endif
    }
}
