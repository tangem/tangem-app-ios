//
//  ActionButtonsSellCoordinator.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

final class ActionButtonsSellCoordinator: CoordinatorObject {
    @Injected(\.safariManager) private var safariManager: SafariManager

    @Published private(set) var accountsAwareActionButtonsSellViewModel: AccountsAwareActionButtonsSellViewModel?

    let dismissAction: Action<ActionButtonsSendToSellModel?>
    let popToRootAction: Action<PopToRootOptions>

    private var safariHandle: SafariHandle?

    private let userWalletModel: UserWalletModel

    required init(
        dismissAction: @escaping Action<ActionButtonsSendToSellModel?>,
        popToRootAction: @escaping Action<PopToRootOptions> = { _ in },
        userWalletModel: some UserWalletModel
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
        self.userWalletModel = userWalletModel
    }

    func start(with options: Options) {
        accountsAwareActionButtonsSellViewModel = AccountsAwareActionButtonsSellViewModel(
            tokenSelectorViewModel: options.tokenSelectorViewModel,
            coordinator: self
        )
    }
}

// MARK: - Options

extension ActionButtonsSellCoordinator {
    struct Options {
        let tokenSelectorViewModel: AccountsAwareTokenSelectorViewModel
    }
}

// MARK: - ActionButtonsSellRoutable

extension ActionButtonsSellCoordinator: ActionButtonsSellRoutable {
    func openSellCrypto(
        at url: URL,
        makeSellToSendToModel: @escaping (String) -> ActionButtonsSendToSellModel?
    ) {
        safariHandle = safariManager.openURL(url) { [weak self] closeURL in
            let sendToSellModel = makeSellToSendToModel(closeURL.absoluteString)

            self?.safariHandle = nil
            self?.dismiss(with: sendToSellModel)
        }
    }

    func dismiss() {
        dismiss(with: nil)
    }
}
