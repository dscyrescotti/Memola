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

    @FetchRequest private var fileObjects: FetchedResults<PhotoFileObject>

    private let memo: MemoObject
    private let size: CGFloat = 40

    @ObservedObject private var tool: Tool
    @ObservedObject private var canvas: Canvas

    @State private var opensCamera: Bool = false
    @State private var isCameraAccessDenied: Bool = false
    @State private var photosPickerItems: [PhotosPickerItem] = []

    init(memo: MemoObject, tool: Tool, canvas: Canvas) {
        self.memo = memo
        self.tool = tool
        self.canvas = canvas

        let predicate: NSPredicate = NSPredicate(format: "graphicContext = %@", memo.canvas.graphicContext)
        let descriptors: [SortDescriptor<PhotoFileObject>] = [SortDescriptor(\.createdAt)]
        self._fileObjects = FetchRequest(sortDescriptors: descriptors, predicate: predicate)
    }

    var body: some View {
        Group {
            #if os(macOS)
            GeometryReader { proxy in
                VStack(alignment: .trailing, spacing: 5) {
                    photoOption
                    photoItemGrid
                        .frame(minHeight: proxy.size.height * 0.2, maxHeight: proxy.size.height * 0.4)
                }
                .fixedSize()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
            }
            .padding(10)
            .transition(.move(edge: .trailing).combined(with: .blurReplace))
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
                tool.selectedPhotoFile?.image
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
        .onChange(of: photosPickerItems) { oldValue, newValue in
            if !newValue.isEmpty {
                Task {
                    tool.isLoadingPhoto = true
                    for photoItem in newValue {
                        await createFile(for: photoItem)
                    }
                    photosPickerItems = []
                    tool.isLoadingPhoto = false
                }
            }
        }
    }

    private var photoOption: some View {
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
            PhotosPicker(selection: $photosPickerItems, matching: .images, preferredItemEncoding: .compatible) {
                Image(systemName: "photo.fill.on.rectangle.fill")
                    #if os(macOS)
                    .frame(width: size * 2, height: size)
                    #else
                    .frame(width: size, height: size)
                    #endif
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
            PhotosPicker(selection: $photosPickerItems, matching: .images, preferredItemEncoding: .compatible) {
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

    @ViewBuilder
    private var photoItemGrid: some View {
        let padding: CGFloat = 5
        let size = (self.size * 2 - (5 + padding * 2)) / 2
        let columns: [GridItem] = .init(repeating: GridItem(.flexible(), spacing: 5), count: 2)
        ScrollView {
            LazyVGrid(columns: columns, spacing: 5) {
                ForEach(fileObjects) { file in
                    Group {
                        let previewSize = file.previewSize(size)
                        if let previewImage = file.previewImage {
                            Image(image: previewImage)
                                .resizable()
                                .frame(width: previewSize.width, height: previewSize.height)
                                .onTapGesture {
                                    if tool.selectedPhotoFile == file {
                                        tool.unselectPhoto()
                                    } else {
                                        tool.selectPhoto(file)
                                    }
                                }
                        } else {
                            Color.gray.opacity(0.5)
                        }
                    }
                    .frame(width: size, height: size)
                    .clipShape(RoundedRectangle(cornerRadius: 5))
                    .overlay {
                        if tool.selectedPhotoFile == file {
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(Color.accentColor, lineWidth: 2.5)
                        }
                    }
                }
            }
            .padding(padding)
        }
        .background {
            RoundedRectangle(cornerRadius: 8)
                .fill(.regularMaterial)
        }
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

    private func createFile(for photoItem: PhotosPickerItem) async {
        let data = try? await photoItem.loadTransferable(type: Data.self)
        if let data, let image = Platform.Image(data: data) {
            tool.createFile(image, with: memo.canvas)
        }
    }
}
