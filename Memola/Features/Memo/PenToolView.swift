//
//  PenToolView.swift
//  Memola
//
//  Created by Dscyre Scotti on 5/4/24.
//

import SwiftUI

struct PenToolView: View {
    @EnvironmentObject var tool: Tool

    var body: some View {
        VStack {
            if let pen = tool.selectedPen {
                let thicknessBounds = pen.style.thinkness
                let thickness = Binding {
                    max(pen.thickness, pen.style.thinkness.min)
                } set: { newValue in
                    tool.selectedPen?.thickness = newValue
                }
                let color = Binding {
                    Color.rgba(from: pen.color)
                } set: { newValue in
                    tool.selectedPen?.color = newValue.components
                    tool.objectWillChange.send()
                }
                HStack {
                    ColorPicker("", selection: color)
                        .frame(width: 40, height: 40)
                    Slider(value: thickness, in: thicknessBounds.min...thicknessBounds.max)
                        .frame(width: 180, height: 40)
                }
            }
            HStack {
                ForEach(tool.pens) { pen in
                    penView(pen)
                        .overlay(alignment: .bottom) {
                            if tool.selectedPen === pen {
                                Circle()
                                    .frame(width: 5, height: 5)
                                    .offset(y: 7.5)
                                    .foregroundStyle(Color.rgba(from: pen.color))
                            }
                        }
                }
            }
            .padding(15)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
    }

    @ViewBuilder
    func penView(_ pen: Pen) -> some View {
        Button {
            if tool.selectedPen === pen {
                tool.selectedPen = nil
            } else {
                tool.changePen(pen)
            }
        } label: {
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
            .frame(width: 30, height: 65)
            .drawingGroup()
            .hoverEffect(.lift)
        }
        .buttonStyle(.plain)
    }
}



