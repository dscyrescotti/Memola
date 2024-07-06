//
//  CanvasView.swift
//  Memola
//
//  Created by Dscyre Scotti on 5/4/24.
//

import SwiftUI

struct CanvasView: Platform.ViewControllerRepresentable {
    @ObservedObject var tool: Tool
    @ObservedObject var canvas: Canvas
    @ObservedObject var history: History

    #if os(macOS)
    func makeNSViewController(context: Context) -> CanvasViewController {
        CanvasViewController(tool: tool, canvas: canvas, history: history)
    }

    func updateNSViewController(_ nsViewController: CanvasViewController, context: Context) { }
    #else
    func makeUIViewController(context: Context) -> CanvasViewController {
        CanvasViewController(tool: tool, canvas: canvas, history: history)
    }

    func updateUIViewController(_ uiViewController: CanvasViewController, context: Context) { }
    #endif
}
