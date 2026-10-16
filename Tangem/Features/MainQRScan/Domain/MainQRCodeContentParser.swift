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
    private let incomingActionParser = IncomingActionParser()

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

        if let url = URL(string: value), isDeeplink(url) {
            return .deeplink(url)
        }

        if MainQRParserSupport.hasPrefix(value, in: MainQRParserConstants.httpSchemes) {
            return .unrecognized
        }

        return .plainAddress(value)
    }

    private func isDeeplink(_ url: URL) -> Bool {
        guard FeatureProvider.isAvailable(.qrScanDeeplinks),
              let action = incomingActionParser.parseIncomingURL(url) else {
            return false
        }

        switch action {
        case .navigation, .externalLink:
            return true
        case .walletConnect, .start, .dismissSafari:
            return false
        }
    }
}
