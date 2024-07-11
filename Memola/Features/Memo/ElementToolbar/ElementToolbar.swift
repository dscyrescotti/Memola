//
//  ElementToolbar.swift
//  Memola
//
//  Created by Dscyre Scotti on 6/30/24.
//

import SwiftUI
import PhotosUI
import AVFoundation

struct ElementToolbar: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    let size: CGFloat = 40
    @ObservedObject var tool: Tool
    @ObservedObject var canvas: Canvas

    var body: some View {
        Group {
            #if os(macOS)
            regularToolbar
            #else
            if horizontalSizeClass == .regular {
                regularToolbar
            } else {
                ZStack(alignment: .bottom) {
                    if tool.selection == .photo {
                        PhotoDock(tool: tool, canvas: canvas)
                    } else {
                        compactToolbar
                    }
                }
            }
            #endif
        }
        
    }

    var regularToolbar: some View {
        HStack(spacing: 0) {
            Button {
                withAnimation {
                    tool.selectTool(.hand)
                }
            } label: {
                Image(systemName: "hand.draw.fill")
                    .fontWeight(.heavy)
                    .contentShape(.circle)
                    .frame(width: size, height: size)
                    .foregroundStyle(tool.selection == .hand ? colorScheme == .light ? Color.white : Color.black : Color.accentColor)
                    .clipShape(.rect(cornerRadius: 8))
                    .contentShape(.rect(cornerRadius: 8))
            }
            #if os(iOS)
            .hoverEffect(.lift)
            #else
            .buttonStyle(.plain)
            #endif
            .background {
                if tool.selection == .hand {
                    Color.accentColor
                        .clipShape(.rect(cornerRadius: 8))
                }
            }
            Button {
                withAnimation {
                    tool.selectTool(.pen)
                }
            } label: {
                Image(systemName: "pencil")
                    .fontWeight(.heavy)
                    .contentShape(.circle)
                    .frame(width: size, height: size)
                    .foregroundStyle(tool.selection == .pen ? colorScheme == .light ? Color.white : Color.black : Color.accentColor)
                    .clipShape(.rect(cornerRadius: 8))
                    .contentShape(.rect(cornerRadius: 8))
            }
            #if os(iOS)
            .hoverEffect(.lift)
            #else
            .buttonStyle(.plain)
            #endif
            .background {
                if tool.selection == .pen {
                    Color.accentColor
                        .clipShape(.rect(cornerRadius: 8))
                }
            }
            HStack(spacing: 0) {
                Button {
                    withAnimation {
                        tool.selectTool(.photo)
                    }
                } label: {
                    Image(systemName: "photo")
                        .contentShape(.circle)
                        .frame(width: size, height: size)
                        .foregroundStyle(tool.selection == .photo ? colorScheme == .light ? Color.white : Color.black : Color.accentColor)
                        .clipShape(.rect(cornerRadius: 8))
                        .contentShape(.rect(cornerRadius: 8))
                }
                #if os(iOS)
                .hoverEffect(.lift)
                #else
                .buttonStyle(.plain)
                #endif
                .background {
                    if tool.selection == .photo {
                        Color.accentColor
                            .clipShape(.rect(cornerRadius: 8))
                    }
                }
            }
        }
        .background {
            RoundedRectangle(cornerRadius: 8)
                .fill(.regularMaterial)
        }
        .transition(.move(edge: .top).combined(with: .blurReplace))
    }

    var compactToolbar: some View {
        HStack(spacing: 0) {
            Button {
                withAnimation {
                    tool.selectTool(.pen)
                }
            } label: {
                Image(systemName: "pencil")
                    .fontWeight(.heavy)
                    .contentShape(.circle)
                    .frame(width: size, height: size)
                    .clipShape(.rect(cornerRadius: 8))
            }
            #if os(iOS)
            .hoverEffect(.lift)
            #endif
            Button {
                withAnimation {
                    tool.selectTool(.photo)
                }
            } label: {
                Image(systemName: "photo")
                    .contentShape(.circle)
                    .frame(width: size, height: size)
                    .clipShape(.rect(cornerRadius: 8))
            }
            #if os(iOS)
            .hoverEffect(.lift)
            #endif
        }
        .background {
            RoundedRectangle(cornerRadius: 8)
                .fill(.regularMaterial)
        }
        .padding(10)
        .frame(maxWidth: .infinity)
        .transition(.move(edge: .bottom).combined(with: .blurReplace))
    }

    
}
