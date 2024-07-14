//
//  PhotoPreview.swift
//  Memola
//
//  Created by Dscyre Scotti on 6/15/24.
//

import SwiftUI

struct PhotoPreview: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private let photoItem: PhotoItem
    @ObservedObject private var tool: Tool

    init(photoItem: PhotoItem, tool: Tool) {
        self.photoItem = photoItem
        self.tool = tool
    }

    var body: some View {
        Image(image: photoItem.previewImage)
            .resizable()
            .scaledToFit()
            .frame(width: horizontalSizeClass == .compact ? 80 : nil, height: horizontalSizeClass == .compact ? nil : 100)
            .cornerRadius(5)
            .overlay {
                RoundedRectangle(cornerRadius: 5)
                    .stroke(Color.gray, lineWidth: 0.2)
            }
            .padding(10)
            .background(.regularMaterial)
            .cornerRadius(5)
            .overlay(alignment: .topLeading) {
                Button {
                    tool.unselectPhoto()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .padding(1)
                        .contentShape(.circle)
                        .background {
                            Circle()
                                .fill(.white)
                        }
                }
                .foregroundStyle(.red)
                #if os(iOS)
                .hoverEffect(.lift)
                #endif
                .offset(x: -12, y: -12)
            }
            .padding(10)
    }
}
