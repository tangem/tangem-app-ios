//
//  SendSwapableToken.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress

typealias SendWithSwapToken = SendSwapableToken

protocol SendSwapableToken: SendTransferableToken, ExpressSourceWallet {
    var isExemptFee: Bool { get }

    var swapAvailabilityProvider: any SwapAvailabilityProvider { get }
    var sendingRestrictionsProvider: any SendingRestrictionsProvider { get }
    var receivingRestrictionsProvider: any ReceivingRestrictionsProvider { get }

    var tokenFeeProvidersManagerProvider: any TokenFeeProvidersManagerProvider { get }

    var sendYieldModuleHelper: SendYieldModuleHelper? { get }
}

// MARK: ExpressSourceWallet + SendSourceToken

extension ExpressSourceWallet where Self: SendSwapableToken {
    var walletInfo: ExpressWalletInfo {
        ExpressWalletInfo(id: userWalletInfo.id.stringValue, refcode: userWalletInfo.refcode?.rawValue)
    }

    var address: String? { defaultAddressString }
    var extraId: String? { .none }
    var currency: ExpressWalletCurrency { tokenItem.expressCurrency }
    var coinCurrency: ExpressWalletCurrency { feeTokenItem.expressCurrency }
    var feeCurrency: ExpressWalletCurrency { feeTokenItem.expressCurrency }
    var allowanceProvider: (any ExpressAllowanceProvider)? { allowanceService }
    var yieldModuleTransactionHelper: YieldModuleTransactionHelper? { sendYieldModuleHelper }
    var expressFeeProviderFactory: ExpressFeeProviderFactory { tokenFeeProvidersManagerProvider }
}
