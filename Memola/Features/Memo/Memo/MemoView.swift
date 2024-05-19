//
//  MemoView.swift
//  Memola
//
//  Created by Dscyre Scotti on 5/4/24.
//

import SwiftUI
import CoreData

struct MemoView: View {
    @StateObject var tool: Tool
    @StateObject var canvas: Canvas
    @StateObject var history = History()

    @State var memo: MemoObject
    @State var title: String
    @FocusState var textFieldState: Bool

    init(memo: MemoObject) {
        self.memo = memo
        self.title = memo.title
        self._tool = StateObject(wrappedValue: Tool(object: memo.tool))
        self._canvas = StateObject(wrappedValue: Canvas(size: memo.canvas.size, canvasID: memo.canvas.objectID))
    }

    var body: some View {
        CanvasView()
            .ignoresSafeArea()
            .overlay(alignment: .trailing) {
                PenDock()
            }
            .disabled(textFieldState)
            .overlay(alignment: .top) {
                Toolbar(memo: memo)
            }
            .disabled(canvas.state == .loading || canvas.state == .closing)
            .overlay {
                switch canvas.state {
                case .loading:
                    loadingIndicator("Loading memo...")
                case .closing:
                    loadingIndicator("Saving memo...")
                default:
                    EmptyView()
                }
            }
            .environmentObject(tool)
            .environmentObject(canvas)
            .environmentObject(history)
    }

    func loadingIndicator(_ title: String) -> some View {
        ProgressView {
            Text(title)
        }
        .progressViewStyle(.circular)
        .padding(20)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}
