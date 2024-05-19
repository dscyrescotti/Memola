//
//  ColorPicker.swift
//  Memola
//
//  Created by Dscyre Scotti on 5/18/24.
//

import SwiftUI
import Foundation

struct ColorPicker: View {
    @State var hue: Double = 1
    @State var saturation: Double = 0
    @State var brightness: Double = 1
    @State var alpha: Double = 1

    @Binding var color: Color

    let size: CGFloat = 20

    var body: some View {
        VStack(spacing: 10) {
            colorPicker
                .frame(width: 200, height: 200)
            HStack(spacing: 10) {
                hueSlider
                alphaSlider
            }
        }
        .padding(10)
        .background {
            Rectangle()
                .fill(.regularMaterial)
                .ignoresSafeArea(.all)
        }
        .onAppear {
            let hsba = color.hsba
            hue = hsba.hue
            saturation = hsba.saturation
            brightness = hsba.brightness
            alpha = hsba.alpha * 1.43 - 0.43
        }
    }

    @ViewBuilder
    var colorPicker: some View {
        GeometryReader { proxy in
            ZStack {
                Color(hue: hue, saturation: 1, brightness: 1)
                LinearGradient(
                    colors: [.white, .clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                LinearGradient(
                    colors: [.black, .clear],
                    startPoint: .bottom,
                    endPoint: .top
                )
            }
            .cornerRadius(5)
            .drawingGroup()
            .overlay {
                RoundedRectangle(cornerRadius: 5)
                    .stroke(Color.gray, lineWidth: 0.2)
            }
            .overlay(alignment: .bottomLeading) {
                Color(hue: hue, saturation: saturation, brightness: brightness)
                    .frame(width: size, height: size)
                    .clipShape(Circle())
                    .padding(1)
                    .overlay {
                        Circle()
                            .strokeBorder(.white, lineWidth: 2)
                    }
                    .overlay {
                        Circle()
                            .stroke(Color.gray, lineWidth: 0.2)
                    }
                    .offset(x: -size + 5, y: size - 5)
                    .offset(x: max(proxy.size.width * saturation, size - 10), y: min(proxy.size.height * -brightness, -size + 10))
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        saturation = min(1, max(value.location.x / proxy.size.width, 0))
                        brightness = 1 - min(1, max(value.location.y / proxy.size.height, 0))
                        updateColor()
                    }
            )
        }
    }

    @ViewBuilder
    var hueSlider: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                LinearGradient(
                    colors: (0...10).map { Color(hue: Double($0) * 0.1, saturation: 1, brightness: 1) },
                    startPoint: .leading,
                    endPoint: .trailing
                )
                Color(hue: hue, saturation: 1, brightness: 1)
                    .frame(width: size, height: size)
                    .clipShape(Circle())
                    .padding(1)
                    .overlay {
                        Circle()
                            .strokeBorder(.white, lineWidth: 2)
                    }
                    .overlay {
                        Circle()
                            .stroke(Color.gray, lineWidth: 0.2)
                    }
                    .offset(x: -size)
                    .offset(x: max(size, proxy.size.width * hue - 2))
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        hue = min(1, max(value.location.x / proxy.size.width, 0))
                        updateColor()
                    }
                    .onEnded { value in
                        hue = min(1, max(value.location.x / proxy.size.width, 0))
                        updateColor()
                    }
            )
            .clipShape(Capsule())
            .overlay {
                Capsule()
                    .stroke(Color.gray, lineWidth: 0.2)
            }
            .frame(height: proxy.size.height)
        }
        .frame(height: size)
    }

    @ViewBuilder
    var alphaSlider: some View {
        GeometryReader { proxy in
            let color = Color(hue: hue, saturation: saturation, brightness: brightness)
            ZStack(alignment: .leading) {
                LinearGradient(
                    colors: (3...10).map { color.opacity(0.1 * CGFloat($0)) },
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .background {
                    Image("transparent-grid-rect")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .background(.white)
                }
                color
                    .frame(width: size, height: size)
                    .clipShape(Circle())
                    .padding(1)
                    .overlay {
                        Circle()
                            .strokeBorder(.white, lineWidth: 2)
                    }
                    .overlay {
                        Circle()
                            .stroke(Color.gray, lineWidth: 0.2)
                    }
                    .offset(x: -size)
                    .offset(x: max(size, proxy.size.width * alpha - 2))
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        alpha = min(1, max(value.location.x / proxy.size.width, 0))
                        updateColor()
                    }
                    .onEnded { value in
                        alpha = min(1, max(value.location.x / proxy.size.width, 0))
                        updateColor()
                    }
            )
            .clipShape(Capsule())
            .overlay {
                Capsule()
                    .stroke(Color.gray, lineWidth: 0.2)
            }
            .frame(height: proxy.size.height)
        }
        .frame(height: size)
    }

    func updateColor() {
        color = Color(hue: hue, saturation: saturation, brightness: brightness).opacity(0.7 * alpha + 0.3)
    }
}
