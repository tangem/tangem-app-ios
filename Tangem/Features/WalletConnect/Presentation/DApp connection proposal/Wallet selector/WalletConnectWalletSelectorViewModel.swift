//
//  WalletConnectWalletSelectorViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import typealias Foundation.TimeInterval

@MainActor
final class WalletConnectWalletSelectorViewModel: ObservableObject {
    private let backAction: () -> Void
    private let userWalletSelectedAction: (UserWalletModel) -> Void

    let selectionAnimationDuration: TimeInterval = 0.3

    @Published private(set) var state: WalletConnectWalletSelectorViewState

    init(
        userWallets: [any UserWalletModel],
        selectedUserWallet: some UserWalletModel,
        backAction: @escaping () -> Void,
        userWalletSelectedAction: @escaping (UserWalletModel) -> Void
    ) {
        state = .loading(userWallets: userWallets, selectedWallet: selectedUserWallet)
        self.backAction = backAction
        self.userWalletSelectedAction = userWalletSelectedAction
    }
}

// MARK: - View events handling

extension WalletConnectWalletSelectorViewModel {
    func handle(viewEvent: WalletConnectWalletSelectorViewEvent) {
        switch viewEvent {
        case .navigationBackButtonTapped:
            backAction()

        case .selectedUserWalletUpdated(let selectedUserWallet):
            updateSelectedUserWallet(selectedUserWallet)

            Task {
                let extraDelay = 0.2
                try await Task.sleep(seconds: self.selectionAnimationDuration + extraDelay)
                self.userWalletSelectedAction(selectedUserWallet)
            }
        }
    }
}

// MARK: - View state updates and mapping

extension WalletConnectWalletSelectorViewModel {
    func updateSelectedUserWallet(_ selectedUserWallet: some UserWalletModel) {
        let updatedWallets = state.wallets.map {
            WalletConnectWalletSelectorViewState.UserWallet(
                domainModel: $0.domainModel,
                state: $0.state,
                isSelected: $0.id == selectedUserWallet.userWalletId
            )
        }

        state.wallets = updatedWallets
    }
}

private extension WalletConnectWalletSelectorViewState {
    static func loading(userWallets: [any UserWalletModel], selectedWallet: some UserWalletModel) -> WalletConnectWalletSelectorViewState {
        WalletConnectWalletSelectorViewState(
            wallets: userWallets.map { userWallet in
                UserWallet(domainModel: userWallet, state: .loading, isSelected: userWallet.userWalletId == selectedWallet.userWalletId)
            }
        )
    }
}
