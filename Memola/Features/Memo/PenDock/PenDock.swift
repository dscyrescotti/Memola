//
//  PenDock.swift
//  Memola
//
//  Created by Dscyre Scotti on 5/4/24.
//

import SwiftUI

struct PenDock: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @ObservedObject var tool: Tool
    @ObservedObject var canvas: Canvas

    let size: CGFloat = 40
    let penPropertySize: CGFloat = 32
    var width: CGFloat {
        horizontalSizeClass == .compact ? size / 2 : size
    }
    var height: CGFloat {
        horizontalSizeClass == .compact ? size : size / 2
    }

    @State var refreshScrollId: UUID = UUID()
    @State var opensColorPicker: Bool = false
    #if os(macOS)
    @State var showsThinknessPicker: Bool = false
    #endif

    var body: some View {
        #if os(macOS)
        GeometryReader { proxy in
            VStack(alignment: .trailing, spacing: 5) {
                penPropertyTool
                penItemList
                    .frame(maxWidth: proxy.size.width * 0.4)
            }
            .fixedSize()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
        }
        .padding(10)
        .transition(.move(edge: .trailing).combined(with: .blurReplace))
        #else
        if horizontalSizeClass == .regular {
            GeometryReader { proxy in
                VStack(alignment: .trailing, spacing: 5) {
                    penPropertyTool
                    penItemList
                        .frame(maxHeight: proxy.size.height * 0.4)
                }
                .fixedSize()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
            }
            .padding(10)
            .transition(.move(edge: .trailing).combined(with: .blurReplace))
        } else {
            GeometryReader { proxy in
                HStack(alignment: .bottom, spacing: 10) {
                    newPenButton
                        .padding(.leading, 10)
                        .frame(height: height)
                    compactPenItemList
                        .fixedSize(horizontal: false, vertical: true)
                    HStack(spacing: 0) {
                        compactPenPropertyTool
                        Divider()
                            .padding(.vertical, 4)
                            .frame(height: size)
                            .foregroundStyle(Color.accentColor)
                            .padding(.leading, 8)
                        Button {
                            withAnimation {
                                tool.selectTool(.hand)
                            }
                        } label: {
                            Image(systemName: "xmark")
                                .frame(width: size, height: size)
                                .clipShape(.rect(cornerRadius: 8))
                                .contentShape(.rect(cornerRadius: 8))
                        }
                        #if os(iOS)
                        .hoverEffect(.lift)
                        #else
                        .buttonStyle(.plain)
                        #endif
                    }
                }
                .clipped()
                .background(alignment: .bottom) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.regularMaterial)
                        .frame(height: height)
                }
                .padding([.horizontal, .bottom], 10)
                .frame(maxWidth: min(proxy.size.height, proxy.size.width), maxHeight: .infinity, alignment: .bottom)
                .frame(maxWidth: .infinity)
            }
            .transition(.move(edge: .bottom).combined(with: .blurReplace))
        }
        #endif
    }

    @ViewBuilder
    var penItemList: some View {
        VStack(alignment: .trailing, spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 5) {
                        ForEach(tool.pens) { pen in
                            penItem(pen)
                                .id(pen.id)
                                .scrollTransition { content, phase in
                                    content
                                        .scaleEffect(phase.isIdentity ? 1 : 0.04, anchor: .trailing)
                                }
                        }
                    }
                    .padding(.vertical, 5)
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
            newPenButton
                .padding(.vertical, 5)
                .frame(width: width)
        }
        .padding(.vertical, 3)
        .background(alignment: .trailing) {
            RoundedRectangle(cornerRadius: 8)
                .fill(.regularMaterial)
                .frame(width: width)
        }
    }

    @ViewBuilder
    var compactPenItemList: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 0) {
                    ForEach(tool.pens) { pen in
                        compactPenItem(pen)
                            .id(pen.id)
                            .scrollTransition { content, phase in
                                content
                                    .scaleEffect(phase.isIdentity ? 1 : 0.04, anchor: .bottom)
                            }
                    }
                }
                .padding(.horizontal, 5)
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
    }

    func penItem(_ pen: Pen) -> some View {
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
        .frame(width: width * 1.2, height: height * 0.9)
        .padding(.vertical, 5)
        .padding(.leading, 10)
        .contentShape(.rect)
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
                #if os(iOS)
                .contentShape(.contextMenuPreview, .rect(cornerRadius: 10))
                #else
                #endif
        }
        .onDrag(if: pen.strokeStyle != .eraser) {
            tool.draggedPen = pen
            return NSItemProvider(contentsOf: URL(string: pen.id)) ?? NSItemProvider()
        } preview: {
            penPreview(pen)
                .contentShape(.dragPreview, .rect(cornerRadius: 10))
        }
        .onDrop(of: [.item], delegate: PenDropDelegate(id: pen.id, tool: tool, action: { refreshScrollId = UUID() }))
        .offset(x: tool.selectedPen === pen ? 0 : 16)
        .contentShape(.rect)
        .onTapGesture {
            if tool.selectedPen !== pen {
                tool.selectPen(pen)
            }
        }
    }

    func compactPenItem(_ pen: Pen) -> some View {
        ZStack {
            compactPenShadow(pen)
            if let tip = pen.style.compactIcon.tip {
                Image(tip)
                    .resizable()
                    .renderingMode(.template)
                    .foregroundStyle(Color.rgba(from: pen.rgba))
            }
            Image(pen.style.compactIcon.base)
                .resizable()
        }
        .frame(width: width * 0.9, height: height * 1.2)
        .padding(.top, 5)
        .contentShape(.rect(cornerRadii: .init(topLeading: 10, bottomLeading: 10)))
        .onTapGesture {
            if tool.selectedPen !== pen {
                tool.selectPen(pen)
            }
        }
        .padding(.horizontal, 6)
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
            compactPenPreview(pen)
                .drawingGroup()
                #if os(iOS)
                .contentShape(.contextMenuPreview, .rect(cornerRadius: 10))
                #else
                #endif
        }
        .onDrag(if: pen.strokeStyle != .eraser) {
            tool.draggedPen = pen
            return NSItemProvider(contentsOf: URL(string: pen.id)) ?? NSItemProvider()
        } preview: {
            compactPenPreview(pen)
                .contentShape(.dragPreview, .rect(cornerRadius: 10))
        }
        .onDrop(of: [.item], delegate: PenDropDelegate(id: pen.id, tool: tool, action: { refreshScrollId = UUID() }))
        .offset(y: tool.selectedPen === pen ? 0 : 16)
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
            .padding(.vertical, 5)
            .frame(width: width)
            .background {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.regularMaterial)
            }
        } else {
            Color.clear
                .frame(width: width, height: 50)
        }
    }

    @ViewBuilder
    var compactPenPropertyTool: some View {
        if let pen = tool.selectedPen {
            HStack(spacing: 8) {
                penThicknessPicker(pen)
                    .frame(width: penPropertySize)
                    .rotationEffect(.degrees(-90))
                if pen.strokeStyle == .marker {
                    penColorPicker(pen)
                        .frame(width: penPropertySize)
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                }
            }
            .frame(height: height)
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
            .contentShape(.rect(cornerRadius: 8))
            .frame(width: penPropertySize, height: penPropertySize)
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray, lineWidth: 0.4)
            }
            .padding(0.2)
            .drawingGroup()
        }
        .buttonStyle(.plain)
        #if os(iOS)
        .hoverEffect(.lift)
        #endif
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
                .onDisappear {
                    withPersistence(\.viewContext) { context in
                        try context.saveIfNeeded()
                    }
                }
        }
    }

    @ViewBuilder
    func penThicknessPicker(_ pen: Pen) -> some View {
        let minimum: CGFloat = pen.style.thickness.min
        let maximum: CGFloat = pen.style.thickness.max
        let start: CGFloat = 4
        let end: CGFloat = 10
        let selection = Binding<CGFloat?>(
            get: { pen.thickness },
            set: {
                pen.thickness = $0 ?? .zero
                tool.objectWillChange.send()
            }
        )
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 0) {
                    ForEach(pen.style.thicknessSteps, id: \.self) { step in
                        let size = ((step - minimum) * (end - start) / (maximum - minimum)) + start - (0.5 / step)
                        Circle()
                            .foregroundStyle(.primary)
                            .frame(width: size, height: size)
                            .frame(width: penPropertySize, height: penPropertySize)
                            .contentShape(.rect)
                            .id(step)
                    }
                }
            }
            .frame(width: penPropertySize, height: penPropertySize)
            .background(.gray.quaternary)
            .clipShape(.rect(cornerRadius: 8))
            .scrollPosition(id: selection, anchor: .center)
            .scrollTargetLayout()
            .scrollTargetBehavior(.viewAligned)
            .scrollIndicators(.hidden)
            .onAppear {
                proxy.scrollTo(selection.wrappedValue)
            }
            .onChange(of: pen.thickness) { _, _ in
                withPersistence(\.viewContext) { context in
                    try context.saveIfNeeded()
                }
            }
        }
    }

    var newPenButton: some View {
        Button {
            createNewPen()
        } label: {
            Image(systemName: "plus.circle.fill")
                .font(.headline)
                .padding(1)
                .contentShape(.circle)
                .background {
                    Circle()
                        .fill(.white)
                }
        }
        .foregroundStyle(.green)
        #if os(iOS)
        .hoverEffect(.lift)
        #else
        .buttonStyle(.plain)
        #endif
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
        .frame(width: width * 1.2, height: height * 0.9)
        .padding(.vertical, 5)
        .padding(.leading, 10)
    }

    func compactPenPreview(_ pen: Pen) -> some View {
        ZStack {
            if let tip = pen.style.compactIcon.tip {
                Image(tip)
                    .resizable()
                    .renderingMode(.template)
                    .foregroundStyle(Color.rgba(from: pen.rgba))
            }
            Image(pen.style.compactIcon.base)
                .resizable()
        }
        .frame(width: width * 0.9, height: height * 1.2)
        .padding(.top, 5)
        .padding(.horizontal, 5)
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

    func compactPenShadow(_ pen: Pen) -> some View {
        ZStack {
            Group {
                if let tip = pen.style.compactIcon.tip {
                    Image(tip)
                        .resizable()
                        .renderingMode(.template)
                }
                Image(pen.style.compactIcon.base)
                    .resizable()
                    .renderingMode(.template)
            }
            .foregroundStyle(.black.opacity(0.2))
            .blur(radius: 3)
            if let tip = pen.style.compactIcon.tip {
                Image(tip)
                    .resizable()
                    .renderingMode(.template)
                    .foregroundStyle(Color(red: pen.rgba[0], green: pen.rgba[1], blue: pen.rgba[2]))
                    .blur(radius: 0.5)
            }
        }
    }

    func createNewPen() {
        let pen = PenObject.createObject(\.viewContext, penStyle: .marker)
        var selectedPen = tool.selectedPen
        selectedPen = (selectedPen?.strokeStyle == .marker ? (selectedPen ?? tool.pens.last) : tool.pens.last)
        if let color = selectedPen?.rgba {
            pen.color = color
        }
        pen.isSelected = true
        pen.tool = tool.object
        pen.orderIndex = Int16(tool.pens.count)
        let _pen = Pen(object: pen)
        tool.addPen(_pen)
    }
}
