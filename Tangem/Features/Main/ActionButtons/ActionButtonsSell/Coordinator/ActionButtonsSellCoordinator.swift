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

    @Published private(set) var actionButtonsSellViewModel: ActionButtonsSellViewModel?
    @Published private(set) var accountsAwareActionButtonsSellViewModel: AccountsAwareActionButtonsSellViewModel?

    let dismissAction: Action<ActionButtonsSendToSellModel?>
    let popToRootAction: Action<PopToRootOptions>

    private var safariHandle: SafariHandle?

    private let expressTokensListAdapter: ExpressTokensListAdapter
    private let tokenSorter: TokenAvailabilitySorter
    private let userWalletModel: UserWalletModel

    required init(
        expressTokensListAdapter: some ExpressTokensListAdapter,
        dismissAction: @escaping Action<ActionButtonsSendToSellModel?>,
        popToRootAction: @escaping Action<PopToRootOptions> = { _ in },
        userWalletModel: some UserWalletModel
    ) {
        self.expressTokensListAdapter = expressTokensListAdapter
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
        self.userWalletModel = userWalletModel

        tokenSorter = CommonSellTokenAvailabilitySorter(userWalletConfig: userWalletModel.config)
    }

    func start(with options: Options) {
        switch options {
        case .default:
            actionButtonsSellViewModel = ActionButtonsSellViewModel(
                tokenSelectorViewModel: makeTokenSelectorViewModel(),
                coordinator: self,
                userWalletModel: userWalletModel
            )
        case .new(let tokenSelectorViewModel):
            accountsAwareActionButtonsSellViewModel = AccountsAwareActionButtonsSellViewModel(
                tokenSelectorViewModel: tokenSelectorViewModel,
                coordinator: self
            )
        }
    }

    private func makeTokenSelectorViewModel() -> ActionButtonsTokenSelectorViewModel {
        TokenSelectorViewModel(
            tokenSelectorItemBuilder: ActionButtonsTokenSelectorItemBuilder(),
            strings: SellTokenSelectorStrings(),
            expressTokensListAdapter: expressTokensListAdapter,
            tokenSorter: tokenSorter
        )
    }
}

// MARK: - Options

extension ActionButtonsSellCoordinator {
    enum Options {
        case `default`
        case new(tokenSelectorViewModel: AccountsAwareTokenSelectorViewModel)
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
