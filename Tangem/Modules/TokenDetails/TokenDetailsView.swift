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
        .navigationBarItems(trailing: navbarTrailingButton)
        .background(Colors.Background.secondary.edgesIgnoringSafeArea(.all))
        .ignoresSafeArea(.keyboard)
        .onAppear(perform: viewModel.onAppear)
        .alert(item: $viewModel.alert) { $0.alert }
    }

    @ViewBuilder
    private var navbarTrailingButton: some View {
        Menu {
            if #available(iOS 15.0, *) {
                Button(Localization.tokenDetailsHideToken, role: .destructive, action: viewModel.hideTokenButtonAction)
            } else {
                Button(Localization.tokenDetailsHideToken, action: viewModel.hideTokenButtonAction)
            }
        } label: {
            NavbarDotsImage()
        }
    }
}
