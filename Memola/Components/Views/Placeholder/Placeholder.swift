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
                    .lineLimit(.none)
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
            let title: String = "Memos Not Found"
            let description: String = "There are no memos matching your search.\n Please try different keywords or create a new memo."
            return Placeholder.Info(title: title, description: description, icon: icon)
        }()

        static let memoEmpty: Info = {
            let icon: String = "note.text"
            let title: String = "No Memos Available"
            let description: String = "You have not created any memos yet.\n Tap the 'New Memo' button to get started."
            return Placeholder.Info(title: title, description: description, icon: icon)
        }()

        static let trashEmpty: Info = {
            let icon: String = "trash"
            let title: String = "Trash is Empty"
            let description: String = "There are no memos in the trash.\n Deleted memos will appear here."
            return Placeholder.Info(title: title, description: description, icon: icon)
        }()

        static let trashNotFound: Info = {
            let icon: String = "exclamationmark.magnifyingglass"
            let title: String = "No Deleted Memos Found"
            let description: String = "No memos found in the trash matching your search.\n Try different keywords or check back later."
            return Placeholder.Info(title: title, description: description, icon: icon)
        }()
    }
}
