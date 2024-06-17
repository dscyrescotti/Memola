//
//  PhotoPreview.swift
//  Memola
//
//  Created by Dscyre Scotti on 6/15/24.
//

import SwiftUI

struct PhotoPreview: View {
    let photoItem: PhotoItem
    @ObservedObject var tool: Tool

    var body: some View {
        Image(uiImage: photoItem.image)
            .resizable()
            .scaledToFill()
            .frame(width: 100, height: 100)
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
                .hoverEffect(.lift)
                .offset(x: -12, y: -12)
            }
            .padding(10)
    }
}
