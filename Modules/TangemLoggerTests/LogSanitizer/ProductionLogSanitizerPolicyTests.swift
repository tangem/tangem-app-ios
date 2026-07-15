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

    @Test(arguments: Self.swapDTOLogPayloads)
    func shouldPreserveSwapDTOLogPayloads(input: String) {
        let actual = LogSanitizer.sanitize(input, policy: .production)
        #expect(actual == input)
    }

    @Test
    func shouldPreserveWalletConnectDeeplink() {
        let input = "Received deeplink: tangem://wc?uri=wc%3Aa4f57e0493f84cfc7168a91579a18c5d9587dd1dd2d40efbe1cd916570399710%402%3FsymKey%3D57285434b30502b8991753225668f667e7c529926f007cec30652861ac11d8a4%26relay-protocol%3Dirn%26methods%3Dpersonal_sign"
        let expected = "Received deeplink: tangem://wc?uri=wc%3Aa4f57e0493f84cfc7168a91579a18c5d9587dd1dd2d40efbe1cd916570399710%402%3FsymKey%\(Self.broadHexRedactPlaceholder)%26relay-protocol%3Dirn%26methods%3Dpersonal_sign"

        let actual = LogSanitizer.sanitize(input, policy: .production)
        #expect(actual == expected)
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
    func shouldPreserveContractAddressesInAccountsTokensPayload() {
        let input = """
        {"id":"usd-coin","networkId":"avalanche","name":"USDC","symbol":"USDC","decimals":6,"contractAddress":"0xaf88d065e77c8cc2239327c5edb3a432268e5831"},
        {"id":"tether","networkId":"ethereum","name":"Tether","symbol":"USDT","decimals":6,"contractAddress":"0xdac17f958d2ee523a2206206994597c13d831ec7"},
        {"id":"usd-coin","networkId":"stellar","contractAddress":"USDC-GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN"}
        """

        let actual = LogSanitizer.sanitize(input, policy: .production)
        #expect(actual == input)
    }

    @Test
    func shouldPreserveContractAddressWhileRedactingSensitiveValuesInSameLog() {
        let input = """
        🟠 request: https://api.tangem.org/wallets/REDACTED/tokens¸
           headers: [
             "card_id": "C91B0000002A7E4F"¸
             "api-key": "kR9vTqLmP4xZc8Hs2NwJfYgD7UaB3eQi6XpMoK1rCzVtEyL5hSnFu0WbAjIGdORXl"¸
             "Content-Type": "application/json"
           ]¸
           body: {"tokens":[{"id":"usd-coin","networkId":"avalanche","contractAddress":"0xaf88d065e77c8cc2239327c5edb3a432268e5831"}]}
        """

        let expected = """
        🟠 request: https://api.tangem.org/wallets/REDACTED/tokens¸
           headers: [
             "card_id": "\(Self.broadHexRedactPlaceholder)"¸
             "api-key": "\(Self.sensitiveKeyRedactPlaceholder)"¸
             "Content-Type": "application/json"
           ]¸
           body: {"tokens":[{"id":"usd-coin","networkId":"avalanche","contractAddress":"0xaf88d065e77c8cc2239327c5edb3a432268e5831"}]}
        """

        let actual = LogSanitizer.sanitize(input, policy: .production)
        #expect(actual == expected)
    }

    @Test
    func shouldPreserveAllContractAddressesInRealisticAccountsResponse() {
        let input = """
        {"wallet":{"version":1,"group":"network","sort":"manual","totalAccounts":1,"totalArchivedAccounts":0},\
        "accounts":[{"id":"0c4d2f1e-ab27-4f88-9c3e-7e1d2a8a8d10","derivation":0,"name":null,"icon":"Star","iconColor":"PalatinateBlue","tokens":[\
        {"id":"bitcoin","networkId":"bitcoin","name":"Bitcoin","symbol":"BTC","decimals":8,"contractAddress":null},\
        {"id":"usd-coin","networkId":"polygon-pos","name":"USDC","symbol":"USDC","decimals":6,"contractAddress":"0x3c499c542cef5e3811e1192ce70d8cc03d5c3359"},\
        {"id":"usd-coin","networkId":"polygon-pos","name":"USDC","symbol":"USDC","decimals":6,"contractAddress":"0xaf88d065e77c8cc2239327c5edb3a432268e5831"},\
        {"id":"usd-coin","networkId":"avalanche","name":"USDC","symbol":"USDC","decimals":6,"contractAddress":"0xb97ef9ef8734c71904d8002f8b6bc66dd9c48a6e"},\
        {"id":"usd-coin","networkId":"avalanche","name":"USDC","symbol":"USDC","decimals":6,"contractAddress":"0xaf88d065e77c8cc2239327c5edb3a432268e5831"},\
        {"id":"usd-coin","networkId":"stellar","name":"USDC","symbol":"USDC","decimals":7,"contractAddress":"USDC-GA5ZSEJYB37JRC5AVCIA5MOP4RHTM335X2KGX3IHOJAPP5RE34K4KZVN"},\
        {"id":"starbro","networkId":"xrp","name":"STARBRO","symbol":"STARBRO","decimals":0,"contractAddress":"5354415242524F00000000000000000000000000.rLfF6rkXsMvNBYosPmwX2kAGQ5oMtab6dW"}\
        ]}]}
        """

        let expected = input.replacingOccurrences(
            of: "0c4d2f1e-ab27-4f88-9c3e-7e1d2a8a8d10",
            with: Self.broadHexRedactPlaceholder
        )

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

extension ProductionLogSanitizerPolicyTests {
    static let expressDTOSwapExchangeStatusResponse = """
    Exchange status response payload:
    "txId": "23b0ba60-8f61-4917-83e7-0464f97f1d55"
    "providerId": "okx-cross-chain"
    "fromAddress": "0x0f0632254b1b45b835e5911E729871667E91BE12"
    "payinAddress": "0x89f423567c2648BB828c3997f60c47b54f57Fa6e"
    "payinExtraId": "0xabcdef0123456789"
    "payoutAddress": "0x0f0632254b1b45b835e5911E729871667E91BE12"
    "refundAddress": "0x0f0632254b1b45b835e5911E729871667E91BE12"
    "refundExtraId": "0xabcdef0123456789"
    "rateType": "float"
    "status": "finished"
    "externalTxId": "8d58d15b-04f4-4631-9a67-b481e3b7c114"
    "externalTxUrl": "https://www.okx.com/web3/dex-swap/0x7cebe3ac2dbfc308da75bd0645274972b021edca82f164f69370d21fad17eb0d"
    "payinHash": "0x7cebe3ac2dbfc308da75bd0645274972b021edca82f164f69370d21fad17eb0d"
    "payoutHash": "0xa3d53ce7f6f9a884d1b9ed62c1f7b872f7d4b2ac51d4276c908e8bb4ce1d3e9f"
    "refundNetwork": "polygon-pos"
    "refundContractAddress": "0xc2132d05d31c914a87c6611c10748aeb04b58e8f"
    "createdAt": "2024-09-19T06:35:22.312Z"
    "updatedAt": "2024-09-19T06:45:22.312Z"
    "payTill": "2024-09-19T07:35:22.312Z"
    "averageDuration": "900.0"
    "fromContractAddress": "0xc2132d05d31c914a87c6611c10748aeb04b58e8f"
    "fromNetwork": "polygon-pos"
    "fromDecimals": "6"
    "fromAmount": "9000000"
    "toContractAddress": "0x2f2a2543b76a4166549f7aab2e75bef0aefc5b0f"
    "toNetwork": "arbitrum-one"
    "toDecimals": "8"
    "toAmount": "14428"
    "toActualAmount": "14420"
    """

    static let decodedTransactionDetails: String = """
    Exchange data decoded transaction details payload:
    "requestId": "23b0ba60-8f61-4917-83e7-0464f97f1d55"
    "txType": "send"
    "txFrom": "0x0f0632254b1b45b835e5911E729871667E91BE12"
    "txTo": "0x89f423567c2648BB828c3997f60c47b54f57Fa6e"
    "txExtraId": "0xabcdef0123456789"
    "txValue": "9000000"
    "otherNativeFee": "nil"
    "gas": "nil"
    "externalTxId": "8d58d15b-04f4-4631-9a67-b481e3b7c114"
    "externalTxUrl": "https://www.okx.com/web3/dex-swap/0x7cebe3ac2dbfc308da75bd0645274972b021edca82f164f69370d21fad17eb0d"
    "payoutAddress": "0x0f0632254b1b45b835e5911E729871667E91BE12"
    "payoutExtraId": "0xabcdef0123456789"
    """

    static let swapDTOLogPayloads = [
        expressDTOSwapExchangeStatusResponse,
        decodedTransactionDetails,
    ]
}
