//
//  MemosView.swift
//  Memola
//
//  Created by Dscyre Scotti on 5/4/24.
//

import SwiftUI

struct MemosView: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    @FetchRequest var memoObjects: FetchedResults<MemoObject>

    @State var memo: MemoObject?
    @State var query: String = ""
    @State var currentDate: Date = .now

    @AppStorage("memola.memo-objects.sort") var sort: Sort = .recent
    @AppStorage("memola.memo-objects.filter") var filter: Filter = .none

    let cellWidth: CGFloat = 250
    let cellHeight: CGFloat = 150
    let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    init() {
        let standard = UserDefaults.standard
        var descriptors: [SortDescriptor<MemoObject>] = []
        var predicates: [NSPredicate] = [NSPredicate(format: "isTrash = NO")]
        let sort = Sort(rawValue: standard.value(forKey: "memola.memo-objects.sort") as? String ?? "") ?? .recent
        let filter = Filter(rawValue: standard.value(forKey: "memola.memo-objects.filter") as? String ?? "") ?? .none
        if filter == .favorites {
            predicates.append(NSPredicate(format: "isFavorite = YES"))
        }
        descriptors = sort.memoSortDescriptors
        let predicate = NSCompoundPredicate(type: .and, subpredicates: predicates)
        _memoObjects = FetchRequest(sortDescriptors: descriptors, predicate: predicate)
    }

    var body: some View {
        NavigationStack {
            memoGrid
                .searchable(text: $query, placement: .toolbar, prompt: Text("Search"))
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Text("Memola")
                            .font(.title3)
                            .fontWeight(.bold)
                    }
                    ToolbarItemGroup(placement: .topBarTrailing) {
                        HStack(spacing: 5) {
                            Button {
                                createMemo(title: "Untitled")
                            } label: {
                                Image(systemName: "square.and.pencil")
                            }
                            .hoverEffect(.lift)
                            if horizontalSizeClass == .compact {
                                Menu {
                                    VStack {
                                        Picker("", selection: $sort) {
                                            ForEach(Sort.all) { sort in
                                                Text(sort.name)
                                                    .tag(sort)
                                            }
                                        }
                                        .pickerStyle(.automatic)
                                        Picker("", selection: $filter) {
                                            ForEach(Filter.all) { filter in
                                                Text(filter.name)
                                                    .tag(filter)
                                            }
                                        }
                                        .pickerStyle(.automatic)
                                    }
                                } label: {
                                    Image(systemName: "ellipsis.circle")
                                }
                            } else {
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
                                Menu {
                                    Picker("", selection: $filter) {
                                        ForEach(Filter.all) { filter in
                                            Text(filter.name)
                                                .tag(filter)
                                        }
                                    }
                                    .pickerStyle(.automatic)
                                } label: {
                                    Image(systemName: "line.3.horizontal.decrease.circle")
                                }
                            }
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
        .onChange(of: filter) { oldValue, newValue in
            updatePredicate()
        }
        .onReceive(timer) { date in
            currentDate = date
        }
        .onAppear {
            memoObjects.sortDescriptors = sort.memoSortDescriptors
            updatePredicate()
        }
    }

    @ViewBuilder
    var memoGrid: some View {
        if memoObjects.isEmpty {
            Placeholder(info: query.isEmpty ? .memoEmpty : .memoNotFound)
        } else {
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
    }

    func memoCard(_ memoObject: MemoObject) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Rectangle()
                .frame(height: cellHeight)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .contextMenu {
                    Button {
                        openMemo(for: memoObject)
                    } label: {
                        Label("Open", systemImage: "doc.text")
                    }
                    Button(role: .destructive) {
                        markAsTrash(for: memoObject)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
                .overlay(alignment: .topTrailing) {
                    Image(systemName: memoObject.isFavorite ? "star.fill" : "star")
                        .contentTransition(.symbolEffect(.replace))
                        .foregroundStyle(memoObject.isFavorite ? .yellow : .primary)
                        .animation(.easeInOut, value: memoObject.isFavorite)
                        .frame(width: 20, height: 20)
                        .padding(5)
                        .background(.gray)
                        .cornerRadius(5)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            toggleFavorite(for: memoObject)
                        }
                        .padding(5)
                }
            VStack(alignment: .leading, spacing: 2) {
                Text(memoObject.title)
                    .font(.headline)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Text("Edited \(memoObject.updatedAt.getTimeDifference(to: currentDate))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
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

        let canvasObject = CanvasObject(\.viewContext)
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
        var predicates: [NSPredicate] = [NSPredicate(format: "isTrash = NO")]
        if !query.isEmpty {
            predicates.append(NSPredicate(format: "title contains[c] %@", query))
        }
        if filter == .favorites {
            predicates.append(NSPredicate(format: "isFavorite = YES"))
        }
        memoObjects.nsPredicate = NSCompoundPredicate(type: .and, subpredicates: predicates)
    }

    func toggleFavorite(for memo: MemoObject) {
        memo.isFavorite.toggle()
        withPersistence(\.viewContext) { context in
            try context.saveIfNeeded()
        }
    }

    func markAsTrash(for memo: MemoObject) {
        memo.isTrash = true
        withPersistence(\.viewContext) { context in
            try context.saveIfNeeded()
        }
    }
}
