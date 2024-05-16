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
                LazyVStack(spacing: 0) {
                    ForEach(tool.pens) { pen in
                        penView(pen)
                    }
                }
                .padding(.vertical, 5)
                .padding(.leading, 40)
            }
            VStack(spacing: 0) {
                Divider()
                newPenButton
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
        .clipShape(.rect(cornerRadii: .init(topLeading: 10, bottomLeading: 10)))
        .contentShape(.rect(cornerRadii: .init(topLeading: 10, bottomLeading: 10)))
        .onDrag(if: pen.strokeStyle != .eraser) {
            tool.draggedPen = pen
            return NSItemProvider(contentsOf: URL(string: pen.id)) ?? NSItemProvider()
        } preview: {
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
            .padding([.vertical, .leading], 10)
            .contentShape(.dragPreview, .rect(cornerRadius: 10))
        }
        .onDrop(of: [.item], delegate: PenDropDelegate(id: pen.id, tool: tool))
        .onTapGesture {
            if tool.selectedPen === pen {
                withAnimation {
                    tool.selectedPen = nil
                }
            } else {
                withAnimation {
                    tool.changePen(pen)
                }
            }
        }
        .offset(x: tool.selectedPen === pen ? 0 : 28)
    }

    var newPenButton: some View {
        Button(action: {
            let pen = Pen(for: .marker)
            pen.color = [Color.red, Color.blue, Color.green, Color.black, Color.orange].randomElement()!.components
            tool.addPen(pen)
        }) {
            Image(systemName: "plus")
                .font(.title3)
                .contentShape(.circle)
        }
        .hoverEffect(.lift)
        .padding(10)
    }
}
