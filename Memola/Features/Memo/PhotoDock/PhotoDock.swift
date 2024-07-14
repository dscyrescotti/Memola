//
//  PhotoDock.swift
//  Memola
//
//  Created by Dscyre Scotti on 7/11/24.
//

import SwiftUI
import PhotosUI

struct PhotoDock: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private let size: CGFloat = 40

    @ObservedObject private var tool: Tool
    @ObservedObject private var canvas: Canvas

    @State private var opensCamera: Bool = false
    @State private var isCameraAccessDenied: Bool = false
    @State private var photosPickerItem: PhotosPickerItem?

    init(tool: Tool, canvas: Canvas) {
        self.tool = tool
        self.canvas = canvas
    }

    var body: some View {
        Group {
            #if os(macOS)
            photoOption
            #else
            if horizontalSizeClass == .regular {
                photoOption
            } else {
                compactPhotoOption
            }
            #endif
        }
        .foregroundStyle(Color.accentColor)
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

    private var photoOption: some View {
        VStack(spacing: 0) {
            #if os(iOS)
            Button {
                openCamera()
            } label: {
                Image(systemName: "camera.fill")
                    .frame(width: size, height: size)
                    .clipShape(.rect(cornerRadius: 8))
                    .contentShape(.rect(cornerRadius: 8))
            }
            .hoverEffect(.lift)
            #endif
            PhotosPicker(selection: $photosPickerItem, matching: .images, preferredItemEncoding: .compatible) {
                Image(systemName: "photo.fill.on.rectangle.fill")
                    .frame(width: size, height: size)
                    .clipShape(.rect(cornerRadius: 8))
                    .contentShape(.rect(cornerRadius: 8))
            }
            #if os(iOS)
            .hoverEffect(.lift)
            #else
            .buttonStyle(.plain)
            #endif
            if horizontalSizeClass == .compact {
                Divider()
                    .padding(.vertical, 4)
                    .frame(height: size)
                    .foregroundStyle(Color.accentColor)
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
        .background {
            RoundedRectangle(cornerRadius: 8)
                .fill(.regularMaterial)
        }
        .padding(.trailing, 10)
        .frame(maxHeight: .infinity)
        .transition(.move(edge: .trailing).combined(with: .blurReplace))
    }

    private var compactPhotoOption: some View {
        HStack(spacing: 0) {
            #if os(iOS)
            Button {
                openCamera()
            } label: {
                Image(systemName: "camera.fill")
                    .frame(width: size, height: size)
                    .clipShape(.rect(cornerRadius: 8))
                    .contentShape(.rect(cornerRadius: 8))
            }
            .hoverEffect(.lift)
            #endif
            PhotosPicker(selection: $photosPickerItem, matching: .images, preferredItemEncoding: .compatible) {
                Image(systemName: "photo.fill.on.rectangle.fill")
                    .frame(width: size, height: size)
                    .clipShape(.rect(cornerRadius: 8))
                    .contentShape(.rect(cornerRadius: 8))
            }
            #if os(iOS)
            .hoverEffect(.lift)
            #else
            .buttonStyle(.plain)
            #endif
            if horizontalSizeClass == .compact {
                Divider()
                    .padding(.vertical, 4)
                    .frame(height: size)
                    .foregroundStyle(Color.accentColor)
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
        .background {
            RoundedRectangle(cornerRadius: 8)
                .fill(.regularMaterial)
        }
        .padding(.bottom, 10)
        .frame(maxWidth: .infinity)
        .transition(.move(edge: .bottom).combined(with: .blurReplace))
    }

    private func openCamera() {
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
