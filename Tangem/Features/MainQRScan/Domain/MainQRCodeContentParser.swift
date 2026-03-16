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
        MainQRScanLogger.debug(MainQRScanLoggerStrings.parserStarted)

        guard !value.isEmpty else {
            MainQRScanLogger.debug(MainQRScanLoggerStrings.parserResultUnrecognizedEmptyPayload)
            return .unrecognized
        }

        if let walletConnectURI = try? walletConnectURLParser.parse(uriString: value) {
            MainQRScanLogger.debug(MainQRScanLoggerStrings.parserResultWalletConnect)
            return .walletConnect(walletConnectURI)
        }

        if let parsedPayment = paymentRequestParser.parse(value) {
            switch parsedPayment.source {
            case .blockchainURI:
                MainQRScanLogger.debug(MainQRScanLoggerStrings.parserResultPaymentURIBlockchainURI)
            case .json:
                MainQRScanLogger.debug(MainQRScanLoggerStrings.parserResultPaymentURIJSON)
            case .deepLink:
                MainQRScanLogger.debug(MainQRScanLoggerStrings.parserResultPaymentURIDeepLink)
            }

            return .paymentURI(parsedPayment.request)
        }

        if MainQRParserSupport.hasPrefix(value, in: MainQRParserConstants.httpSchemes) {
            MainQRScanLogger.debug(MainQRScanLoggerStrings.parserResultUnrecognizedHTTP)
            return .unrecognized
        }

        MainQRScanLogger.debug(MainQRScanLoggerStrings.parserResultPlainAddress)
        return .plainAddress(value)
    }
}
