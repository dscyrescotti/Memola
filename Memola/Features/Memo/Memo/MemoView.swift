//
//  MemoView.swift
//  Memola
//
//  Created by Dscyre Scotti on 5/4/24.
//

import SwiftUI
import CoreData

struct MemoView: View {
    @Environment(\.dismiss) var dismiss

    @StateObject var tool: Tool
    @StateObject var canvas: Canvas
    @StateObject var history = History()

    let memo: MemoObject

    init(memo: MemoObject) {
        self.memo = memo
        self._tool = StateObject(wrappedValue: Tool(object: memo.tool))
        self._canvas = StateObject(wrappedValue: Canvas(size: memo.canvas.size, canvasID: memo.canvas.objectID))
    }

    var body: some View {
        CanvasView()
            .ignoresSafeArea()
            .overlay(alignment: .topTrailing) {
                VStack(alignment: .trailing, spacing: 20) {
                    historyTool
                    PenToolView()
                }
                .padding()
            }
            .overlay(alignment: .topLeading) {
                Button {
                    closeMemo()
                } label: {
                    Image(systemName: "xmark")
                        .contentShape(.circle)
                        .padding(15)
                        .background(.regularMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                }
                .hoverEffect(.lift)
                .padding()
            }
            .disabled(canvas.state == .loading || canvas.state == .closing)
            .overlay {
                switch canvas.state {
                case .loading:
                    progressView("Loading memo...")
                case .closing:
                    progressView("Saving memo...")
                default:
                    EmptyView()
                }
            }
            .environmentObject(tool)
            .environmentObject(canvas)
            .environmentObject(history)
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
        .padding(15)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    func progressView(_ title: String) -> some View {
        ProgressView {
            Text(title)
        }
        .progressViewStyle(.circular)
        .padding(20)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    func closeMemo() {
        withPersistenceSync(\.viewContext) { context in
            try context.saveIfNeeded()
        }
        dismiss()
    }
}
