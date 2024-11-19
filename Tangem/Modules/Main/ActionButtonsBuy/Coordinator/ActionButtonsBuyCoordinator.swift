//
//  ActionButtonsBuyCoordinator.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

final class ActionButtonsBuyCoordinator: CoordinatorObject {
    @Injected(\.safariManager) private var safariManager: SafariManager

    @Published private(set) var actionButtonsBuyViewModel: ActionButtonsBuyViewModel?

    private var safariHandle: SafariHandle?

    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    private let expressTokensListAdapter: ExpressTokensListAdapter
    private let tokenSorter: TokenAvailabilitySorter

    required init(
        expressTokensListAdapter: some ExpressTokensListAdapter,
        tokenSorter: some TokenAvailabilitySorter = CommonBuyTokenAvailabilitySorter(),
        dismissAction: @escaping Action<Void>,
        popToRootAction: @escaping Action<PopToRootOptions> = { _ in }
    ) {
        self.expressTokensListAdapter = expressTokensListAdapter
        self.tokenSorter = tokenSorter
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        actionButtonsBuyViewModel = ActionButtonsBuyViewModel(
            coordinator: self,
            tokenSelectorViewModel: makeTokenSelectorViewModel()
        )
    }

    private func makeTokenSelectorViewModel() -> TokenSelectorViewModel<
        ActionButtonsTokenSelectorItem,
        ActionButtonsTokenSelectorItemBuilder
    > {
        TokenSelectorViewModel(
            tokenSelectorItemBuilder: ActionButtonsTokenSelectorItemBuilder(),
            strings: BuyTokenSelectorStrings(),
            expressTokensListAdapter: expressTokensListAdapter,
            tokenSorter: tokenSorter
        )
    }
}

extension ActionButtonsBuyCoordinator: ActionButtonsBuyRoutable {
    func openBuyCrypto(at url: URL) {
        safariHandle = safariManager.openURL(url) { [weak self] _ in
            self?.safariHandle = nil
            self?.dismiss()
        }
    }
}

extension ActionButtonsBuyCoordinator {
    enum Options {
        case `default`
    }
}
