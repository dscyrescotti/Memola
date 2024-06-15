//
//  Toolbar.swift
//  Memola
//
//  Created by Dscyre Scotti on 5/19/24.
//

import SwiftUI
import PhotosUI
import Foundation
import AVFoundation

struct Toolbar: View {
    @Environment(\.dismiss) var dismiss

    @ObservedObject var tool: Tool
    @ObservedObject var canvas: Canvas
    @ObservedObject var history: History

    @State var title: String
    @State var memo: MemoObject
    @State var photoItem: PhotosPickerItem?
    @State var opensCamera: Bool = false
    @State var isCameraAccessDenied: Bool = false

    @FocusState var textFieldState: Bool

    let size: CGFloat

    init(size: CGFloat, memo: MemoObject, tool: Tool, canvas: Canvas, history: History) {
        self.size = size
        self.memo = memo
        self.tool = tool
        self.canvas = canvas
        self.history = history
        self.title = memo.title
    }
    
    var body: some View {
        HStack(spacing: 5) {
            HStack(spacing: 5) {
                if !canvas.locksCanvas {
                    closeButton
                    titleField
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            elementTool
            HStack(spacing: 5) {
                if !canvas.locksCanvas {
                    historyControl
                }
                lockButton
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .font(.subheadline)
        .padding(10)
        .onChange(of: photoItem) { oldValue, newValue in
            if newValue != nil {
                Task {
                    let data = try? await newValue?.loadTransferable(type: Data.self)
                    if let data {
                        withAnimation {
                            tool.selectedImage = UIImage(data: data)
                        }
                    }
                    photoItem = nil
                }
            }
        }
        .fullScreenCover(isPresented: $opensCamera) {
            CameraView(image: $tool.selectedImage)
                .ignoresSafeArea()
        }
        .alert("Camera Access Denied", isPresented: $isCameraAccessDenied) {
            Button {
                if let url = URL(string: UIApplication.openSettingsURLString + "&path=CAMERA/\(String(describing: Bundle.main.bundleIdentifier))") {
                    UIApplication.shared.open(url)
                }
            } label: {
                Text("Open Settings")
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Memola requires access to the camera to capture photos. Please open Settings and enable camera access.")
        }
    }

    var closeButton: some View {
        Button {
            closeMemo()
        } label: {
            Image(systemName: "xmark")
                .contentShape(.circle)
                .frame(width: size, height: size)
                .background(.regularMaterial)
                .clipShape(.rect(cornerRadius: 8))
        }
        .hoverEffect(.lift)
        .disabled(textFieldState)
        .transition(.move(edge: .top).combined(with: .blurReplace))
    }

    var titleField: some View {
        TextField("", text: $title)
            .focused($textFieldState)
            .textFieldStyle(.plain)
            .padding(.horizontal, size / 2.5)
            .frame(width: 140, height: size)
            .background(.regularMaterial)
            .clipShape(.rect(cornerRadius: 8))
            .onChange(of: textFieldState) { oldValue, newValue in
                if !newValue {
                    if !title.isEmpty {
                        memo.title = title
                    } else {
                        title = memo.title
                    }
                    withPersistence(\.viewContext) { context in
                        try context.saveIfNeeded()
                    }
                }
            }
            .transition(.move(edge: .top).combined(with: .blurReplace))
    }

    var elementTool: some View {
        HStack(spacing: 0) {
            Button {
                withAnimation {
                    tool.selection = tool.selection == .pen ? .none : .pen
                }
            } label: {
                Image(systemName: "pencil")
                    .fontWeight(.heavy)
                    .contentShape(.circle)
                    .frame(width: size, height: size)
                    .background(tool.selection == .pen ? Color.accentColor : Color.clear)
                    .foregroundStyle(tool.selection == .pen ? Color.white : Color.accentColor)
                    .clipShape(.rect(cornerRadius: 8))
            }
            .hoverEffect(.lift)
            HStack(spacing: 0) {
                Button {
                    withAnimation {
                        tool.selection = tool.selection == .photo ? .none : .photo
                    }
                } label: {
                    Image(systemName: "photo")
                        .contentShape(.circle)
                        .frame(width: size, height: size)
                        .background(tool.selection == .photo ? Color.accentColor : Color.clear)
                        .foregroundStyle(tool.selection == .photo ? Color.white : Color.accentColor)
                        .clipShape(.rect(cornerRadius: 8))
                }
                .hoverEffect(.lift)
                if tool.selection == .photo {
                    HStack(spacing: 0) {
                        Button {
                            openCamera()
                        } label: {
                            Image(systemName: "camera.fill")
                                .contentShape(.circle)
                                .frame(width: size, height: size)
                                .clipShape(.rect(cornerRadius: 8))
                        }
                        .hoverEffect(.lift)
                        PhotosPicker(selection: $photoItem, matching: .images) {
                            Image(systemName: "photo.fill.on.rectangle.fill")
                                .contentShape(.circle)
                                .frame(width: size, height: size)
                                .clipShape(.rect(cornerRadius: 8))
                        }
                        .hoverEffect(.lift)
                    }
                }
            }
            .background {
                if tool.selection == .photo {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.tertiary)
                }
            }
        }
        .background {
            RoundedRectangle(cornerRadius: 8)
                .fill(.regularMaterial)
        }
    }

    var historyControl: some View {
        HStack {
            Button {
                history.historyPublisher.send(.undo)
            } label: {
                Image(systemName: "arrow.uturn.backward.circle")
                    .contentShape(.circle)
            }
            .hoverEffect(.lift)
            .disabled(history.undoDisabled)
            Button {
                history.historyPublisher.send(.redo)
            } label: {
                Image(systemName: "arrow.uturn.forward.circle")
                    .contentShape(.circle)
            }
            .hoverEffect(.lift)
            .disabled(history.redoDisabled)
        }
        .frame(width: size * 2, height: size)
        .background(.regularMaterial)
        .clipShape(.rect(cornerRadius: 8))
        .disabled(textFieldState)
        .transition(.move(edge: .top).combined(with: .blurReplace))
    }

    var lockButton: some View {
        Button {
            #warning("TODO: need to revisit toggale logic")
            withAnimation {
                canvas.locksCanvas.toggle()
            }
        } label: {
            ZStack {
                if canvas.locksCanvas {
                    Image(systemName: "lock.open")
                        .transition(.move(edge: .trailing).combined(with: .blurReplace))
                } else {
                    Image(systemName: "lock")
                        .transition(.move(edge: .leading).combined(with: .blurReplace))
                }
            }
            .contentShape(.circle)
            .frame(width: size, height: size)
            .background(.regularMaterial)
            .clipShape(.rect(cornerRadius: 8))
        }
        .hoverEffect(.lift)
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

    func closeMemo() {
        withAnimation {
            canvas.state = .closing
        }
        withPersistence(\.backgroundContext) { context in
            try? context.saveIfNeeded()
            context.refreshAllObjects()
            DispatchQueue.main.async {
                withAnimation {
                    canvas.state = .closed
                }
                dismiss()
            }
        }
    }
}
