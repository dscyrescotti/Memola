//
//  Data++.swift
//  Memola
//
//  Created by Dscyre Scotti on 6/16/24.
//

import Foundation

extension Data {
    func getBookmarkURL() -> URL? {
        var isStale = false
        guard let bookmarkURL = try? URL(resolvingBookmarkData: self, options: .withoutUI, relativeTo: nil, bookmarkDataIsStale: &isStale) else {
            return nil
        }
        return bookmarkURL
    }
}
