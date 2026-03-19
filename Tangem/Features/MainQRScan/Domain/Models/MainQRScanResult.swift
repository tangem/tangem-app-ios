//
//  MainQRScanResult.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

enum MainQRScanResult {
    case walletConnect(WalletConnectRequestURI)
    case paymentURI(MainQRPaymentRequest)
    case plainAddress(String)
    case unrecognized
}
