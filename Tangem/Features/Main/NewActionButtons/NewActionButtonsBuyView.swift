//
//  NewActionButtonsBuyView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets
import TangemLocalization

struct NewActionButtonsBuyView: View {
    @ObservedObject var viewModel: NewActionButtonsBuyViewModel

    var body: some View {
        NewTokenSelectorView(viewModel: viewModel.tokenSelectorViewModel)
            .searchType(.native)
            .background(Colors.Background.tertiary.ignoresSafeArea())
            .navigationTitle(Localization.commonBuy)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    CloseButton { viewModel.close() }
                }
            }
            .onAppear(perform: viewModel.onAppear)
            .alert(item: $viewModel.alert) { $0.alert }
    }
}
