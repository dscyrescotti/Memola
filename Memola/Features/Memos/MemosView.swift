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
                .onDisappear {
                    withPersistence(\.viewContext) { context in
                        context.refreshAllObjects()
                    }
                }
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
        let memoObject = MemoObject(\.viewContext)
        memoObject.title = title
        memoObject.createdAt = .now
        memoObject.updatedAt = .now

        let canvasObject = CanvasObject(context: managedObjectContext)
        canvasObject.width = 8_000
        canvasObject.height = 8_000

        let toolObject = ToolObject(\.viewContext)
        toolObject.pens = []

        let eraserPenObject = PenObject.createObject(\.viewContext, penStyle: .eraser)
        eraserPenObject.orderIndex = 0
        let markerPenObject = PenObject.createObject(\.viewContext, penStyle: .marker)
        markerPenObject.orderIndex = 1

        let graphicContextObject = GraphicContextObject(\.viewContext)
        graphicContextObject.strokes = []

        memoObject.canvas = canvasObject
        memoObject.tool = toolObject

        canvasObject.memo = memoObject
        canvasObject.graphicContext = graphicContextObject

        toolObject.memo = memoObject
        toolObject.pens = [eraserPenObject, markerPenObject]

        eraserPenObject.tool = toolObject
        markerPenObject.tool = toolObject

        graphicContextObject.canvas = canvasObject

        withPersistenceSync(\.viewContext) { context in
            try context.save()
            DispatchQueue.main.async {
                openMemo(for: memoObject)
            }
        }
    }

    func openMemo(for memo: MemoObject) {
        self.memo = memo
    }
}
