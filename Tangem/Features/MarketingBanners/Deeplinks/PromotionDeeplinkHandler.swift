//
//  PromotionDeeplinkHandler.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

final class PromotionDeeplinkHandler {
    @Injected(\.incomingActionManager) private var incomingActionManager: IncomingActionManaging
    @Injected(\.floatingSheetPresenter) private var floatingSheetPresenter: FloatingSheetPresenter
    @Injected(\.alertPresenter) private var alertPresenter: AlertPresenter

    private weak var coordinator: (any PromotionDeeplinkRoutable)?
    private let walletModel: any WalletModel
    private let userWalletInfo: UserWalletInfo
    private let walletModelLocator = DeeplinkWalletModelLocator()

    init(
        coordinator: any PromotionDeeplinkRoutable,
        walletModel: any WalletModel,
        userWalletInfo: UserWalletInfo
    ) {
        self.coordinator = coordinator
        self.walletModel = walletModel
        self.userWalletInfo = userWalletInfo
    }
}

// MARK: - Private

private extension PromotionDeeplinkHandler {
    func route(_ action: IncomingAction) -> Bool {
        guard case .navigation(let navigationAction) = action else {
            return false
        }

        let params = navigationAction.params
        let addressing = walletAddressing(of: params.userWalletId)

        switch navigationAction.destination {
        case .swap:
            switch addressing {
            case .thisWallet:
                return openSwap(userWalletId: userWalletInfo.id.stringValue, params: params)
            case .anotherWallet(let userWalletId):
                return openSwap(userWalletId: userWalletId, params: params)
            case .unknownWallet:
                return openSwap(userWalletId: userWalletInfo.id.stringValue, params: nil)
            }

        // The deeplink spec doesn't say yet what an unresolvable `user_wallet_id` means for `.buy` and
        // `.link`, so they decline every foreign id, one naming no wallet at all included. Revisit then.
        case .buy:
            return addressing == .thisWallet ? openOnramp() : false

        case .link:
            return addressing == .thisWallet ? openLink(url: params.url) : false

        default:
            return false
        }
    }

    func walletAddressing(of userWalletId: String?) -> WalletAddressing {
        guard let userWalletId, userWalletId != userWalletInfo.id.stringValue else {
            return .thisWallet
        }

        return walletModelLocator.findUserWalletModel(userWalletModelId: userWalletId) != nil
            ? .anotherWallet(userWalletId: userWalletId)
            : .unknownWallet
    }

    func openLink(url: URL?) -> Bool {
        guard let url else {
            return false
        }

        incomingActionManager.discardIncomingAction()
        coordinator?.openInSafari(url: url)
        return true
    }

    /// Opens swap on the given wallet, which is not necessarily the one this screen was opened for.
    /// `nil` params mean there is nothing to preselect, which opens the default swap right away.
    func openSwap(userWalletId: String, params: DeeplinkNavigationAction.Params?) -> Bool {
        guard
            let userWalletModel = walletModelLocator.findUserWalletModel(userWalletModelId: userWalletId),
            userWalletModel.config.hasFeature(.swapping)
        else {
            return false
        }

        if let params, let parameters = DeeplinkSwapParametersResolver().resolve(
            params: params,
            accountModelsManager: userWalletModel.accountModelsManager,
            userWalletInfo: userWalletModel.userWalletInfo
        ) {
            coordinator?.openSwap(parameters: parameters)
            return true
        }

        let walletModels = AccountWalletModelsAggregator.walletModels(from: userWalletModel.accountModelsManager)

        guard let sourceToken = MainSwapSourceResolver.makeBestEffortSourceToken(
            from: walletModels,
            userWalletInfo: userWalletModel.userWalletInfo
        ) else {
            return false
        }

        let resolver = MainSwapSourceResolver(
            userWalletModel: userWalletModel,
            swapAvailabilityChecker: CommonSwapAvailabilityChecker(userWalletInfo: userWalletModel.userWalletInfo)
        )

        coordinator?.openSwap(parameters: .from(sourceToken, pair: .deferred(sourceResolver: resolver)))
        return true
    }

    func openOnramp() -> Bool {
        let input = SendInput(userWalletInfo: userWalletInfo, walletModel: walletModel)
        let availabilityProvider = TokenActionAvailabilityProvider(userWalletInfo: userWalletInfo, walletModel: walletModel)

        TokenActionAvailabilityAlertPresenter.presentOrProceed(
            presenter: alertPresenter,
            warning: availabilityProvider.availabilityWarningType,
            action: { [weak self] in
                self?.coordinator?.openOnramp(input: input, parameters: .none)
            }
        )
        return true
    }
}

// MARK: - Types

extension PromotionDeeplinkHandler {
    /// Which wallet a deeplink names relative to the one this screen was opened for.
    enum WalletAddressing: Equatable {
        /// No `user_wallet_id`, or one naming this screen's wallet.
        case thisWallet
        case anotherWallet(userWalletId: String)
        /// A wallet this device doesn't have, which leaves the link effectively unaddressed.
        case unknownWallet
    }
}

// MARK: - IncomingActionRoutingHandler

extension PromotionDeeplinkHandler: IncomingActionRoutingHandler {
    func becomeIncomingActionsResponder() {
        incomingActionManager.becomeFirstResponder(self)
    }

    func resignIncomingActionsResponder() {
        incomingActionManager.resignFirstResponder(self)
    }

    func didReceiveIncomingAction(_ action: IncomingAction) -> Bool {
        let handled = route(action)

        if handled {
            Task { @MainActor in
                floatingSheetPresenter.removeActiveSheet()
            }
        }

        return handled
    }
}
