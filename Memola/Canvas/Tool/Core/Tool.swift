//
//  Tool.swift
//  Memola
//
//  Created by Dscyre Scotti on 5/4/24.
//

import Combine
import SwiftUI
import CoreData
import Foundation

final class Tool: NSObject, ObservableObject {
    let object: ToolObject

    @Published var pens: [Pen] = []

    // MARK: - Pen
    @Published var selectedPen: Pen?
    @Published var draggedPen: Pen?
    // MARK: - Photo
    @Published var selectedPhotoFile: PhotoFileObject?
    @Published var isLoadingPhoto: Bool = false

    @Published var selection: ToolSelection = .hand

    let scrollPublisher = PassthroughSubject<String, Never>()
    var markers: [Pen] {
        pens.filter { $0.strokeStyle == .marker }
    }

    init(object: ToolObject) {
        self.object = object
        selection = ToolSelection(rawValue: object.selection) ?? .hand
    }

    func selectTool(_ selection: ToolSelection) {
        guard self.selection != selection else { return }
        self.selection = selection
        withPersistence(\.viewContext) { [weak object] context in
            object?.selection = selection.rawValue
            object?.memo?.updatedAt = .now
            try context.saveIfNeeded()
        }
    }

    func load() {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            pens = object.pens.sortedArray(using: [NSSortDescriptor(key: "orderIndex", ascending: true)]).compactMap {
                guard let pen = $0 as? PenObject else { return nil }
                return Pen(object: pen)
            }
            if let selectedPen = pens.first(where: { $0.isSelected }) {
                selectPen(selectedPen)
                scrollPublisher.send(selectedPen.id)
            }
        }
    }

    func selectPen(_ pen: Pen) {
        if let selectedPen {
            unselectPen(selectedPen)
        }
        withAnimation {
            selectedPen = pen
        }
        selectedPen?.isSelected = true
        withPersistence(\.viewContext) { context in
            try context.saveIfNeeded()
        }
    }

    func unselectPen(_ pen: Pen) {
        pen.isSelected = false
        withAnimation {
            selectedPen = nil
        }
        withPersistence(\.viewContext) { context in
            try context.saveIfNeeded()
        }
    }

    func duplicatePen(_ pen: Pen, of originalPen: Pen) {
        guard let index = pens.firstIndex(where: { originalPen === $0 }) else { return }
        withAnimation {
            pens.insert(pen, at: index + 1)
        }
        selectPen(pen)
        withPersistence(\.viewContext) { [pens, weak object] context in
            for (index, pen) in pens.enumerated() {
                pen.object?.orderIndex = Int16(index)
            }
            object?.memo?.updatedAt = .now
            try context.saveIfNeeded()
        }
    }

    func addPen(_ pen: Pen) {
        withAnimation {
            pens.append(pen)
        }
        selectPen(pen)
        if let _pen = pen.object {
            object.pens.add(_pen)
        }
        scrollPublisher.send(pen.id)
        withPersistence(\.viewContext) { [weak object] context in
            object?.memo?.updatedAt = .now
            try context.saveIfNeeded()
        }
    }

    func removePen(_ pen: Pen) {
        guard let index = pens.firstIndex(where: { $0 === pen }) else { return }
        let deletedPen = withAnimation {
            pens.remove(at: index)
        }
        unselectPen(deletedPen)
        if let _pen = deletedPen.object {
            _pen.tool = nil
            object.pens.remove(_pen)
            withPersistence(\.viewContext) { [weak object] context in
                context.delete(_pen)
                object?.memo?.updatedAt = .now
                try context.saveIfNeeded()
            }
        }
    }

    func createFile(_ image: Platform.Image, with canvas: CanvasObject) {
        guard let (resizedImage, dimension) = resizePhoto(of: image) else { return }
        guard let photoItem = bookmarkPhoto(of: resizedImage, and: image, in: dimension, with: canvas.objectID) else { return }
        let _dimension = photoItem.dimension
        let graphicContext = canvas.graphicContext
        withPersistence(\.viewContext) { [weak graphicContext = graphicContext] context in
            let file = PhotoFileObject(\.viewContext)
            file.imageURL = photoItem.id
            file.bookmark = photoItem.bookmark
            file.dimension = [_dimension.width, _dimension.height]
            file.createdAt = .now
            file.photos = []
            file.graphicContext = graphicContext
            graphicContext?.files.add(file)
            try context.saveIfNeeded()
        }
    }

    func selectPhoto(_ photoFile: PhotoFileObject) {
        selectedPhotoFile = photoFile
    }

    func unselectPhoto() {
        selectedPhotoFile = nil
    }

    private func resizePhoto(of image: Platform.Image) -> (Platform.Image, CGSize)? {
        let targetSize = CGSize(width: 512, height: 512)
        let size = image.size
        let widthRatio = targetSize.width / size.width
        let heightRatio = targetSize.height / size.height
        let dimension = CGSize(
            width: size.width * min(widthRatio, heightRatio),
            height: size.height * min(widthRatio, heightRatio)
        )
        let rect = CGRect(origin: .zero, size: targetSize)

        #if os(macOS)
        let newImage = NSImage(size: rect.size, flipped: false) { destRect in
            NSGraphicsContext.current?.imageInterpolation = .high
            image.draw(in: destRect, from: NSZeroRect, operation: .copy, fraction: 1)
            return true
        }
        return (newImage, dimension)
        #else
        UIGraphicsBeginImageContextWithOptions(targetSize, true, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        guard let newImage else { return nil }

        return (newImage, dimension)
        #endif
    }

    private func bookmarkPhoto(of image: Platform.Image, and previewImage: Platform.Image, in dimension: CGSize, with canvasID: NSManagedObjectID) -> PhotoItem? {
        #if os(macOS)
        guard let data = image.tiffRepresentation else { return nil }
        #else
        guard let data = image.jpegData(compressionQuality: 1) else { return nil }
        #endif
        let fileManager = FileManager.default
        guard let directory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        let fileName = "\(UUID().uuidString)-\(Int(Date.now.timeIntervalSince1970))"
        let folder = directory.appendingPathComponent(canvasID.uriRepresentation().lastPathComponent, conformingTo: .folder)

        if !fileManager.fileExists(atPath: folder.path()) {
            do {
                try fileManager.createDirectory(at: folder, withIntermediateDirectories: true)
            } catch {
                NSLog("[Memola] - \(error.localizedDescription)")
                return nil
            }
        }
        let file = folder.appendingPathComponent(fileName, conformingTo: .jpeg)
        do {
            try data.write(to: file)
        } catch {
            NSLog("[Memola] - \(error.localizedDescription)")
            return nil
        }
        var photoBookmark: PhotoItem?
        do {
            let bookmark = try file.bookmarkData(options: .minimalBookmark)
            photoBookmark = PhotoItem(id: file, image: image, dimension: dimension, bookmark: bookmark)
        } catch {
            NSLog("[Memola] - \(error.localizedDescription)")
        }
        return photoBookmark
    }
}
