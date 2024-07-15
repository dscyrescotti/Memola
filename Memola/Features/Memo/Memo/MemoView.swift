//
//  MemoView.swift
//  Memola
//
//  Created by Dscyre Scotti on 5/4/24.
//

import SwiftUI
import CoreData

struct MemoView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @StateObject private var tool: Tool
    @StateObject private var canvas: Canvas
    @StateObject private var history: History

    @State private var title: String
    @FocusState private var textFieldState: Bool

    private let memo: MemoObject
    private let size: CGFloat = 40

    init(memo: MemoObject) {
        self.memo = memo
        self.title = memo.title
        self._tool = StateObject(wrappedValue: Tool(object: memo.tool))
        self._canvas = StateObject(wrappedValue: Canvas(size: memo.canvas.size, canvasID: memo.canvas.objectID, gridMode: memo.canvas.gridMode))
        self._history = StateObject(wrappedValue: History(memo: memo))
    }

    var body: some View {
        Group {
            #if os(macOS)
            canvasView
            #else
            if horizontalSizeClass == .regular {
                canvasView
            } else {
                compactCanvasView
            }
            #endif
        }
        .overlay(alignment: .top) {
            Toolbar(memo: memo, tool: tool, canvas: canvas, history: history)
        }
        .disabled(textFieldState || tool.isLoadingPhoto)
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
        .overlay {
            if tool.isLoadingPhoto {
                loadingIndicator("Loading photo...")
            }
        }
        .focusedSceneObject(tool)
        .focusedSceneObject(canvas)
        .focusedSceneObject(history)
        .focusedSceneValue(\.activeSceneKey, .memo)
    }

    private var canvasView: some View {
        CanvasView(tool: tool, canvas: canvas, history: history)
            .ignoresSafeArea()
            .overlay(alignment: .trailing) {
                switch tool.selection {
                case .pen:
                    PenDock(tool: tool, canvas: canvas)
                case .photo:
                    ZStack(alignment: .bottomTrailing) {
                        PhotoDock(tool: tool, canvas: canvas)
                        if let photoItem = tool.selectedPhotoItem {
                            PhotoPreview(photoItem: photoItem, tool: tool)
                                .transition(.move(edge: .trailing).combined(with: .blurReplace))
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                default:
                    EmptyView()
                }
            }
            .overlay(alignment: .bottomLeading) {
                zoomControl
            }
    }

    private var compactCanvasView: some View {
        CanvasView(tool: tool, canvas: canvas, history: history)
            .ignoresSafeArea()
            .overlay(alignment: .bottom) {
                switch tool.selection {
                case .pen:
                    PenDock(tool: tool, canvas: canvas)
                        .transition(.move(edge: .bottom).combined(with: .blurReplace))
                case .photo:
                    if let photoItem = tool.selectedPhotoItem {
                        PhotoPreview(photoItem: photoItem, tool: tool)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .transition(.move(edge: .trailing))
                    }
                default:
                    EmptyView()
                }
            }
            .overlay(alignment: .bottom) {
                if tool.selection != .pen {
                    ElementToolbar(tool: tool, canvas: canvas)
                        .transition(.move(edge: .bottom).combined(with: .blurReplace))
                }
            }
    }

    @ViewBuilder
    private var zoomControl: some View {
        let upperBound: CGFloat = 400
        let lowerBound: CGFloat = 10
        let zoomScale: CGFloat = (((canvas.zoomScale - canvas.minimumZoomScale) * (upperBound - lowerBound) / (canvas.maximumZoomScale - canvas.minimumZoomScale)) + lowerBound).rounded()
        let zoomScales: [Int] = [400, 200, 100, 75, 50, 25, 10]
        #if os(macOS)
        Menu {
            ForEach(zoomScales, id: \.self) { scale in
                Button {
                    let zoomScale = ((CGFloat(scale) - lowerBound) * (canvas.maximumZoomScale - canvas.minimumZoomScale) / (upperBound - lowerBound)) + canvas.minimumZoomScale
                    canvas.zoomPublisher.send(zoomScale)
                } label: {
                    Label {
                        Text(scale, format: .percent)
                    } icon: {
                        if CGFloat(scale) == zoomScale {
                            Image(systemName: "checkmark")
                        }
                    }
                    .font(.headline)
                }
            }
        } label: {
            Text(zoomScale / 100, format: .percent)
                .foregroundStyle(Color.accentColor)
                .font(.subheadline)
                .frame(height: size)
                .clipShape(.rect(cornerRadius: 8))
                .contentShape(.rect(cornerRadius: 8))
        }
        .menuIndicator(.hidden)
        .frame(width: 50, height: size)
        .padding(.leading, 12)
        .background(.regularMaterial)
        .clipShape(.rect(cornerRadius: 8))
        .contentShape(.rect(cornerRadius: 8))
        .menuStyle(.borderlessButton)
        .transition(.move(edge: .bottom).combined(with: .blurReplace))
        .padding(10)
        #else
        Menu {
            ForEach(zoomScales, id: \.self) { scale in
                Button {
                    let zoomScale = ((CGFloat(scale) - lowerBound) * (canvas.maximumZoomScale - canvas.minimumZoomScale) / (upperBound - lowerBound)) + canvas.minimumZoomScale
                    canvas.zoomPublisher.send(zoomScale)
                } label: {
                    Label {
                        Text(scale, format: .percent)
                    } icon: {
                        if CGFloat(scale) == zoomScale {
                            Image(systemName: "checkmark")
                        }
                    }
                    .font(.headline)
                }
            }
        } label: {
            Text(zoomScale / 100, format: .percent)
                .frame(width: 45)
                .font(.subheadline)
                .padding(.horizontal, size / 2.5)
                .frame(height: size)
                .background(.regularMaterial)
                .clipShape(.rect(cornerRadius: 8))
                .contentShape(.rect(cornerRadius: 8))
                .padding(10)
        }
        .hoverEffect(.lift)
        .transition(.move(edge: .bottom).combined(with: .blurReplace))
        #endif
    }

    private func loadingIndicator(_ title: String) -> some View {
        ProgressView {
            Text(title)
        }
        .progressViewStyle(.circular)
        .padding(20)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}
