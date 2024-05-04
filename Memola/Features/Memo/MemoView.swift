//
//  MemoView.swift
//  Memola
//
//  Created by Dscyre Scotti on 5/4/24.
//

import SwiftUI

struct MemoView: View {
    @Environment(\.dismiss) var dismiss
    var body: some View {
        VStack {
            Text("Memo View")
            Button {
                dismiss()
            } label: {
                Text("Close Memo")
            }
        }
    }
}
