//
//  ManageTokensSheetView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct ManageTokensSheetView<RootContent: View>: View {
    @ObservedObject private var viewModel: ManageTokensSheetViewModel
    @ObservedObject private var stateObject: BottomScrollableSheetStateObject
    private let content: () -> RootContent

    init(
        viewModel: ManageTokensSheetViewModel,
        stateObject: BottomScrollableSheetStateObject,
        @ViewBuilder content: @escaping () -> RootContent
    ) {
        self.viewModel = viewModel
        self.stateObject = stateObject
        self.content = content
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            content()

            bottomSheet

            sheets
        }
    }

    private var bottomSheet: some View {
        BottomScrollableSheet(stateObject: stateObject) {
            TextField("Placeholder", text: $viewModel.searchText)
                .frame(height: 46)
                .padding(.horizontal, 12)
                .background(Colors.Field.primary)
                .cornerRadius(14)
                .padding(.horizontal, 16)
        } content: {
            LazyVStack(spacing: .zero) {
                ForEach(viewModel.dataSource(), id: \.self) { index in
                    Button(action: viewModel.toggleItem) {
                        Text(index)
                            .font(.title3)
                            .foregroundColor(Color.black.opacity(0.8))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.all)
                    }

                    Divider()
                }
            }
        }
    }

    private var sheets: some View {
        NavHolder()
            .bottomSheet(item: $viewModel.bottomSheet) {
                BottomSheetContainer_Previews.BottomSheetView(viewModel: $0)
            }
    }
}
