//
//  MemosView.swift
//  Memola
//
//  Created by Dscyre Scotti on 5/4/24.
//

import SwiftUI

struct MemosView: View {
    @Environment(\.managedObjectContext) var managedObjectContext

    @FetchRequest var memoObjects: FetchedResults<MemoObject>

    @State var memo: MemoObject?
    @State var query: String = ""

    @AppStorage("memola.memo-objects.sort") var sort: Sort = .recent

    let cellWidth: CGFloat = 250
    let cellHeight: CGFloat = 150

    init() {
        let standard = UserDefaults.standard
        var descriptors: [SortDescriptor<MemoObject>] = []
        let sort = Sort(rawValue: standard.value(forKey: "memola.memo-objects.sort") as? String ?? "") ?? .recent
        descriptors = sort.memoSortDescriptors
        _memoObjects = FetchRequest(sortDescriptors: descriptors)
    }

    var body: some View {
        NavigationStack {
            memoGrid
                .navigationTitle("Memos")
                .searchable(text: $query, placement: .toolbar, prompt: Text("Search"))
                .toolbar {
                    ToolbarItemGroup(placement: .primaryAction) {
                        HStack(spacing: 5) {
                            Button {
                                createMemo(title: "Untitled")
                            } label: {
                                Image(systemName: "square.and.pencil")
                            }
                            .hoverEffect(.lift)
                            Menu {
                                Picker("", selection: $sort) {
                                    ForEach(Sort.all) { sort in
                                        Text(sort.name)
                                            .tag(sort)
                                    }
                                }
                            } label: {
                                Image(systemName: "arrow.up.arrow.down.circle")
                            }
                            .hoverEffect(.lift)
                        }
                    }
                }
        }
        .fullScreenCover(item: $memo) { memo in
            MemoView(memo: memo)
                .onDisappear {
                    withPersistence(\.viewContext) { context in
                        try context.saveIfNeeded()
                        context.refreshAllObjects()
                    }
                }
        }
        .onChange(of: sort) { oldValue, newValue in
            memoObjects.sortDescriptors = newValue.memoSortDescriptors
        }
        .onChange(of: query) { oldValue, newValue in
            updatePredicate()
        }
    }

    var memoGrid: some View {
        GeometryReader { proxy in
            let count = Int(proxy.size.width / cellWidth)
            let columns: [GridItem] = .init(repeating: GridItem(.flexible(), spacing: 15), count: count)
            ScrollView {
                LazyVGrid(columns: columns, spacing: 15) {
                    ForEach(memoObjects) { memo in
                        memoCard(memo)
                    }
                }
                .padding()
            }
        }
    }

    func memoCard(_ memoObject: MemoObject) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Rectangle()
                .frame(height: cellHeight)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            Text(memoObject.title)
                .font(.headline)
                .fontWeight(.semibold)
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
        canvasObject.gridMode = 1

        let toolObject = ToolObject(\.viewContext)
        toolObject.selection = 0
        toolObject.pens = []

        let eraserPenObject = PenObject.createObject(\.viewContext, penStyle: .eraser)
        eraserPenObject.orderIndex = 0
        let markerPenObjects = [Color.red, Color.blue, Color.yellow, Color.black].enumerated().map { (index, color) in
            let penObject = PenObject.createObject(\.viewContext, penStyle: .marker)
            penObject.orderIndex = Int16(index) + 1
            penObject.color = color.components
            return penObject
        }
        markerPenObjects.first?.isSelected = true

        let graphicContextObject = GraphicContextObject(\.viewContext)
        graphicContextObject.elements = []

        memoObject.canvas = canvasObject
        memoObject.tool = toolObject

        canvasObject.memo = memoObject
        canvasObject.graphicContext = graphicContextObject

        toolObject.memo = memoObject
        toolObject.pens = .init(array: [eraserPenObject] + markerPenObjects)

        eraserPenObject.tool = toolObject
        markerPenObjects.forEach { $0.tool = toolObject }

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

    func updatePredicate() {
        var predicates: [NSPredicate] = []
        if !query.isEmpty {
            predicates.append(NSPredicate(format: "title contains[c] %@", query))
        }
//        if filter == .favorites {
//            predicates.append(NSPredicate(format: "isFavorite = YES"))
//        }
        memoObjects.nsPredicate = NSCompoundPredicate(type: .and, subpredicates: predicates)
    }
}
