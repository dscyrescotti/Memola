//
//  Toolbar.swift
//  Memola
//
//  Created by Dscyre Scotti on 5/19/24.
//

import SwiftUI
import Foundation

struct Toolbar: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @ObservedObject private var tool: Tool
    @ObservedObject private var canvas: Canvas
    @ObservedObject private var history: History

    @State private var title: String

    @FocusState private var textFieldState: Bool

    private let size: CGFloat = 40
    private let memo: MemoObject

    init(memo: MemoObject, tool: Tool, canvas: Canvas, history: History) {
        self.memo = memo
        self.tool = tool
        self.canvas = canvas
        self.history = history
        self.title = memo.title
    }
    
    var body: some View {
        HStack(spacing: 5) {
            HStack(spacing: 5) {
                closeButton
                titleField
                    .foregroundStyle(Color.primary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            #if os(macOS)
            ElementToolbar(tool: tool, canvas: canvas)
            #else
            if horizontalSizeClass == .regular {
                ElementToolbar(tool: tool, canvas: canvas)
            }
            #endif
            HStack(spacing: 5) {
                gridModeControl
                historyControl
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .font(.subheadline)
        .padding(10)
        .foregroundStyle(Color.accentColor)
    }

    private var closeButton: some View {
        Button {
            closeMemo()
        } label: {
            Image(systemName: "xmark")
                .frame(width: size, height: size)
                .background(.regularMaterial)
                .clipShape(.rect(cornerRadius: 8))
                .contentShape(.rect(cornerRadius: 8))
        }
        #if os(iOS)
        .hoverEffect(.lift)
        #else
        .buttonStyle(.plain)
        #endif
        .disabled(textFieldState)
        .transition(.move(edge: .top).combined(with: .blurReplace))
    }

    private var titleField: some View {
        TextField("", text: $title)
            .focused($textFieldState)
            .textFieldStyle(.plain)
            .padding(.horizontal, size / 2.5)
            .frame(width: horizontalSizeClass == .compact ? 100 : 140, height: size)
            .background(.regularMaterial)
            .clipShape(.rect(cornerRadius: 8))
            .onChange(of: textFieldState) { oldValue, newValue in
                if !newValue {
                    if !title.isEmpty {
                        memo.title = title
                        memo.updatedAt = .now
                    } else {
                        title = memo.title
                    }
                    withPersistence(\.viewContext) { context in
                        try context.saveIfNeeded()
                    }
                }
            }
            .transition(.move(edge: .top).combined(with: .blurReplace))
    }

    private var historyControl: some View {
        HStack(spacing: 0) {
            Button {
                history.historyPublisher.send(.undo)
            } label: {
                Image(systemName: "arrow.uturn.backward.circle")
                    .frame(width: size, height: size)
                    .contentShape(.rect(cornerRadius: 8))
            }
            #if os(iOS)
            .hoverEffect(.lift)
            #else
            .buttonStyle(.plain)
            #endif
            .disabled(history.undoDisabled)
            Button {
                history.historyPublisher.send(.redo)
            } label: {
                Image(systemName: "arrow.uturn.forward.circle")
                    .frame(width: size, height: size)
                    .contentShape(.rect(cornerRadius: 8))
            }
            #if os(iOS)
            .hoverEffect(.lift)
            #else
            .buttonStyle(.plain)
            #endif
            .disabled(history.redoDisabled)
        }
        .background(.regularMaterial)
        .clipShape(.rect(cornerRadius: 8))
        .disabled(textFieldState)
        .transition(.move(edge: .top).combined(with: .blurReplace))
    }

    private var gridModeControl: some View {
        #if os(macOS)
        Button {
            switch canvas.gridMode {
            case .none:
                canvas.gridMode = .point
            case .point:
                canvas.gridMode = .line
            case .line:
                canvas.gridMode = .none
            }
        } label: {
            Image(systemName: canvas.gridMode.icon)
                .frame(width: size, height: size)
                .background(.regularMaterial)
                .clipShape(.rect(cornerRadius: 8))
                .contentShape(.rect(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .contentTransition(.symbolEffect(.replace))
        .transition(.move(edge: .top).combined(with: .blurReplace))
        #else
        Menu {
            ForEach(GridMode.all, id: \.self) { mode in
                Button {
                    canvas.setGridMode(mode)
                } label: {
                    Label {
                        Text(mode.title)
                    } icon: {
                        Image(systemName: mode.icon)
                    }
                    .font(.headline)
                }
            }
        } label: {
            Image(systemName: canvas.gridMode.icon)
                .frame(width: size, height: size)
                .background(.regularMaterial)
                .clipShape(.rect(cornerRadius: 8))
                .contentShape(.rect(cornerRadius: 8))
        }
        .hoverEffect(.lift)
        .contentTransition(.symbolEffect(.replace))
        .transition(.move(edge: .top).combined(with: .blurReplace))
        #endif
    }

    private func closeMemo() {
        canvas.save(for: memo) {
            #if os(macOS)
            MemoManager.shared.closeMemo()
            #else
            dismiss()
            #endif
        }
    }
}
