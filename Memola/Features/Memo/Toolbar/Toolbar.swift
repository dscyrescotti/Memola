//
//  Toolbar.swift
//  Memola
//
//  Created by Dscyre Scotti on 5/19/24.
//

import SwiftUI
import Foundation

struct Toolbar: View {
    @Environment(\.dismiss) var dismiss
    
    @EnvironmentObject var history: History
    
    @State var memo: MemoObject
    @State var title: String
    @FocusState var textFieldState: Bool

    init(memo: MemoObject) {
        self.memo = memo
        self.title = memo.title
    }
    
    var body: some View {
        HStack(spacing: 5) {
            closeButton
            titleField
            Spacer()
            historyTool
        }
        .font(.subheadline)
        .padding(10)
    }

    var closeButton: some View {
        Button {
            closeMemo()
        } label: {
            Image(systemName: "xmark")
                .contentShape(.circle)
                .padding(10)
                .background(.regularMaterial)
                .clipShape(.rect(cornerRadius: 8))
        }
        .hoverEffect(.lift)
        .disabled(textFieldState)
    }

    var titleField: some View {
        TextField("", text: $title)
            .focused($textFieldState)
            .textFieldStyle(.plain)
            .padding(.vertical, 5)
            .padding(.horizontal, 10)
            .frame(width: 120)
            .background(.regularMaterial)
            .clipShape(.rect(cornerRadius: 8))
            .onChange(of: textFieldState) { oldValue, newValue in
                if !newValue {
                    if !title.isEmpty {
                        memo.title = title
                    } else {
                        title = memo.title
                    }
                }
            }
    }

    var historyTool: some View {
        HStack {
            Button {
                history.historyPublisher.send(.undo)
            } label: {
                Image(systemName: "arrow.uturn.backward.circle")
                    .contentShape(.circle)
            }
            .hoverEffect(.lift)
            .disabled(history.undoDisabled)
            Button {
                history.historyPublisher.send(.redo)
            } label: {
                Image(systemName: "arrow.uturn.forward.circle")
                    .contentShape(.circle)
            }
            .hoverEffect(.lift)
            .disabled(history.redoDisabled)
        }
        .padding(10)
        .background(.regularMaterial)
        .clipShape(.rect(cornerRadius: 8))
        .disabled(textFieldState)
    }

    func closeMemo() {
        withPersistenceSync(\.viewContext) { context in
            try context.saveIfNeeded()
        }
        dismiss()
    }
}
