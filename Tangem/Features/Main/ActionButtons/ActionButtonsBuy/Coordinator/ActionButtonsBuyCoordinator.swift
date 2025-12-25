//
//  ActionButtonsBuyCoordinator.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

final class ActionButtonsBuyCoordinator: CoordinatorObject {
    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    // MARK: - Dependencies

    @Injected(\.safariManager) private var safariManager: SafariManager

    // MARK: - Published property

    @Published private(set) var viewState: RootViewState?

    @Published var addToPortfolioBottomSheetInfo: HotCryptoAddToPortfolioBottomSheetViewModel?

    // MARK: - Private property

    private var safariHandle: SafariHandle?

    required init(
        dismissAction: @escaping Action<Void>,
        popToRootAction: @escaping Action<PopToRootOptions> = { _ in }
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        switch options {
        case .default(let options):
            viewState = .tokenList(
                ActionButtonsBuyViewModel(
                    tokenSelectorViewModel: makeTokenSelectorViewModel(
                        expressTokensListAdapter: options.expressTokensListAdapter,
                        tokenSorter: options.tokenSorter
                    ),
                    coordinator: self,
                    userWalletModel: options.userWalletModel
                )
            )
        case .new(let tokenSelectorViewModel):
            viewState = .newTokenList(
                AccountsAwareActionButtonsBuyViewModel(tokenSelectorViewModel: tokenSelectorViewModel, coordinator: self)
            )
        }
    }
}

// MARK: - ActionButtonsBuyRoutable

extension ActionButtonsBuyCoordinator: ActionButtonsBuyRoutable {
    func openOnramp(input: SendInput, parameters: PredefinedOnrampParameters) {
        let dismissAction: Action<SendCoordinator.DismissOptions?> = { [weak self] _ in
            self?.dismiss()
        }

        let coordinator = SendCoordinator(dismissAction: dismissAction)
        let options = SendCoordinator.Options(
            input: input,
            type: .onramp(parameters: parameters),
            source: .actionButtons
        )
        coordinator.start(with: options)
        viewState = .onramp(coordinator)
    }

    func openAddToPortfolio(viewModel: HotCryptoAddToPortfolioBottomSheetViewModel) {
        addToPortfolioBottomSheetInfo = viewModel
    }

    func closeAddToPortfolio() {
        addToPortfolioBottomSheetInfo = nil
    }
}

// MARK: - Options

extension ActionButtonsBuyCoordinator {
    enum Options {
        case `default`(options: DefaultActionButtonBuyCoordinatorOptions)
        case new(tokenSelectorViewModel: AccountsAwareTokenSelectorViewModel)

        struct DefaultActionButtonBuyCoordinatorOptions {
            let userWalletModel: UserWalletModel
            let expressTokensListAdapter: ExpressTokensListAdapter
            let tokenSorter: TokenAvailabilitySorter
        }
    }

    enum RootViewState: Equatable {
        case tokenList(ActionButtonsBuyViewModel)
        case newTokenList(AccountsAwareActionButtonsBuyViewModel)
        case onramp(SendCoordinator)

        static func == (lhs: RootViewState, rhs: RootViewState) -> Bool {
            switch (lhs, rhs) {
            case (.tokenList, .tokenList): true
            case (.newTokenList, .newTokenList): true
            case (.onramp, .onramp): true
            default: false
            }
        }
    }
}

// MARK: - Factory method

private extension ActionButtonsBuyCoordinator {
    func makeTokenSelectorViewModel(expressTokensListAdapter: some ExpressTokensListAdapter, tokenSorter: TokenAvailabilitySorter) -> ActionButtonsTokenSelectorViewModel {
        TokenSelectorViewModel(
            tokenSelectorItemBuilder: ActionButtonsTokenSelectorItemBuilder(),
            strings: BuyTokenSelectorStrings(),
            expressTokensListAdapter: expressTokensListAdapter,
            tokenSorter: tokenSorter
        )
    }
}
