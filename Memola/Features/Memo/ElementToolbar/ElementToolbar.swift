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
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    let size: CGFloat
    @ObservedObject var tool: Tool
    @ObservedObject var canvas: Canvas

    @State var opensCamera: Bool = false
    @State var isCameraAccessDenied: Bool = false
    @State var photosPickerItem: PhotosPickerItem?

    @Namespace var namespace

    var body: some View {
        Group {
            if horizontalSizeClass == .regular {
                regularToolbar
            } else {
                ZStack(alignment: .bottom) {
                    if tool.selection == .photo {
                        photoOption
                            .background {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(.regularMaterial)
                            }
                            .padding(.bottom, 10)
                            .frame(maxWidth: .infinity)
                            .transition(.move(edge: .bottom).combined(with: .blurReplace))
                    } else {
                        compactToolbar
                    }
                }
                .padding(.bottom, 10)
            }
        }
        #if os(iOS)
        .fullScreenCover(isPresented: $opensCamera) {
            let image: Binding<UIImage?> = Binding {
                tool.selectedPhotoItem?.image
            } set: { image in
                guard let image else { return }
                tool.selectPhoto(image, for: canvas.canvasID)
            }
            CameraView(image: image, canvas: canvas)
                .ignoresSafeArea()
        }
        .alert("Camera Access Denied", isPresented: $isCameraAccessDenied) {
            Button {
                if let url = URL(string: Platform.Application.openSettingsURLString + "&path=CAMERA/\(String(describing: Bundle.main.bundleIdentifier))") {
                    Platform.Application.shared.open(url)
                }
            } label: {
                Text("Open Settings")
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Memola requires access to the camera to capture photos. Please open Settings and enable camera access.")
        }
        #endif
        .onChange(of: photosPickerItem) { oldValue, newValue in
            if newValue != nil {
                Task {
                    tool.isLoadingPhoto = true
                    let data = try? await newValue?.loadTransferable(type: Data.self)
                    if let data, let image = Platform.Image(data: data) {
                        tool.selectPhoto(image, for: canvas.canvasID)
                    }
                    photosPickerItem = nil
                }
            }
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
                    .foregroundStyle(tool.selection == .hand ? Color.white : Color.accentColor)
                    .clipShape(.rect(cornerRadius: 8))
            }
            #if os(iOS)
            .hoverEffect(.lift)
            #endif
            .background {
                if tool.selection == .hand {
                    Color.accentColor
                        .clipShape(.rect(cornerRadius: 8))
                        .matchedGeometryEffect(id: "element.toolbar.bg", in: namespace)
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
                    .foregroundStyle(tool.selection == .pen ? Color.white : Color.accentColor)
                    .clipShape(.rect(cornerRadius: 8))
            }
            #if os(iOS)
            .hoverEffect(.lift)
            #endif
            .background {
                if tool.selection == .pen {
                    Color.accentColor
                        .clipShape(.rect(cornerRadius: 8))
                        .matchedGeometryEffect(id: "element.toolbar.bg", in: namespace)
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
                        .foregroundStyle(tool.selection == .photo ? Color.white : Color.accentColor)
                        .clipShape(.rect(cornerRadius: 8))
                }
                #if os(iOS)
                .hoverEffect(.lift)
                #endif
                .background {
                    if tool.selection == .photo {
                        Color.accentColor
                            .clipShape(.rect(cornerRadius: 8))
                            .matchedGeometryEffect(id: "element.toolbar.bg", in: namespace)
                    }
                    if tool.selection != .photo {
                        Color.clear
                            .matchedGeometryEffect(id: "element.toolbar.photo.options", in: namespace)
                    }
                }
                if tool.selection == .photo {
                    photoOption
                        .matchedGeometryEffect(id: "element.toolbar.photo.options", in: namespace)
                        .transition(.blurReplace.animation(.easeIn(duration: 0.1)))
                }
            }
            .background {
                if tool.selection == .photo {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.tertiary)
                        .transition(.move(edge: .leading).combined(with: .opacity).animation(.easeIn(duration: 0.1)))
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

    var photoOption: some View {
        HStack(spacing: 0) {
            Button {
                openCamera()
            } label: {
                Image(systemName: "camera.fill")
                    .contentShape(.circle)
                    .frame(width: size, height: size)
                    .clipShape(.rect(cornerRadius: 8))
            }
            #if os(iOS)
            .hoverEffect(.lift)
            #endif
            PhotosPicker(selection: $photosPickerItem, matching: .images, preferredItemEncoding: .compatible) {
                Image(systemName: "photo.fill.on.rectangle.fill")
                    .contentShape(.circle)
                    .frame(width: size, height: size)
                    .clipShape(.rect(cornerRadius: 8))
            }
            #if os(iOS)
            .hoverEffect(.lift)
            #endif
        }
    }

    func openCamera() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { status in
                withAnimation {
                    if status {
                        opensCamera = true
                    } else {
                        isCameraAccessDenied = true
                    }
                }
            }
        case .authorized:
            opensCamera = true
        default:
            isCameraAccessDenied = true
        }
    }
}
