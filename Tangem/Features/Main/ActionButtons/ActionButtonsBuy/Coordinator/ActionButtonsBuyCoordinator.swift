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

    @Published var addToPortfolioBottomSheetInfo: HotCryptoAddToPortfolioModel?

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
        case .new:
            viewState = .newTokenList(
                NewActionButtonsBuyViewModel(coordinator: self)
            )
        }
    }
}

// MARK: - ActionButtonsBuyRoutable

extension ActionButtonsBuyCoordinator: ActionButtonsBuyRoutable {
    func openOnramp(walletModel: any WalletModel, userWalletModel: UserWalletModel) {
        let dismissAction: Action<SendCoordinator.DismissOptions?> = { [weak self] _ in
            self?.dismiss()
        }

        let coordinator = SendCoordinator(dismissAction: dismissAction)
        let options = SendCoordinator.Options(
            input: .init(
                userWalletInfo: userWalletModel.sendWalletInfo,
                walletModel: walletModel,
                expressInput: .init(userWalletModel: userWalletModel)
            ),
            type: .onramp(),
            source: .actionButtons
        )
        coordinator.start(with: options)
        viewState = .onramp(coordinator)
    }

    func openOnramp(input: SendInput) {
        let dismissAction: Action<SendCoordinator.DismissOptions?> = { [weak self] _ in
            self?.dismiss()
        }

        let coordinator = SendCoordinator(dismissAction: dismissAction)
        let options = SendCoordinator.Options(
            input: input,
            type: .onramp(),
            source: .actionButtons
        )
        coordinator.start(with: options)
        viewState = .onramp(coordinator)
    }

    func openAddToPortfolio(_ infoModel: HotCryptoAddToPortfolioModel) {
        addToPortfolioBottomSheetInfo = infoModel
    }

    func closeAddToPortfolio() {
        addToPortfolioBottomSheetInfo = nil
    }
}

// MARK: - Options

extension ActionButtonsBuyCoordinator {
    enum Options {
        case `default`(options: DefaultActionButtonBuyCoordinatorOptions)
        case new

        struct DefaultActionButtonBuyCoordinatorOptions {
            let userWalletModel: UserWalletModel
            let expressTokensListAdapter: ExpressTokensListAdapter
            let tokenSorter: TokenAvailabilitySorter
        }
    }

    enum RootViewState: Equatable {
        case tokenList(ActionButtonsBuyViewModel)
        case newTokenList(NewActionButtonsBuyViewModel)
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
