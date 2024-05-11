//
//  MemosView.swift
//  Memola
//
//  Created by Dscyre Scotti on 5/4/24.
//

import SwiftUI

struct MemosView: View {
    @Environment(\.managedObjectContext) var managedObjectContext

    @FetchRequest(sortDescriptors: []) var memoObjects: FetchedResults<MemoObject>

    @State var memo: MemoObject?

    var body: some View {
        NavigationStack {
            memoGrid
                .navigationTitle("Memos")
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            createMemo(title: "Untitled")
                        } label: {
                            Image(systemName: "plus")
                        }
                        .hoverEffect()
                    }
                }
        }
        .fullScreenCover(item: $memo) { memo in
            MemoView(memo: memo)
        }
    }

    var memoGrid: some View {
        ScrollView {
            LazyVGrid(columns: .init(repeating: GridItem(.flexible()), count: 3)) {
                ForEach(memoObjects) { memo in
                    memoCard(memo)
                }
            }
            .padding()
        }
    }

    func memoCard(_ memoObject: MemoObject) -> some View {
        VStack(alignment: .leading) {
            Rectangle()
                .frame(height: 150)
            Text(memoObject.title)
        }
        .onTapGesture {
            openMemo(for: memoObject)
        }
    }

    func createMemo(title: String) {
        do {
            let memoObject = MemoObject(context: managedObjectContext)
            memoObject.title = title
            memoObject.createdAt = .now
            memoObject.updatedAt = .now

            let canvasObject = CanvasObject(context: managedObjectContext)
            canvasObject.width = 4_000
            canvasObject.height = 4_000

            let graphicContextObject = GraphicContextObject(context: managedObjectContext)
            graphicContextObject.strokes = []

            memoObject.canvas = canvasObject
            canvasObject.memo = memoObject
            canvasObject.graphicContext = graphicContextObject
            graphicContextObject.canvas = canvasObject

            try managedObjectContext.save()
            openMemo(for: memoObject)
        } catch {
            NSLog("[Memola] - \(error.localizedDescription)")
        }
    }

    func openMemo(for memo: MemoObject) {
        self.memo = memo
    }
}
