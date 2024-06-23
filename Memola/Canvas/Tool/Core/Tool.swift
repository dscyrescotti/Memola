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

public class Tool: NSObject, ObservableObject {
    let object: ToolObject

    @Published var pens: [Pen] = []

    // MARK: - Pen
    @Published var selectedPen: Pen?
    @Published var draggedPen: Pen?
    // MARK: - Photo
    @Published var selectedPhotoItem: PhotoItem?

    @Published var selection: ToolSelection = .none

    let scrollPublisher = PassthroughSubject<String, Never>()
    var markers: [Pen] {
        pens.filter { $0.strokeStyle == .marker }
    }

    init(object: ToolObject) {
        self.object = object
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
        withPersistence(\.viewContext) { [pens] context in
            for (index, pen) in pens.enumerated() {
                pen.object?.orderIndex = Int16(index)
            }
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
        withPersistence(\.viewContext) { context in
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
            withPersistence(\.viewContext) { context in
                context.delete(_pen)
                try context.saveIfNeeded()
            }
        }
    }

    func selectPhoto(_ image: UIImage, for canvasID: NSManagedObjectID) {
        guard let (resizedImage, dimension) = resizePhoto(of: image) else { return }
        let photoItem = bookmarkPhoto(of: resizedImage, in: dimension, with: canvasID)
        withAnimation {
            selectedPhotoItem = photoItem
        }
    }

    private func resizePhoto(of image: UIImage) -> (UIImage, CGSize)? {
        let targetSize = CGSize(width: 512, height: 512)
        let size = image.size
        let widthRatio = targetSize.width / size.width
        let heightRatio = targetSize.height / size.height
        let dimension = CGSize(
            width: size.width * min(widthRatio, heightRatio),
            height: size.height * min(widthRatio, heightRatio)
        )
        let rect = CGRect(origin: .zero, size: targetSize)

        UIGraphicsBeginImageContextWithOptions(targetSize, true, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        guard let newImage else { return nil }

        return (newImage, dimension)
    }

    private func bookmarkPhoto(of image: UIImage, in dimension: CGSize, with canvasID: NSManagedObjectID) -> PhotoItem? {
        guard let data = image.jpegData(compressionQuality: 1) else { return nil }
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

    func unselectPhoto() {
        guard let photoItem = selectedPhotoItem else { return }
        let fileManager = FileManager.default
        if let url = photoItem.bookmark.getBookmarkURL() {
            do {
                try fileManager.removeItem(at: url)
            } catch {
                NSLog("[Memola] - \(error.localizedDescription)")
            }
        }
        withAnimation {
            selectedPhotoItem = nil
        }
    }
}
