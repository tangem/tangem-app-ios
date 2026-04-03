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
    case payment(MainQRResolvedPaymentRequest)
    case address(MainQRAddressRequest)
    case showNoSupportedTokens(MainQRNoSupportedTokensContext? = nil)
    case showUnrecognized
}
