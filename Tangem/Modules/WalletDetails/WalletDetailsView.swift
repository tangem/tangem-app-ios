//
//  WalletDetailsView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import SwiftUI

struct WalletDetailsView: View {
    @ObservedObject private var viewModel: WalletDetailsViewModel

    init(viewModel: WalletDetailsViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        GroupedScrollView(alignment: .leading, spacing: 24) {
            nameSection

            backupSection

            commonSection

            forgetSection
        }
        .interContentPadding(8)
        .background(Colors.Background.secondary.ignoresSafeArea())
        .navigationTitle("Wallet settings")
        .navigationBarTitleDisplayMode(.inline)
        .alert(item: $viewModel.alert) { $0.alert }
        .actionSheet(item: $viewModel.actionSheet) { $0.sheet }
        .scrollDismissesKeyboardCompat(.interactively)
        .onAppear(perform: viewModel.onAppear)
    }

    private var nameSection: some View {
        DefaultTextFieldRowView(title: Localization.customTokenNameInputTitle, text: $viewModel.name)
            .defaultRoundedBackground()
    }

    private var backupSection: some View {
        GroupedSection(viewModel.backupViewModel) {
            DefaultRowView(viewModel: $0)
        }
    }

    private var commonSection: some View {
        GroupedSection(viewModel.commonSectionModels) {
            DefaultRowView(viewModel: $0)
        }
    }

    private var forgetSection: some View {
        GroupedSection(viewModel.forgetViewModel) {
            DefaultRowView(viewModel: $0)
                .appearance(.destructiveButton)
        } footer: {
            DefaultFooterView("This will remove the wallet from the application. The wallet itself can be added again.")
        }
    }
}

struct WalletDetailsView_Preview: PreviewProvider {
    static let viewModel = WalletDetailsViewModel(
        userWalletModel: UserWalletModelMock(),
        coordinator: WalletDetailsCoordinator()
    )

    static var previews: some View {
        WalletDetailsView(viewModel: viewModel)
    }
}
