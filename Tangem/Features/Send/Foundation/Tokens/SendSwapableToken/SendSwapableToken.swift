//
//  SendSwapableToken.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemExpress

protocol SendSwapableToken: SendSourceToken, ExpressSourceWallet {
    var isExemptFee: Bool { get }

    var sendingRestrictionsProvider: any SendingRestrictionsProvider { get }
    var receivingRestrictionsProvider: any ReceivingRestrictionsProvider { get }

    var tokenFeeProvidersManagerProvider: any TokenFeeProvidersManagerProvider { get }
    var expressTransactionValidator: ExpressTransactionValidator { get }
}

// MARK: ExpressSourceWallet + SendSourceToken

extension ExpressSourceWallet where Self: SendSwapableToken {
    var address: String? { defaultAddressString }
    var extraId: String? { .none }
    var currency: ExpressWalletCurrency { tokenItem.expressCurrency }
    var coinCurrency: ExpressWalletCurrency { feeTokenItem.expressCurrency }
    var feeCurrency: ExpressWalletCurrency { feeTokenItem.expressCurrency }
    var allowanceProvider: (any ExpressAllowanceProvider)? { allowanceService }
    var expressFeeProviderFactory: ExpressFeeProviderFactory { tokenFeeProvidersManagerProvider }
}
