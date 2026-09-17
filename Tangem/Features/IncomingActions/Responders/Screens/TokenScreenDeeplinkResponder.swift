//
//  TokenScreenDeeplinkResponder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

/// Answers on behalf of the token screen — token details and staking details alike — for the deeplinks it has
/// a flow of its own for: a swap inside the screen and buying the very token it shows.
final class TokenScreenDeeplinkResponder {
    @Injected(\.incomingActionManager) private var incomingActionManager: IncomingActionManaging
    @Injected(\.alertPresenter) private var alertPresenter: AlertPresenter

    private weak var coordinator: (any TokenScreenDeeplinkRoutable)?
    private let walletModel: any WalletModel
    private let userWalletInfo: UserWalletInfo

    init(
        coordinator: any TokenScreenDeeplinkRoutable,
        walletModel: any WalletModel,
        userWalletInfo: UserWalletInfo
    ) {
        self.coordinator = coordinator
        self.walletModel = walletModel
        self.userWalletInfo = userWalletInfo
    }
}

// MARK: - Private

@MainActor
private extension TokenScreenDeeplinkResponder {
    func route(_ action: IncomingAction) -> Bool {
        switch action {
        case .navigation(.swap(let deeplink)):
            return openSwap(deeplink)

        // The deeplink spec doesn't say yet what an unresolvable `user_wallet_id` means for `.buy`,
        // so it declines every foreign id, one naming no wallet at all included. Revisit then.
        case .navigation(.buy(let deeplink)):
            return walletAddressing(of: deeplink.userWalletId) == .thisWallet ? openOnramp() : false

        default:
            return false
        }
    }

    func walletAddressing(of userWalletId: String?) -> WalletAddressing {
        guard let userWalletId, userWalletId != userWalletInfo.id.stringValue else {
            return .thisWallet
        }

        return DeeplinkWalletModelLocator().findUserWalletModel(userWalletModelId: userWalletId) != nil
            ? .anotherWallet(userWalletId: userWalletId)
            : .unknownWallet
    }

    /// Opens the swap inside this screen's own flow, on the wallet the link names — not necessarily the one
    /// this screen was opened for. A wallet this device doesn't have leaves nothing to preselect.
    func openSwap(_ deeplink: SwapDeeplink) -> Bool {
        let addressing = walletAddressing(of: deeplink.userWalletId)

        let userWalletModel: (any UserWalletModel)? = switch addressing {
        case .thisWallet, .unknownWallet:
            DeeplinkWalletModelLocator().findUserWalletModel(userWalletModelId: userWalletInfo.id.stringValue)
        case .anotherWallet(let userWalletId):
            DeeplinkWalletModelLocator().findUserWalletModel(userWalletModelId: userWalletId)
        }

        guard
            let userWalletModel,
            let parameters = deeplink.makeParameters(for: userWalletModel, preselecting: addressing != .unknownWallet)
        else {
            return false
        }

        coordinator?.openSwap(parameters: parameters)
        return true
    }

    /// Buying from this screen means onramping the token it shows, not picking one from a selector.
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

extension TokenScreenDeeplinkResponder {
    /// Which wallet a deeplink names relative to the one this screen was opened for.
    enum WalletAddressing: Equatable {
        /// No `user_wallet_id`, or one naming this screen's wallet.
        case thisWallet
        case anotherWallet(userWalletId: String)
        /// A wallet this device doesn't have, which leaves the link effectively unaddressed.
        case unknownWallet
    }
}

// MARK: - IncomingActionResponder

extension TokenScreenDeeplinkResponder: IncomingActionResponder {
    func beginHandlingIncomingActions() {
        incomingActionManager.becomeFirstResponder(self)
    }

    func endHandlingIncomingActions() {
        incomingActionManager.resignFirstResponder(self)
    }

    func didReceiveIncomingAction(_ action: IncomingAction) -> Bool {
        // Incoming actions are dispatched on the main thread, and so is everything a deeplink reads here.
        guard MainActor.assumeIsolated({ route(action) }) else {
            return false
        }

        DeeplinkFloatingSheet.dismissActive()
        return true
    }
}
