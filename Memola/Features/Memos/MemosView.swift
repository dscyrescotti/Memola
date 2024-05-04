//
//  MemosView.swift
//  Memola
//
//  Created by Dscyre Scotti on 5/4/24.
//

import SwiftUI

struct MemosView: View {
    @State var isPresented: Bool = false
    var body: some View {
        VStack {
            Text("Memos View")
            Button {
                isPresented.toggle()
            } label: {
                Text("Open Memo")
            }
            .fullScreenCover(isPresented: $isPresented) {
                MemoView()
            }
        }
    }
}
