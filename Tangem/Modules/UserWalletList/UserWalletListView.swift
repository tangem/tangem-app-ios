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
                    if !viewModel.walletCellModels.isEmpty {
                        #warning("l10n")
                        UserWalletListHeaderView(name: "Multi-currency")

                        ForEach(viewModel.walletCellModels) { cellModel in
                            UserWalletListCellView(model: cellModel)
                        }
                    }

                    if !viewModel.noteCellModels.isEmpty {
                        #warning("l10n")
                        UserWalletListHeaderView(name: "Single-currency")

                        ForEach(viewModel.noteCellModels) { cellModel in
                            UserWalletListCellView(model: cellModel)
                        }
                    }
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
}

struct UserWalletListView_Previews: PreviewProvider {
    static var previews: some View {
        UserWalletListView(viewModel: .init(coordinator: UserWalletListCoordinator()))
    }
}
