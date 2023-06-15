//
//  TokenDetailsView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct TokenDetailsView: View {
    @ObservedObject var viewModel: TokenDetailsViewModel

    var body: some View {
        RefreshableScrollView(onRefresh: viewModel.onRefresh) {
            VStack(spacing: 14) {
                BalanceWithButtonsView(viewModel: viewModel.balanceWithButtonsModel)
            }
        }
        .padding(.horizontal, 16)
        .edgesIgnoringSafeArea(.bottom)
        .navigationBarTitle("", displayMode: .inline)
        .background(Colors.Background.secondary.edgesIgnoringSafeArea(.all))
        .alert(item: $viewModel.alert) { $0.alert }
    }
}
