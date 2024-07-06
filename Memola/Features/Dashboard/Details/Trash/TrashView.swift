//
//  TrashView.swift
//  Memola
//
//  Created by Dscyre Scotti on 6/29/24.
//

import SwiftUI

struct TrashView: View {
    #if os(macOS)
    @Environment(\.openWindow) var openWindow
    #endif
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    @FetchRequest var memoObjects: FetchedResults<MemoObject>

    @State var query: String = ""
    @State var restoredMemo: MemoObject?
    @State var deletedMemo: MemoObject?

    #if os(iOS)
    @Binding var memo: MemoObject?
    #endif
    @Binding var sidebarItem: SidebarItem?

    var placeholder: Placeholder.Info {
        query.isEmpty ? .trashEmpty : .trashNotFound
    }

    #if os(macOS)
    init(sidebarItem: Binding<SidebarItem?>) {
        _sidebarItem = sidebarItem
        let descriptors = [SortDescriptor(\MemoObject.deletedAt, order: .reverse)]
        let predicate = NSPredicate(format: "isTrash = YES")
        _memoObjects = FetchRequest(sortDescriptors: descriptors, predicate: predicate)
    }
    #else
    init(memo: Binding<MemoObject?>, sidebarItem: Binding<SidebarItem?>) {
        _memo = memo
        _sidebarItem = sidebarItem
        let descriptors = [SortDescriptor(\MemoObject.deletedAt, order: .reverse)]
        let predicate = NSPredicate(format: "isTrash = YES")
        _memoObjects = FetchRequest(sortDescriptors: descriptors, predicate: predicate)
    }
    #endif

    var body: some View {
        let restoresMemo = Binding<Bool> {
            restoredMemo != nil
        } set: { _ in
            restoredMemo = nil
        }
        let deletesMemo = Binding<Bool> {
            deletedMemo != nil
        } set: { _ in
            deletedMemo = nil
        }
        MemoGrid(memoObjects: memoObjects, placeholder: placeholder) { memoObject, cellWidth in
            memoCard(memoObject, cellWidth)
        }
        .navigationTitle(horizontalSizeClass == .compact ? "Trash" : "")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .searchable(text: $query, placement: .toolbar, prompt: Text("Search"))
        .toolbar {
            #if os(macOS)
            ToolbarItem(placement: .navigation) {
                Text("Memola")
                    .font(.title3)
                    .fontWeight(.bold)
            }
            #else
            if horizontalSizeClass == .regular {
                ToolbarItem(placement: .topBarLeading) {
                    Text("Memola")
                        .font(.title3)
                        .fontWeight(.bold)
                }
            }
            #endif
        }
        .onChange(of: query) { oldValue, newValue in
            updatePredicate()
        }
        .alert("Restore Memo", isPresented: restoresMemo) {
            Button {
                restoreMemo(for: restoredMemo)
            } label: {
                Text("Restore")
            }
            Button {
                restoreAndOpenMemo(for: restoredMemo)
            } label: {
                Text("Restore and Open")
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Would you like to restore this memo or restore and open it?")
        }
        .alert("Delete Memo Permanently", isPresented: deletesMemo) {
            Button(role: .destructive) {
                deleteMemo(for: deletedMemo)
            } label: {
                Text("Delete")
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to permanently delete this memo? This action cannot be undone.")
        }
    }

    func memoCard(_ memoObject: MemoObject, _ cellWidth: CGFloat) -> some View {
        MemoCard(memoObject: memoObject, cellWidth: cellWidth) { card in
            card
                .contextMenu {
                    Button {
                        restoreMemo(for: memoObject)
                    } label: {
                        Label("Restore", systemImage: "square.and.arrow.down")
                            .labelStyle(.titleAndIcon)
                    }
                    Button(role: .destructive) {
                        deletedMemo = memoObject
                    } label: {
                        Label("Delete Permanently", systemImage: "trash")
                            .labelStyle(.titleAndIcon)
                    }
                }
        } details: {
            if let deletedAt = memoObject.deletedAt {
                Text("Deleted on \(deletedAt.formatted(date: .abbreviated, time: .standard))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .onTapGesture {
            restoredMemo = memoObject
        }
    }

    func updatePredicate() {
        var predicates: [NSPredicate] = [NSPredicate(format: "isTrash = YES")]
        if !query.isEmpty {
            predicates.append(NSPredicate(format: "title contains[c] %@", query))
        }
        memoObjects.nsPredicate = NSCompoundPredicate(type: .and, subpredicates: predicates)
    }

    func restoreMemo(for memo: MemoObject?) {
        guard let memo else { return }
        memo.isTrash = false
        memo.deletedAt = nil
        withPersistence(\.viewContext) { context in
            try context.saveIfNeeded()
        }
    }

    func restoreAndOpenMemo(for memo: MemoObject?) {
        restoreMemo(for: memo)
        self.sidebarItem = .memos
        if let memo {
            #if os(macOS)
            openWindow(id: "memo-view", value: memo.objectID.uriRepresentation())
            #else
            self.memo = memo
            #endif
        }
    }

    func deleteMemo(for memo: MemoObject?) {
        guard let memo else { return }
        withPersistenceSync(\.viewContext) { context in
            context.delete(memo)
            try context.saveIfNeeded()
        }
    }
}
