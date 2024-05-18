//
//  PenDockView.swift
//  Memola
//
//  Created by Dscyre Scotti on 5/4/24.
//

import SwiftUI

struct PenDockView: View {
    @EnvironmentObject var tool: Tool

    let width: CGFloat = 90
    let height: CGFloat = 30
    let factor: CGFloat = 0.95

    var body: some View {
        VStack(alignment: .trailing) {
            if let pen = tool.selectedPen {
                VStack(spacing: 10) {
                    Button {
                        tool.opensColorPicker = true
                    } label: {
                        let hsba = pen.color.hsba
                        Color(hue: hsba.hue, saturation: hsba.saturation, brightness: hsba.brightness)
                            .overlay {
                                Image("transparent-grid-square")
                                    .resizable()
                                    .scaleEffect(1.8)
                                    .aspectRatio(contentMode: .fill)
                                    .opacity(0.5)
                                    .overlay {
                                        pen.color
                                    }
                                    .clipShape(Triangle())
                            }
                            .clipShape(Capsule())
                            .frame(height: 20)
                            .drawingGroup()
                    }
                    .hoverEffect(.lift)
                    .popover(isPresented: $tool.opensColorPicker) {
                        ColorPicker(pen: pen)
                            .presentationCompactAdaptation(.popover)
                    }
                    Capsule()
                        .frame(height: 20)
                }
                .padding()
                .frame(width: width * factor - 18)
                .background {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.regularMaterial)
                }
                .transition(.move(edge: .trailing).combined(with: .opacity))
            } else {
                Color.clear
                    .frame(width: width * factor - 18, height: 50)
            }
            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 0) {
                        ForEach(tool.pens) { pen in
                            penView(pen)
                                .id(pen.id)
                                .scrollTransition { content, phase in
                                    content
                                        .scaleEffect(phase.isIdentity ? 1 : 0.04, anchor: .trailing)
                                }
                        }
                    }
                    .padding(.vertical, 10)
                    .padding(.leading, 40)
                }
                .onReceive(tool.scrollPublisher) { id in
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        withAnimation {
                            proxy.scrollTo(id)
                        }
                    }
                }
            }
            .frame(maxHeight:( (height * factor + 10) * 6) + 20)
            .fixedSize()
            .background(alignment: .trailing) {
                RoundedRectangle(cornerRadius: 20)
                    .fill(.regularMaterial)
                    .frame(width: width * factor - 18)
            }
            .clipShape(.rect(cornerRadii: .init(bottomTrailing: 20, topTrailing: 20)))
            .overlay(alignment: .bottomLeading) {
                newPenButton
                    .offset(x: 60, y: 10)
            }
        }
        .fixedSize()
    }

    @ViewBuilder
    func penView(_ pen: Pen) -> some View {
        ZStack {
            if let tip = pen.style.icon.tip {
                Image(tip)
                    .resizable()
                    .renderingMode(.template)
                    .foregroundStyle(Color.rgba(from: pen.rgba))
            }
            Image(pen.style.icon.base)
                .resizable()
        }
        .frame(width: width * factor, height: height * factor)
        .padding(.vertical, 5)
        .contentShape(.rect(cornerRadii: .init(topLeading: 10, bottomLeading: 10)))
        .onTapGesture {
            if tool.selectedPen === pen {
                tool.unselectPen(pen)
            } else {
                tool.selectPen(pen)
            }
        }
        .padding(.leading, 10)
        .contextMenu(if: pen.strokeStyle != .eraser) {
            ControlGroup {
                Button {
                    let originalPen = pen
                    let pen = PenObject.createObject(\.viewContext, penStyle: originalPen.style)
                    pen.color = originalPen.rgba
                    pen.isSelected = true
                    pen.tool = tool.object
                    let _pen = Pen(object: pen)
                    tool.duplicatePen(_pen, of: originalPen)
                } label: {
                    Label(
                        title: { Text("Duplicate") },
                        icon: { Image(systemName: "plus.square.on.square") }
                    )
                }
                Button(role: .destructive) {
                    tool.removePen(pen)
                } label: {
                    Label(
                        title: { Text("Remove") },
                        icon: { Image(systemName: "trash") }
                    )
                }
            }
            .controlGroupStyle(.menu)
        }
        .onDrag(if: pen.strokeStyle != .eraser) {
            tool.draggedPen = pen
            return NSItemProvider(contentsOf: URL(string: pen.id)) ?? NSItemProvider()
        } preview: {
            penPreview(pen)
                .contentShape(.dragPreview, .rect(cornerRadius: 10))
        }
        .onDrop(of: [.item], delegate: PenDropDelegate(id: pen.id, tool: tool))
        .offset(x: tool.selectedPen === pen ? 0 : 25)
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
            Image(systemName: "plus.circle.fill")
                .font(.title2)
                .padding(1)
                .contentShape(.circle)
                .background {
                    Circle()
                        .fill(.white)
                }
        }
        .foregroundStyle(.green)
        .hoverEffect(.lift)
    }

    func penPreview(_ pen: Pen) -> some View {
        ZStack {
            if let tip = pen.style.icon.tip {
                Image(tip)
                    .resizable()
                    .renderingMode(.template)
                    .foregroundStyle(Color.rgba(from: pen.rgba))
            }
            Image(pen.style.icon.base)
                .resizable()
        }
        .frame(width: width * factor, height: height * factor)
        .padding(.vertical, 5)
        .padding(.leading, 10)
    }
}
