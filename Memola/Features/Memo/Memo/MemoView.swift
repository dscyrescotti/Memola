//
//  MemoView.swift
//  Memola
//
//  Created by Dscyre Scotti on 5/4/24.
//

import SwiftUI
import CoreData

struct MemoView: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    @StateObject var tool: Tool
    @StateObject var canvas: Canvas
    @StateObject var history: History

    @State var memo: MemoObject
    @State var title: String
    @FocusState var textFieldState: Bool

    let size: CGFloat = 32

    init(memo: MemoObject) {
        self.memo = memo
        self.title = memo.title
        self._tool = StateObject(wrappedValue: Tool(object: memo.tool))
        self._canvas = StateObject(wrappedValue: Canvas(size: memo.canvas.size, canvasID: memo.canvas.objectID, gridMode: memo.canvas.gridMode))
        self._history = StateObject(wrappedValue: History(memo: memo))
    }

    var body: some View {
        Group {
            if horizontalSizeClass == .regular {
                canvasView
            } else {
                compactCanvasView
            }
        }
        .overlay(alignment: .top) {
            Toolbar(size: size, memo: memo, tool: tool, canvas: canvas, history: history)
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
    }

    var canvasView: some View {
        CanvasView(tool: tool, canvas: canvas, history: history)
            .ignoresSafeArea()
            .overlay(alignment: .bottomTrailing) {
                switch tool.selection {
                case .pen:
                    PenDock(tool: tool, canvas: canvas, size: size)
                        .transition(.move(edge: .trailing).combined(with: .blurReplace))
                case .photo:
                    if let photoItem = tool.selectedPhotoItem {
                        PhotoPreview(photoItem: photoItem, tool: tool)
                            .transition(.move(edge: .trailing).combined(with: .blurReplace))
                    }
                default:
                    EmptyView()
                }
            }
            .overlay(alignment: .bottomLeading) {
                zoomControl
            }
    }

    var compactCanvasView: some View {
        CanvasView(tool: tool, canvas: canvas, history: history)
            .ignoresSafeArea()
            .overlay(alignment: .bottom) {
                switch tool.selection {
                case .pen:
                    PenDock(tool: tool, canvas: canvas, size: size)
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
                    ElementToolbar(size: size, tool: tool, canvas: canvas)
                        .transition(.move(edge: .bottom).combined(with: .blurReplace))
                }
            }
            .overlay(alignment: .bottom) {
                if tool.selection != .hand {
                    Button {
                        withAnimation {
                            tool.selectTool(.hand)
                        }
                    } label: {
                        Image(systemName: "chevron.compact.down")
                            .font(.headline)
                            .frame(width: 80)
                            .padding(5)
                            .background(.regularMaterial)
                            .clipShape(.capsule)
                            .contentShape(.capsule)
                    }
                    .offset(y: 5)
                }
            }
    }

    @ViewBuilder
    var zoomControl: some View {
        let upperBound: CGFloat = 400
        let lowerBound: CGFloat = 10
        let zoomScale: CGFloat = (((canvas.zoomScale - canvas.minimumZoomScale) * (upperBound - lowerBound) / (canvas.maximumZoomScale - canvas.minimumZoomScale)) + lowerBound).rounded()
        let zoomScales: [Int] = [400, 200, 100, 75, 50, 25, 10]
        if !canvas.locksCanvas {
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
                    .padding(10)
            }
            #if os(iOS)
            .hoverEffect(.lift)
            #endif
            .transition(.move(edge: .bottom).combined(with: .blurReplace))
        }
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
