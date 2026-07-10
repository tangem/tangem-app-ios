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

    private weak var coordinator: (any PromotionDeeplinkRoutable)?
    private let walletModel: any WalletModel
    private let userWalletInfo: UserWalletInfo

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
            return openSwap()

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

    func openSwap() -> Bool {
        guard let parameters = SwapPredefinedParametersHelper().makeParameters(
            walletModel: walletModel,
            userWalletInfo: userWalletInfo,
            position: .automatic
        ) else {
            return false
        }

        coordinator?.openSwap(parameters: parameters)
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
        route(action)
    }
}
