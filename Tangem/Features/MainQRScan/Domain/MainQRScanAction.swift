//
//  MainQRScanAction.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

enum MainQRScanAction: Equatable {
    case walletConnect(WalletConnectRequestURI)
    case paymentSingle(MainQRResolvedPaymentRequest)
    case paymentMultiple(MainQRResolvedPaymentRequest)
    case addressSingle(MainQRAddressRequest)
    case addressMultiple(MainQRAddressRequest)
    case showNoSupportedTokens
    case showUnrecognized
}
