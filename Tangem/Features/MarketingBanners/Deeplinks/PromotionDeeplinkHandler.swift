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

        if let targetUserWalletId = navigationAction.params.userWalletId,
           targetUserWalletId != userWalletInfo.id.stringValue {
            return false
        }

        switch navigationAction.destination {
        case .swap:
            return openSwap(params: navigationAction.params)

        case .buy:
            return openOnramp()

        case .link:
            return openLink(url: navigationAction.params.url)

        default:
            return false
        }
    }

    func openLink(url: URL?) -> Bool {
        guard let url else {
            return false
        }

        incomingActionManager.discardIncomingAction()
        coordinator?.openInSafari(url: url)
        return true
    }

    func openSwap(params: DeeplinkNavigationAction.Params) -> Bool {
        guard let userWalletModel = walletModelLocator.findUserWalletModel(userWalletModelId: userWalletInfo.id.stringValue) else {
            return false
        }

        if let parameters = DeeplinkSwapParametersResolver().resolve(
            params: params,
            accountModelsManager: userWalletModel.accountModelsManager,
            userWalletInfo: userWalletModel.userWalletInfo
        ) {
            coordinator?.openSwap(parameters: parameters)
            return true
        }

        let walletModels = AccountWalletModelsAggregator.walletModels(from: userWalletModel.accountModelsManager)

        guard let sourceToken = MainSwapPairResolver.makeBestEffortSourceToken(
            from: walletModels,
            userWalletInfo: userWalletModel.userWalletInfo
        ) else {
            return false
        }

        let resolver = MainSwapPairResolver(
            userWalletModel: userWalletModel,
            swapAvailabilityChecker: CommonSwapAvailabilityChecker(userWalletInfo: userWalletModel.userWalletInfo)
        )

        coordinator?.openSwap(parameters: .deferredPairResolution(source: sourceToken, resolver: resolver))
        return true
    }

    func openOnramp() -> Bool {
        let input = SendInput(userWalletInfo: userWalletInfo, walletModel: walletModel)
        coordinator?.openOnramp(input: input, parameters: .none)
        return true
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
