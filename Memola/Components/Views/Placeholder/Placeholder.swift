//
//  Placeholder.swift
//  Memola
//
//  Created by Dscyre Scotti on 6/27/24.
//

import SwiftUI

struct Placeholder: View {
    let info: Info

    var body: some View {
        VStack(spacing: 15) {
            Image(systemName: info.icon)
                .font(.system(size: 50))
                .frame(width: 55, height: 55)
            VStack(spacing: 3) {
                Text(info.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                Text(info.description)
                    .font(.callout)
                    .fontWeight(.regular)
                    .frame(minHeight: 50, alignment: .top)
            }
        }
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

extension Placeholder {
    struct Info {
        let title: String
        let description: String
        let icon: String

        static let memoNotFound: Info = {
            let icon: String = "sparkle.magnifyingglass"
            let title: String = "No Memos Found"
            let description: String = "Explore your other memos or create your own."
            return Placeholder.Info(title: title, description: description, icon: icon)
        }()

        static let memoEmpty: Info = {
            let icon: String = "note.text"
            let title: String = "No Memos"
            let description: String = "Create a new memo to jot your thoughts or notes down."
            return Placeholder.Info(title: title, description: description, icon: icon)
        }()
    }
}
