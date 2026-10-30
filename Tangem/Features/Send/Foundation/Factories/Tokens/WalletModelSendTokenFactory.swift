//
//  WalletModelSendTokenFactory.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress
import TangemLocalization
import struct TangemUIUtils.AlertBinder

struct WalletModelSendTokenFactory {
    let userWalletInfo: UserWalletInfo
    let walletModel: any WalletModel
    let operationType: ExpressOperationType

    func makeSwapableToken() throws -> SendSwapableToken {
        guard walletModel.isJointAccountParticipant else {
            return CommonSendSwapableTokenFactory(
                userWalletInfo: userWalletInfo,
                walletModel: walletModel,
                operationType: operationType
            ).makeSwapableToken()
        }

        let sourceAvailability = TokenActionAvailabilityProvider(
            userWalletInfo: userWalletInfo,
            walletModel: walletModel
        ).swapSourceAvailability()

        throw BuildError.receiveOnlyToken(walletModel.tokenItem, sourceAvailability: sourceAvailability)
    }

    func makeReceiveToken() -> SendReceiveToken {
        guard walletModel.isJointAccountParticipant else {
            return CommonSendSwapableTokenFactory(
                userWalletInfo: userWalletInfo,
                walletModel: walletModel,
                operationType: operationType
            ).makeSwapableToken()
        }

        return CommonSendSourceTokenFactory(
            userWalletInfo: userWalletInfo,
            walletModel: walletModel
        ).makeSourceToken()
    }
}

extension WalletModelSendTokenFactory {
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

extension WalletModelSendTokenFactory.BuildError: BindableError {
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
