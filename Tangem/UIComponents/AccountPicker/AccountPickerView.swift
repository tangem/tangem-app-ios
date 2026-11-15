//
//  AccountPickerView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI
import TangemAccounts

struct AccountPickerView: View {
    @ObservedObject private var viewModel: AccountPickerViewModel

    init(viewModel: AccountPickerViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        content
            .padding(.horizontal, 16)
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.content {
        case .userWallets(let items):
            UserWalletSelectorList(items: items, isBalanceMasked: viewModel.isBalanceMasked, onTap: viewModel.select)
        case .accounts(let sections):
            AccountPickerList(sections: sections, isBalanceMasked: viewModel.isBalanceMasked, onTap: viewModel.select)
        }
    }
}

// MARK: - Previews

#Preview {
    AccountPickerView(
        viewModel: AccountPickerViewModel(
            userWalletsProvider: PreviewUserWalletsProvider(),
            accountAvailabilityProvider: PreviewAvailabilityProvider(),
            onSelect: { _ in }
        )
    )
}

private struct PreviewUserWalletsProvider: AccountPickerUserWalletsProvider {
    var userWalletsPublisher: AnyPublisher<[AccountPickerUserWallet], Never> {
        let userWallets = FakeUserWalletModel.allFakeWalletModels.map { userWalletModel in
            AccountPickerUserWallet(
                userWalletModel: userWalletModel,
                accounts: [
                    CryptoAccountModelMock(isMainAccount: true, onArchive: { _ in }),
                    CryptoAccountModelMock(isMainAccount: false, accountType: .joint, onArchive: { _ in }),
                ]
            )
        }

        return .just(output: userWallets)
    }
}

private struct PreviewAvailabilityProvider: AccountPickerAccountAvailabilityProvider {
    func availability(of account: some BaseAccountModel, in userWalletModel: some UserWalletModel) -> SelectorAvailability {
        guard userWalletModel.userWalletId == FakeUserWalletModel.xrpNote.userWalletId else {
            return .available
        }

        return .unavailable(SelectorUnavailableReason(badge: nil, title: "Already added", message: "Already added"))
    }
}
