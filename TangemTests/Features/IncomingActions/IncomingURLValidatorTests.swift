//
//  IncomingURLValidatorTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import Tangem

struct IncomingURLValidatorTests {
    private let urlValidator = CommonIncomingURLValidator()

    @Test(
        "Validate correct URLs",
        arguments: [
            URL(string: "https://tangem.com")!,
            URL(string: "https://app.tangem.com")!,
            URL(string: "https://tangem.com/redirect")!,
            URL(string: "tangem://buy")!,
            URL(string: "https://app.tangem.com/ndef")!,
            URL(string: "tangem://redirect?action=dismissBrowser")!,
            URL(string: "https://tangem.com/redirect?action=dismissBrowser")!,
            URL(string: "https://tangem.com/redirect_sell?transactionId=00000-0000-000&baseCurrencyCode=btc&baseCurrencyAmount=10&depositWalletAddress=xxxxxxx&depositWalletAddressTag=000000")!,
            URL(string: "tangem://redirect_sell?transactionId=00000-0000-000&baseCurrencyCode=btc&baseCurrencyAmount=10&depositWalletAddress=xxxxxxx&depositWalletAddressTag=000000)")!,
            URL(string: "tangem://wc?uri=wc%3Aa4f57e0493f84cfc7168a91579a18c5d9587dd1dd2d40efbe1cd916570399710%402%3Frelay-protocol%3Dirn%26symKey%3D57285434b30502b8991753225668f667e7c529926f007cec30652861ac11d8a4%26expiryTimestamp%3D1750166958")!,
            URL(string: "tangem://wc")!,
            URL(string: "tangem://onramp")!,
        ]
    )
    func acceptsCorrectURLs(validURL: URL) {
        #expect(urlValidator.validate(validURL), "Expected \(validURL) to be accepted")
    }

    @Test(
        "Rejects malformed or spoofed deeplink schemes",
        arguments: [
            URL(string: "tangeem://buy")!,
            URL(string: "tangem2://sell")!,
            URL(string: "https://google.com")!,
            URL(string: "fishing://token?network_id=ethereum&token_id=ethereum&type=income_transaction")!,
            URL(string: "http://tangem.com")!,
            URL(string: "https://tangem.co")!,
            URL(string: "https://app.tangem.co/ndef")!,
            URL(string: "ftp://tangem.com")!,
            URL(string: "file://tangem.com/secret")!,
            URL(string: "mailto:info@tangem.com")!,
            URL(string: "customscheme://open")!,
            URL(string: "chrome-extension://malicious-redirect")!,
            URL(string: "https://tangem.com.evil.com/hack")!,
            URL(string: "https://app.tangem.com.evil.com")!,
            URL(string: "tangem.com.foo.bar")!,
        ]
    )
    func rejectsInvalidDeeplinkLikeURLs(invalidURL: URL) {
        #expect(urlValidator.validate(invalidURL) == false, "Expected \(invalidURL) to be invalid")
    }
}
