//
//  UserWalletListView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import SwiftUI

struct UserWalletListView: View {
    @ObservedObject private var viewModel: UserWalletListViewModel

    init(viewModel: UserWalletListViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(spacing: 16) {
            #warning("l10n")
            Text("My Wallets")
                .font(Font.body.bold)

            ScrollView(.vertical) {
                VStack(spacing: 0) {
                    #warning("l10n")
                    section("Multi-currency", for: viewModel.multiCurrencyModels)

                    #warning("l10n")
                    section("Single-currency", for: viewModel.singleCurrencyModels)
                }
            }
            .background(Colors.Background.primary)
            .cornerRadius(14)

            #warning("l10n")
            TangemButton(title: "Add new card", systemImage: "plus") {

            }
            .buttonStyle(TangemButtonStyle(colorStyle: .grayAlt, layout: .flexibleWidth))
        }
        .padding(16)
    }

    @ViewBuilder
    private func section(_ header: String, for models: [UserWalletListCellViewModel]) -> some View {
        if !models.isEmpty {
            UserWalletListHeaderView(name: header)

            ForEach(0 ..< models.count, id: \.self) { i in
                UserWalletListCellView(model: models[i], isSelected: viewModel.selectedAccountId == models[i].account.accountId) { account in
                    viewModel.onAccountTapped(account)
                }

                if i != (models.count - 1) {
                    Separator(height: 0.5, padding: 0, color: Colors.Stroke.primary)
                        .padding(.leading, 78)
                }
            }
        }
    }
}

struct UserWalletListView_Previews: PreviewProvider {
    static var previews: some View {
        UserWalletListView(viewModel: .init(coordinator: UserWalletListCoordinator()))
    }
}
