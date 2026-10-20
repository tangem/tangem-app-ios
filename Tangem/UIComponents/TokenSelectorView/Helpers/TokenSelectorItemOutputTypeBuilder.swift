//
//  TokenSelectorItemOutputTypeBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress
import TangemLocalization
import struct TangemUIUtils.AlertBinder

struct TokenSelectorItemOutputTypeBuilder {
    let expressOperationType: ExpressOperationType

    func makeReceiveToken(item: TokenSelectorItem) throws -> SendReceiveToken {
        switch item.kind {
        case .crypto(let walletModel, _) where walletModel.isJointAccountParticipant:
            return CommonSendSourceTokenFactory(
                userWalletInfo: item.userWalletInfo,
                walletModel: walletModel
            ).makeSourceToken()

        case .crypto, .tangemPay:
            return try makeSwapableToken(item: item)
        }
    }

    func makeSwapableToken(item: TokenSelectorItem) throws -> SendSwapableToken {
        switch item.kind {
        case .crypto(let walletModel, _) where walletModel.isJointAccountParticipant:
            let sourceAvailability = TokenActionAvailabilityProvider(
                userWalletInfo: item.userWalletInfo,
                walletModel: walletModel
            ).swapSourceAvailability()

            throw BuildError.receiveOnlyToken(item.tokenItem, sourceAvailability: sourceAvailability)

        case .crypto(let walletModel, _):
            return CommonSendSwapableTokenFactory(
                userWalletInfo: item.userWalletInfo,
                walletModel: walletModel,
                operationType: expressOperationType
            ).makeSwapableToken()

        case .tangemPay(let tangemPayAccount, let accountToken, let account):
            return TangemPaySwapableTokenFactory(
                userWalletInfo: item.userWalletInfo,
                tangemPayAccount: tangemPayAccount,
                account: account,
                accountToken: accountToken,
                operationType: expressOperationType,
                receiveTokenPresentation: .tangemPayAccount
            ).makeSwapableToken()
        }
    }
}

extension TokenSelectorItemOutputTypeBuilder {
    enum BuildError: LocalizedError {
        case receiveOnlyToken(TokenItem, sourceAvailability: TokenActionAvailabilityProvider.SwapSourceActionAvailabilityStatus)

        var errorDescription: String? {
            switch self {
            case .receiveOnlyToken(let tokenItem, _):
                "\(tokenItem.name) can only be swapped into"
            }
        }
    }
}

// MARK: - BindableError

extension TokenSelectorItemOutputTypeBuilder.BuildError: BindableError {
    var binder: AlertBinder {
        alertBinder(okAction: {})
    }

    func alertBinder(okAction: @escaping () -> Void) -> AlertBinder {
        switch self {
        case .receiveOnlyToken(_, let sourceAvailability):
            TokenActionAvailabilityAlertBuilder().alert(for: sourceAvailability)
                ?? AlertBinder(title: Localization.commonError, message: localizedDescription)
        }
    }
}
