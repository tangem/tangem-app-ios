//
//  ProductionLogSanitizerPolicyTests.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Testing
@testable import TangemLogger

@Suite(.tags(.logSanitizer))
struct ProductionLogSanitizerPolicyTests {
    @Test
    func shouldPreserveMultipleSafeValuesInSingleLog() {
        let input = #"response: <NSHTTPURLResponse: 0x106f3a120>;"#
            + #"start="2026-12-24T00:00:00.000Z";"#
            + #"end="1970-01-01T12:34:56Z""#

        let actual = LogSanitizer.sanitize(input, policy: .production)
        #expect(actual == input)
    }

    @Test
    func shouldPreserveAllValuesInSwapLog() {
        let input = """
        "txId": "23b0ba60-8f61-4917-83e7-0464f97f1d55",
        "providerId": "okx-cross-chain",
        "fromAddress": "0x0f0632254b1b45b835e5911E729871667E91BE12",
        "payinAddress": "0x89f423567c2648BB828c3997f60c47b54f57Fa6e",
        "payoutAddress": "0x0f0632254b1b45b835e5911E729871667E91BE12",
        "refundAddress": "0x0f0632254b1b45b835e5911E729871667E91BE12",
        "rateType": "float",
        "status": "finished",
        "externalTxStatus": "finished",
        "txHash": "0x7cebe3ac2dbfc308da75bd0645274972b021edca82f164f69370d21fad17eb0d",
        "fromContractAddress": "0xc2132d05d31c914a87c6611c10748aeb04b58e8f",
        "fromNetwork": "polygon-pos",
        "fromDecimals": 6,
        "fromAmount": "9000000",
        "toContractAddress": "0x2f2a2543b76a4166549f7aab2e75bef0aefc5b0f",
        "toNetwork": "arbitrum-one",
        "toDecimals": 8,
        "toAmount": "14428",
        "createdAt": "2024-09-19T06:35:22.312Z"
        """

        let actual = LogSanitizer.sanitize(input, policy: .production)
        #expect(actual == input)
    }

    @Test
    func shouldPreserveWalletConnectDeeplink() {
        let input = #"Received deeplink: tangem://wc?uri=wc%3Aa4f57e0493f84cfc7168a91579a18c5d9587dd1dd2d40efbe1cd916570399710%402%3Frelay-protocol%3Dirn%26symKey%3D57285434b30502b8991753225668f667e7c529926f007cec30652861ac11d8a4%26expiryTimestamp%3D1750166958"#

        let actual = LogSanitizer.sanitize(input, policy: .production)
        #expect(actual == input)
    }

    @Test
    func shouldPreserveWalletConnectProposalContainingISO8601Timestamp() {
        let input = #"Session proposal: Proposal(id: "id", pairingTopic: "pairingTopic", proposer: WalletConnectPairing.AppMetadata(name: "App", description: "Description", url: "https://react-app.walletconnect.com", icons: [], redirect: nil), requiredNamespaces: [:], optionalNamespaces: nil, sessionProperties: nil, scopedProperties: nil, requests: Optional(WalletConnectSign.ProposalRequests(authentication: Optional([WalletConnectSign.AuthPayload(domain: "react-app.walletconnect.com", aud: "https://react-app.walletconnect.com", version: "1", nonce: "1", chains: ["eip155:1"], type: "caip122", iat: "2026-04-29T13:52:24.409Z", nbf: nil, exp: nil, statement: nil, requestId: nil, resources: nil, signatureTypes: nil)]))), proposal: WalletConnectSign.SessionProposal(relays: [WalletConnectUtils.RelayProtocolOptions(protocol: "irn", data: nil)], proposer: WalletConnectSign.Participant(publicKey: "publicKey", metadata: WalletConnectPairing.AppMetadata(name: "App", description: "Description", url: "https://react-app.walletconnect.com", icons: [], redirect: nil)), requiredNamespaces: [:], optionalNamespaces: nil, sessionProperties: nil, scopedProperties: nil, expiryTimestamp: Optional(1777471744), requests: nil))"#

        let actual = LogSanitizer.sanitize(input, policy: .production)
        #expect(actual == input)
    }

    @Test
    func shouldRedactSensitiveValuesWithoutAffectingPreservedValues() {
        let input = #"response: <NSHTTPURLResponse: 0x106f3a120>; timestamp="2026-12-24T00:00:00.000Z"; "#
            + #"headers: ["api-key": "secret123", "access-token": "abc/def=="]"#

        let expected = #"response: <NSHTTPURLResponse: 0x106f3a120>; timestamp="2026-12-24T00:00:00.000Z"; "#
            + #"headers: ["api-key": "\#(Self.sensitiveKeyRedactPlaceholder)", "#
            + #""access-token": "\#(Self.sensitiveKeyRedactPlaceholder)"]"#

        let actual = LogSanitizer.sanitize(input, policy: .production)

        #expect(actual == expected)
    }

    @Test
    func shouldBeIdempotent() {
        let input = #"response: <NSHTTPURLResponse: 0x106f3a120>; "#
            + #"timestamp="2026-12-24T00:00:00.000Z"; "#
            + #"headers: ["api-key": "secret123"]; hex=0xdeadbeef"#

        let firstPass = LogSanitizer.sanitize(input, policy: .production)
        let secondPass = LogSanitizer.sanitize(firstPass, policy: .production)

        #expect(firstPass == secondPass)
    }

    @Test
    func shouldLeaveSafeLogUnchanged() {
        let input = #"response: success; status=200; message="everything is fine""#
        let actual = LogSanitizer.sanitize(input, policy: .production)

        #expect(actual == input)
    }

    @Test
    func shouldRedactMultipleSensitiveKeysInSingleLog() {
        let input = "key=abcd1234abcd5678abcd&auth=1234abcd1234abcd1234"
        let expected = "key=\(Self.sensitiveKeyRedactPlaceholder)&auth=\(Self.sensitiveKeyRedactPlaceholder)"

        let actual = LogSanitizer.sanitize(input, policy: .production)

        #expect(actual == expected)
    }

    @Test
    func shouldRedactSensitiveKeyInsideJsonPayload() {
        let input = #"{"key": "abcd1234abcd5678abcd"}"#
        let expected = #"{"key": "\#(Self.sensitiveKeyRedactPlaceholder)"}"#

        let actual = LogSanitizer.sanitize(input, policy: .production)

        #expect(actual == expected)
    }

    @Test
    func shouldRedactSensitiveKeyAndBroadHexInSingleLog() {
        let input = "x-api-key=abcd1234abcd5678abcd hex=deadbeefcafebabe"
        let expected = "x-api-key=\(Self.sensitiveKeyRedactPlaceholder) hex=\(Self.broadHexRedactPlaceholder)"

        let actual = LogSanitizer.sanitize(input, policy: .production)

        #expect(actual == expected)
    }

    @Test
    func shouldRedactKeysAndBroadHexInNetworkRequestLog() {
        let input = """
        🟠 request: https://api.tangem.org/card/artworks¸
           headers: [
             "card_public_key": "7C2A9F1E4D6B8C3F0A5E7D1B9C4F2A6E8B1D3C7F5A9E0C2B6D4F8A1E3C5B7D9"¸
             "card_id": "C91B0000002A7E4F"¸
             "device": "iPhone 69"¸
             "platform": "ios"¸
             "system_version": "42.0"¸
             "language": "en-GB"¸
             "version": "6.7"¸
             "api-key": "kR9vTqLmP4xZc8Hs2NwJfYgD7UaB3eQi6XpMoK1rCzVtEyL5hSnFu0WbAjIGdORXl"¸
             "Content-Type": "application/json"¸
             "timezone": "Asia/Bangkok"
           ]
        """

        let expected = """
        🟠 request: https://api.tangem.org/card/artworks¸
           headers: [
             "card_public_key": "\(Self.sensitiveKeyRedactPlaceholder)"¸
             "card_id": "\(Self.broadHexRedactPlaceholder)"¸
             "device": "iPhone 69"¸
             "platform": "ios"¸
             "system_version": "42.0"¸
             "language": "en-GB"¸
             "version": "6.7"¸
             "api-key": "\(Self.sensitiveKeyRedactPlaceholder)"¸
             "Content-Type": "application/json"¸
             "timezone": "Asia/Bangkok"
           ]
        """

        let actual = LogSanitizer.sanitize(input, policy: .production)

        #expect(actual == expected)
    }
}

extension ProductionLogSanitizerPolicyTests {
    private static let sensitiveKeyRedactPlaceholder = "REDACTED_SENSITIVE_KEY"
    private static let broadHexRedactPlaceholder = "REDACTED_HEX"
}
