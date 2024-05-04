//
//  MemoView.swift
//  Memola
//
//  Created by Dscyre Scotti on 5/4/24.
//

import SwiftUI

struct MemoView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) var managedObjectContext

    @StateObject var tool = Tool()
    @StateObject var history = History()

    @EnvironmentObject var canvas: Canvas

    var body: some View {
        CanvasView()
            .ignoresSafeArea()
            .overlay(alignment: .bottomTrailing) {
                PenToolView()
                    .padding()
            }
            .overlay(alignment: .topTrailing) {
                historyTool
                    .padding()
            }
            .overlay(alignment: .topLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .padding(15)
                        .background(.regularMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                }
                .hoverEffect(.lift)
                .padding()
            }
            .disabled(canvas.state == .loading)
            .overlay {
                if canvas.state == .loading {
                    ProgressView {
                        Text("Loading memo...")
                    }
                    .progressViewStyle(.circular)
                    .padding(20)
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                }
            }
            .environmentObject(tool)
            .environmentObject(canvas)
            .environmentObject(history)
            .task {
                canvas.listen(on: managedObjectContext)
            }
    }

    var historyTool: some View {
        HStack {
            Button {
                history.historyPublisher.send(.undo)
            } label: {
                Image(systemName: "arrow.uturn.backward.circle")
            }
            .hoverEffect(.lift)
            .disabled(history.undoDisabled)
            Button {
                history.historyPublisher.send(.redo)
            } label: {
                Image(systemName: "arrow.uturn.forward.circle")
            }
            .hoverEffect(.lift)
            .disabled(history.redoDisabled)
        }
        .padding(15)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}
