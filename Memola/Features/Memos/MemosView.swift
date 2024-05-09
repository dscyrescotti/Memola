//
//  MemosView.swift
//  Memola
//
//  Created by Dscyre Scotti on 5/4/24.
//

import SwiftUI

struct MemosView: View {
    @Environment(\.managedObjectContext) var managedObjectContext

    @FetchRequest(sortDescriptors: []) var memos: FetchedResults<Memo>

    @State var memo: Memo?

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
            MemoView()
                .environmentObject(memo.canvas)
        }
    }

    var memoGrid: some View {
        ScrollView {
            LazyVGrid(columns: .init(repeating: GridItem(.flexible()), count: 3)) {
                ForEach(memos) { memo in
                    memoCard(memo)
                }
            }
            .padding()
        }
    }

    func memoCard(_ memo: Memo) -> some View {
        VStack(alignment: .leading) {
            Rectangle()
                .frame(height: 150)
            Text(memo.title)
        }
        .onTapGesture {
            openMemo(for: memo)
        }
    }

    func createMemo(title: String) {
        do {
            let memo = Memo(context: managedObjectContext)
            memo.id = UUID()
            memo.title = title
            memo.createdAt = .now
            memo.updatedAt = .now

            let canvas = Canvas(context: managedObjectContext)
            canvas.id = UUID()
            canvas.width = 4_000
            canvas.height = 4_000

            let graphicContext = GraphicContext(context: managedObjectContext)
            graphicContext.id = UUID()
            graphicContext.strokes = []

            memo.canvas = canvas
            canvas.memo = memo
            canvas.graphicContext = graphicContext
            graphicContext.canvas = canvas

            try managedObjectContext.save()
            openMemo(for: memo)
        } catch {
            NSLog("[Memola] - \(error.localizedDescription)")
        }
    }

    func openMemo(for memo: Memo) {
        self.memo = memo
    }
}
