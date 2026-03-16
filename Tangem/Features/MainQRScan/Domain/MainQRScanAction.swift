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

extension MainQRScanAction {
    var debugName: String {
        switch self {
        case .walletConnect:
            return "walletConnect"
        case .paymentSingle:
            return "paymentSingle"
        case .paymentMultiple:
            return "paymentMultiple"
        case .addressSingle:
            return "addressSingle"
        case .addressMultiple:
            return "addressMultiple"
        case .showNoSupportedTokens:
            return "showNoSupportedTokens"
        case .showUnrecognized:
            return "showUnrecognized"
        }
    }
}
