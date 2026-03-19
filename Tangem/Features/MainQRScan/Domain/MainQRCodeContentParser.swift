//
//  MainQRCodeContentParser.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct MainQRCodeContentParser {
    private let walletConnectURLParser = WalletConnectURLParser()
    private let paymentRequestParser = MainQRPaymentRequestParser()

    func parse(_ rawValue: String) -> MainQRScanResult {
        let value = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !value.isEmpty else {
            return .unrecognized
        }

        if let walletConnectURI = try? walletConnectURLParser.parse(uriString: value) {
            return .walletConnect(walletConnectURI)
        }

        if let paymentRequest = paymentRequestParser.parse(value) {
            return .paymentURI(paymentRequest)
        }

        if MainQRParserSupport.hasPrefix(value, in: MainQRParserConstants.httpSchemes) {
            return .unrecognized
        }

        return .plainAddress(value)
    }
}
