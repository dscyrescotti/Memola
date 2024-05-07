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

    @State var canvas: Canvas?

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
        .fullScreenCover(item: $canvas) { canvas in
            MemoView()
                .environmentObject(canvas)
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
            let data = try JSONEncoder().encode(Canvas())
            let memo = Memo(context: managedObjectContext)
            memo.id = UUID()
            memo.title = title
            memo.data = data
            memo.createdAt = .now
            memo.updatedAt = .now

            try managedObjectContext.save()
            openMemo(for: memo)
        } catch {
            NSLog("[SketchNote] - \(error.localizedDescription)")
        }
    }

    func openMemo(for memo: Memo) {
        do {
            let data = memo.data
            let canvas = try JSONDecoder().decode(Canvas.self, from: data)
            canvas.memo = memo
            self.canvas = canvas
        } catch {
            NSLog("[SketchNote] - \(error.localizedDescription)")
        }
    }
}
