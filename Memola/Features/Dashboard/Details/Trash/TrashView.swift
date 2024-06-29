//
//  TrashView.swift
//  Memola
//
//  Created by Dscyre Scotti on 6/29/24.
//

import SwiftUI

struct TrashView: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    @FetchRequest var memoObjects: FetchedResults<MemoObject>

    @State var query: String = ""

    var placeholder: Placeholder.Info {
        query.isEmpty ? .trashEmpty : .trashNotFound
    }

    init() {
        let descriptors = [SortDescriptor(\MemoObject.deletedAt, order: .reverse)]
        let predicate = NSPredicate(format: "isTrash = YES")
        _memoObjects = FetchRequest(sortDescriptors: descriptors, predicate: predicate)
    }

    var body: some View {
        MemoGrid(memoObjects: memoObjects, placeholder: placeholder) { memoObject in
                memoCard(memoObject)
            }
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $query, placement: .toolbar, prompt: Text("Search"))
            .toolbar {
                if horizontalSizeClass == .compact {
                    ToolbarItem(placement: .principal) {
                        Text("Trash")
                            .font(.title3)
                            .fontWeight(.bold)
                    }
                } else {
                    ToolbarItem(placement: .topBarLeading) {
                        Text("Memola")
                            .font(.title3)
                            .fontWeight(.bold)
                    }
                }
            }
            .onChange(of: query) { oldValue, newValue in
                updatePredicate()
            }
    }

    func memoCard(_ memoObject: MemoObject) -> some View {
        MemoCard(memoObject: memoObject) { card in
            card
                .contextMenu {
                    Button {

                    } label: {
                        Label("Restore", systemImage: "square.and.arrow.down")
                    }
                    Button(role: .destructive) {

                    } label: {
                        Label("Delete Permanently", systemImage: "trash")
                    }
                }
        } details: {
            Text("Deleted on \(memoObject.deletedAt.formatted(date: .abbreviated, time: .standard))")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .onTapGesture {

        }
    }

    func updatePredicate() {
        var predicates: [NSPredicate] = [NSPredicate(format: "isTrash = YES")]
        if !query.isEmpty {
            predicates.append(NSPredicate(format: "title contains[c] %@", query))
        }
        memoObjects.nsPredicate = NSCompoundPredicate(type: .and, subpredicates: predicates)
    }
}
