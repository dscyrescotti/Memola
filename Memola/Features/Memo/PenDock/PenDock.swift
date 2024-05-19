//
//  PenDock.swift
//  Memola
//
//  Created by Dscyre Scotti on 5/4/24.
//

import SwiftUI

struct PenDock: View {
    @EnvironmentObject var tool: Tool

    let width: CGFloat = 90
    let height: CGFloat = 30
    let factor: CGFloat = 0.9

    @State var refreshScrollId: UUID = UUID()
    @State var opensColorPicker: Bool = false

    var body: some View {
        VStack(alignment: .trailing) {
            penPropertyTool
            penItemList
        }
        .fixedSize()
        .frame(maxHeight: .infinity)
        .padding(10)
    }

    var penItemList: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 0) {
                    ForEach(tool.pens) { pen in
                        penItemRow(pen)
                            .id(pen.id)
                            .scrollTransition { content, phase in
                                content
                                    .scaleEffect(phase.isIdentity ? 1 : 0.04, anchor: .trailing)
                            }
                    }
                }
                .padding(.vertical, 10)
                .padding(.leading, 40)
                .id(refreshScrollId)
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
            RoundedRectangle(cornerRadius: 8)
                .fill(.regularMaterial)
                .frame(width: width * factor - 18)
        }
        .clipShape(.rect(cornerRadii: .init(bottomTrailing: 8, topTrailing: 8)))
        .overlay(alignment: .bottomLeading) {
            newPenButton
                .offset(x: 60, y: 10)
        }
    }

    func penItemRow(_ pen: Pen) -> some View {
        ZStack {
            penShadow(pen)
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
                    tool.selectPen(pen)
                } label: {
                    Label(
                        title: { Text("Select") },
                        icon: { Image(systemName: "pencil.tip.crop.circle") }
                    )
                }
                Button {
                    let originalPen = pen
                    let pen = PenObject.createObject(\.viewContext, penStyle: originalPen.style)
                    pen.color = originalPen.rgba
                    pen.thickness = originalPen.thickness
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
                .disabled(tool.markers.count <= 1)
            }
            .controlGroupStyle(.menu)
        } preview: {
            penPreview(pen)
                .drawingGroup()
                .contentShape(.contextMenuPreview, .rect(cornerRadius: 10))
        }
        .onDrag(if: pen.strokeStyle != .eraser) {
            tool.draggedPen = pen
            return NSItemProvider(contentsOf: URL(string: pen.id)) ?? NSItemProvider()
        } preview: {
            penPreview(pen)
                .contentShape(.dragPreview, .rect(cornerRadius: 10))
        }
        .onDrop(of: [.item], delegate: PenDropDelegate(id: pen.id, tool: tool, action: { refreshScrollId = UUID() }))
        .offset(x: tool.selectedPen === pen ? 0 : 25)
    }

    @ViewBuilder
    var penPropertyTool: some View {
        if let pen = tool.selectedPen {
            VStack(spacing: 5) {
                if pen.strokeStyle == .marker {
                    penColorPicker(pen)
                }
                penThicknessPicker(pen)
            }
            .padding(10)
            .frame(width: width * factor - 18)
            .background {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.regularMaterial)
            }
            .transition(.move(edge: .trailing).combined(with: .opacity))
        } else {
            Color.clear
                .frame(width: width * factor - 18, height: 50)
        }
    }

    func penColorPicker(_ pen: Pen) -> some View {
        Button {
            opensColorPicker = true
        } label: {
            let hsba = pen.color.hsba
            let baseColor = Color(hue: hsba.hue, saturation: hsba.saturation, brightness: hsba.brightness)
            GeometryReader { proxy in
                HStack(spacing: 0) {
                    baseColor
                        .frame(width: proxy.size.width / 2)
                    Image("transparent-grid-square")
                        .resizable()
                        .scaleEffect(3)
                        .aspectRatio(contentMode: .fill)
                        .opacity(1 - hsba.alpha)
                        .frame(width: proxy.size.width / 2)
                        .clipped()
                }
            }
            .background(baseColor)
            .clipShape(.rect(cornerRadius: 8))
            .frame(height: 25)
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray, lineWidth: 0.4)
            }
            .padding(0.2)
            .drawingGroup()
        }
        .hoverEffect(.lift)
        .popover(isPresented: $opensColorPicker) {
            let color = Binding(
                get: { pen.color },
                set: {
                    pen.color = $0
                    tool.objectWillChange.send()
                }
            )
            ColorPicker(color: color)
                .presentationCompactAdaptation(.popover)
        }
    }

    @ViewBuilder
    func penThicknessPicker(_ pen: Pen) -> some View {
        let minimum: CGFloat = pen.style.thickness.min
        let maximum: CGFloat = pen.style.thickness.max
        let start: CGFloat = 4
        let end: CGFloat = 10
        let selection = Binding(
            get: { pen.thickness },
            set: { 
                pen.thickness = $0
                tool.objectWillChange.send()
            }
        )
        Picker("", selection: selection) {
            ForEach(pen.style.thicknessSteps, id: \.self) { step in
                let size = ((step - minimum) * (end - start) / (maximum - minimum)) + start - (0.5 / step)
                Circle()
                    .fill(.black)
                    .frame(width: size, height: size)
                    .frame(width: size + 2, height: size + 2)
            }
        }
        .pickerStyle(.wheel)
        .frame(width: width * factor - 18, height: 35)
    }

    var newPenButton: some View {
        Button {
            let pen = PenObject.createObject(\.viewContext, penStyle: .marker)
            if let color = (tool.selectedPen ?? tool.pens.last)?.rgba {
                pen.color = color
            }
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

    func penShadow(_ pen: Pen) -> some View {
        ZStack {
            Group {
                if let tip = pen.style.icon.tip {
                    Image(tip)
                        .resizable()
                        .renderingMode(.template)
                }
                Image(pen.style.icon.base)
                    .resizable()
                    .renderingMode(.template)
            }
            .drawingGroup()
            .foregroundStyle(.black.opacity(0.2))
            .blur(radius: 3)
            if let tip = pen.style.icon.tip {
                Image(tip)
                    .resizable()
                    .renderingMode(.template)
                    .foregroundStyle(Color(red: pen.rgba[0], green: pen.rgba[1], blue: pen.rgba[2]))
                    .blur(radius: 0.5)
            }
        }
    }
}
