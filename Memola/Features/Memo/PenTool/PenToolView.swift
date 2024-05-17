//
//  PenToolView.swift
//  Memola
//
//  Created by Dscyre Scotti on 5/4/24.
//

import SwiftUI

struct PenToolView: View {
    @EnvironmentObject var tool: Tool

    let width: CGFloat = 80
    let height: CGFloat = 30
    let factor: CGFloat = 1.22

    var body: some View {
        VStack(alignment: .trailing, spacing: 0) {
            ScrollView(.vertical, showsIndicators: false) {
                if tool.isReordering {
                    LazyVStack(spacing: 0) {
                        ForEach(tool.pens) { pen in
                            if pen.strokeStyle == .marker {
                                penView(pen)
                                    .offset(y: tool.isShaking ? 1.5 : -1.5)
                            } else {
                                penView(pen)
                            }
                        }
                    }
                    .padding(.vertical, 5)
                    .padding(.leading, 40)
                    .onAppear {
                        withAnimation(.easeInOut.repeatForever().speed(5)) {
                            tool.isShaking.toggle()
                        }
                    }
                    .id(tool.shakingId)
                } else {
                    LazyVStack(spacing: 0) {
                        ForEach(tool.pens) { pen in
                            penView(pen)
                        }
                    }
                    .padding(.vertical, 5)
                    .padding(.leading, 40)
                }
            }
            VStack(spacing: 0) {
                Divider()
                if tool.isReordering {
                    reorderCancelButton
                } else {
                    newPenButton
                }
            }
            .frame(width: width * factor - 20)
        }
        .frame(maxHeight: (height * factor + 10) * 8)
        .fixedSize()
        .background {
            HStack(spacing: 0) {
                Spacer(minLength: 70)
                RoundedRectangle(cornerRadius: 20)
                    .fill(.regularMaterial)
            }
        }
        .clipShape(.rect(cornerRadii: .init(bottomTrailing: 20, topTrailing: 20)))
    }

    @ViewBuilder
    func penView(_ pen: Pen) -> some View {
        ZStack {
            if let tip = pen.style.icon.tip {
                Image(tip)
                    .resizable()
                    .renderingMode(.template)
                    .foregroundStyle(Color.rgba(from: pen.color))
            }
            Image(pen.style.icon.base)
                .resizable()
        }
        .frame(width: width * factor, height: height * factor)
        .padding(.vertical, 5)
        .padding(.leading, 10)
        .contentShape(.rect(cornerRadii: .init(topLeading: 10, bottomLeading: 10)))
        .onTapGesture {
            if tool.selectedPen === pen {
                tool.unselectPen(pen)
            } else {
                tool.selectPen(pen)
            }
        }
        .disabled(tool.isReordering)
        .contextMenu(if: pen.strokeStyle != .eraser && !tool.isReordering) {
            Button {
                tool.isReordering = true
            } label: {
                Label("Rearrange", systemImage: "arrow.up.arrow.down.circle")
            }
            Button(role: .destructive) {
                tool.removePen(pen)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .onDrag(if: pen.strokeStyle != .eraser && tool.isReordering) {
            tool.draggedPen = pen
            return NSItemProvider(contentsOf: URL(string: pen.id)) ?? NSItemProvider()
        } preview: {
            penPreview(pen)
                .contentShape(.dragPreview, .rect(cornerRadius: 10))
        }
        .onDrop(of: [.item], delegate: PenDropDelegate(id: pen.id, tool: tool))
        .offset(x: tool.selectedPen === pen ? 0 : 28)
    }

    var newPenButton: some View {
        Button {
            let pen = PenObject.createObject(\.viewContext, penStyle: .marker)
            pen.color = [Color.red, Color.blue, Color.green, Color.black, Color.orange].randomElement()!.components
            pen.isSelected = true
            pen.tool = tool.object
            pen.orderIndex = Int16(tool.pens.count)
            let _pen = Pen(object: pen)
            tool.addPen(_pen)
        } label: {
            Image(systemName: "pencil.tip.crop.circle.badge.plus")
                .font(.title2)
                .contentShape(.circle)
        }
        .hoverEffect(.lift)
        .padding(10)
    }

    var reorderCancelButton: some View {
        Button {
            tool.isReordering = false
        } label: {
            Image(systemName: "xmark.circle")
                .font(.title2)
                .contentShape(.circle)
        }
        .hoverEffect(.lift)
        .padding(10)
    }

    func penPreview(_ pen: Pen) -> some View {
        ZStack {
            if let tip = pen.style.icon.tip {
                Image(tip)
                    .resizable()
                    .renderingMode(.template)
                    .foregroundStyle(Color.rgba(from: pen.color))
            }
            Image(pen.style.icon.base)
                .resizable()
        }
        .frame(width: width * factor, height: height * factor)
        .padding(.vertical, 5)
        .padding(.leading, 10)
    }
}
