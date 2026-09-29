//
//  TonConnectSendTransactionValidatorTests.swift
//  TangemModules
//
//  Created by Dean Rie
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BigInt
import Foundation
import Testing
import TonSwift
@testable import TangemTonConnect

@Suite(.tags(.tonConnect))
struct TonConnectSendTransactionValidatorTests {
    /// Fixed clock: 2025-11-29T13:50:42Z.
    private static let now = Date(timeIntervalSince1970: 1_764_424_242)
    private static let walletRaw = "0:8a8627861a5dd96c9db3ce0807b122da5ed473934ce7568a5b4b1c361cbb28ae"
    private static var walletAddress: Address { try! Address.parse(walletRaw) }
    /// Same account in user-friendly non-bounceable form (as Tangem displays TON addresses).
    private static var walletFriendly: String { walletAddress.toString(bounceable: false) }

    private static var destination: Address { try! Address.parse("0:66fbe3c5c03bf5c82792f904c9f8bf28894a6aa3d213d41c20569b654aadedb3") }
    private static var destinationBounceable: String { destination.toString(bounceable: true) }
    private static var destinationNonBounceable: String { destination.toString(bounceable: false) }

    private let validator = TonConnectSendTransactionValidator(now: { TonConnectSendTransactionValidatorTests.now })
    private let account = TonConnectWalletAccount(address: TonConnectSendTransactionValidatorTests.walletAddress, network: .mainnet)

    private func payload(
        validUntil: Int64? = 1_764_424_242 + 120,
        network: TonConnectNetworkID? = .mainnet,
        from: String? = nil,
        messages: [TonConnectSendTransactionPayload.Message]? = [.init(address: TonConnectSendTransactionValidatorTests.destinationBounceable, amount: "100000000")],
        hasItems: Bool = false
    ) -> TonConnectSendTransactionPayload {
        TonConnectSendTransactionPayload(validUntil: validUntil, network: network, from: from, messages: messages, hasItems: hasItems)
    }

    // MARK: - Decoding

    @Test
    func decodesSpecExamplePayload() throws {
        let json = #"{"valid_until":1764424242,"network":"-239","from":"Ef8AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADAU","messages":[{"address":"Ef8AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADAU","amount":"100000000"}]}"#

        let payload = try TonConnectSendTransactionPayload.decode(from: Data(json.utf8))

        #expect(payload.validUntil == 1_764_424_242)
        #expect(payload.network == .mainnet)
        #expect(payload.from == "Ef8AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADAU")
        #expect(payload.messages?.count == 1)
        #expect(payload.messages?.first?.amount == "100000000")
        #expect(!payload.hasItems)
    }

    @Test
    func decodesOptionalMessageFieldsAndStringValidUntil() throws {
        let json = #"{"valid_until":"1764424242","messages":[{"address":"a","amount":"1","payload":"te6cc","stateInit":"te6cc","extra_currency":{"239":"5"}}],"items":[{"type":"ton"}]}"#

        let payload = try TonConnectSendTransactionPayload.decode(from: Data(json.utf8))

        #expect(payload.validUntil == 1_764_424_242)
        #expect(payload.messages?.first?.payload == "te6cc")
        #expect(payload.messages?.first?.stateInit == "te6cc")
        #expect(payload.messages?.first?.extraCurrency == ["239": "5"])
        #expect(payload.hasItems)
    }

    @Test
    func decodingRejectsInvalidJSON() {
        #expect(throws: TonConnectError.badRequest("transaction payload is not valid JSON")) {
            try TonConnectSendTransactionPayload.decode(from: Data("[]".utf8))
        }
    }

    // MARK: - Happy path

    @Test
    func acceptsValidPayloadAndExtractsBounceFlags() throws {
        let payloadCell = try Builder().store(uint: 0, bits: 32).writeSnakeString("hello").endCell()
        let payload = payload(
            from: Self.walletFriendly,
            messages: [
                .init(address: Self.destinationBounceable, amount: "100000000", payload: try TonConnectBoc.base64(payloadCell)),
                .init(address: Self.destinationNonBounceable, amount: "1"),
            ]
        )

        let transaction = try validator.validate(payload, for: account)

        #expect(transaction.validUntil == 1_764_424_362)
        #expect(transaction.messages.count == 2)
        #expect(transaction.messages[0].destination == Self.destination)
        #expect(transaction.messages[0].bounce == true)
        #expect(transaction.messages[0].amount == BigUInt(100_000_000))
        #expect(transaction.messages[0].payload == payloadCell)
        #expect(transaction.messages[0].stateInit == nil)
        #expect(transaction.messages[1].bounce == false)
        #expect(transaction.totalAmount == BigUInt(100_000_001))
    }

    @Test
    func acceptsRawAndFriendlyFromForms() throws {
        #expect(throws: Never.self) { try validator.validate(payload(from: Self.walletRaw), for: account) }
        #expect(throws: Never.self) { try validator.validate(payload(from: Self.walletFriendly), for: account) }
        #expect(throws: Never.self) { try validator.validate(payload(from: Self.walletAddress.toString(bounceable: true)), for: account) }
    }

    @Test
    func acceptsMissingOptionalFields() throws {
        let transaction = try validator.validate(payload(validUntil: nil, network: nil, from: nil), for: account)

        #expect(transaction.validUntil == nil)
    }

    @Test
    func acceptsUrlSafeBase64BocAndStateInit() throws {
        let stateInit = try Builder().store(bit: false).store(bit: false).store(bit: false).store(bit: false).store(bit: false).endCell()
        let urlSafe = try TonConnectBoc.base64(stateInit)
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")

        let transaction = try validator.validate(payload(messages: [.init(address: Self.destinationBounceable, amount: "1", stateInit: urlSafe)]), for: account)

        #expect(transaction.messages[0].stateInit == stateInit)
    }

    // MARK: - Rejections

    @Test
    func rejectsItemsAndMixedPayloads() {
        #expect(throws: TonConnectError.badRequest("structured items are not supported by this wallet; send raw messages")) {
            try validator.validate(payload(messages: nil, hasItems: true), for: account)
        }
        #expect(throws: TonConnectError.badRequest("payload must contain either messages or items, not both")) {
            try validator.validate(payload(hasItems: true), for: account)
        }
        #expect(throws: TonConnectError.badRequest("payload must contain messages")) {
            try validator.validate(payload(messages: nil), for: account)
        }
        #expect(throws: TonConnectError.badRequest("messages must not be empty")) {
            try validator.validate(payload(messages: []), for: account)
        }
    }

    @Test
    func rejectsExpiredAndNonPositiveValidUntil() {
        #expect(throws: TonConnectError.badRequest("request expired: valid_until 1764424242 is in the past")) {
            try validator.validate(payload(validUntil: 1_764_424_242), for: account)
        }
        #expect(throws: TonConnectError.badRequest("request expired: valid_until 1 is in the past")) {
            try validator.validate(payload(validUntil: 1), for: account)
        }
        #expect(throws: TonConnectError.badRequest("valid_until must be a positive unix timestamp")) {
            try validator.validate(payload(validUntil: 0), for: account)
        }
        #expect(throws: TonConnectError.badRequest("valid_until must be a positive unix timestamp")) {
            try validator.validate(payload(validUntil: -5), for: account)
        }
    }

    @Test
    func rejectsNetworkMismatchWithExactStringComparison() {
        #expect(throws: TonConnectError.badRequest("network -3 does not match the connected account network -239")) {
            try validator.validate(payload(network: .testnet), for: account)
        }
        #expect(throws: TonConnectError.badRequest("network -0239 does not match the connected account network -239")) {
            try validator.validate(payload(network: TonConnectNetworkID(rawValue: "-0239")), for: account)
        }
    }

    @Test
    func rejectsForeignOrMalformedFrom() {
        #expect(throws: TonConnectError.badRequest("from does not match the connected account")) {
            try validator.validate(payload(from: Self.destinationBounceable), for: account)
        }
        #expect(throws: TonConnectError.badRequest("from is not a valid TON address")) {
            try validator.validate(payload(from: "not-an-address"), for: account)
        }
    }

    @Test
    func rejectsTooManyMessages() {
        let messages = Array(repeating: TonConnectSendTransactionPayload.Message(address: Self.destinationBounceable, amount: "1"), count: 5)

        #expect(throws: TonConnectError.badRequest("too many messages: 5, the wallet supports at most 4")) {
            try validator.validate(payload(messages: messages), for: account)
        }
    }

    @Test
    func rejectsRawDestinationAddresses() {
        #expect(throws: TonConnectError.badRequest("messages[0].address must be in user-friendly format, raw addresses are not allowed")) {
            try validator.validate(payload(messages: [.init(address: Self.destination.toRaw(), amount: "1")]), for: account)
        }
    }

    @Test
    func rejectsInvalidDestinationAddress() {
        var corrupted = Self.destinationBounceable
        corrupted.removeLast()
        corrupted.append(Self.destinationBounceable.last == "A" ? "B" : "A")

        #expect(throws: TonConnectError.badRequest("messages[0].address is not a valid TON address")) {
            try validator.validate(payload(messages: [.init(address: corrupted, amount: "1")]), for: account)
        }
    }

    @Test(arguments: ["", "-1", "1.5", "0x10", "1e9", " 1"])
    func rejectsNonDecimalAmounts(amount: String) {
        #expect(throws: TonConnectError.badRequest("messages[0].amount must be a non-negative decimal string of nanocoins")) {
            try validator.validate(payload(messages: [.init(address: Self.destinationBounceable, amount: amount)]), for: account)
        }
    }

    @Test
    func rejectsAmountsAbove120Bits() {
        let tooLarge = (BigUInt(1) << 120).description
        let maximum = ((BigUInt(1) << 120) - 1).description

        #expect(throws: TonConnectError.badRequest("messages[0].amount exceeds the maximum representable value")) {
            try validator.validate(payload(messages: [.init(address: Self.destinationBounceable, amount: tooLarge)]), for: account)
        }
        #expect(throws: Never.self) {
            try validator.validate(payload(messages: [.init(address: Self.destinationBounceable, amount: maximum)]), for: account)
        }
    }

    @Test
    func rejectsExtraCurrency() {
        #expect(throws: TonConnectError.badRequest("messages[0].extra_currency is not supported by this wallet")) {
            try validator.validate(payload(messages: [.init(address: Self.destinationBounceable, amount: "1", extraCurrency: ["239": "1"])]), for: account)
        }
        #expect(throws: Never.self) {
            try validator.validate(payload(messages: [.init(address: Self.destinationBounceable, amount: "1", extraCurrency: [:])]), for: account)
        }
    }

    @Test
    func rejectsMalformedPayloadAndStateInitBocs() throws {
        #expect(throws: TonConnectError.badRequest("messages[0].payload is not valid base64")) {
            try validator.validate(payload(messages: [.init(address: Self.destinationBounceable, amount: "1", payload: "%%%")]), for: account)
        }
        #expect(throws: TonConnectError.badRequest("messages[0].payload is not a valid BoC: unsupported magic")) {
            try validator.validate(payload(messages: [.init(address: Self.destinationBounceable, amount: "1", payload: Data([1, 2, 3, 4, 5, 6]).base64EncodedString())]), for: account)
        }

        // A structurally valid cell that is not a StateInit (a single "1" bit says "has split_depth" and then runs out of bits).
        let notStateInit = try Builder().store(bit: true).endCell()
        #expect(throws: TonConnectError.badRequest("messages[1].stateInit is not a valid StateInit cell")) {
            try validator.validate(payload(messages: [
                .init(address: Self.destinationBounceable, amount: "1"),
                .init(address: Self.destinationBounceable, amount: "1", stateInit: try TonConnectBoc.base64(notStateInit)),
            ]), for: account)
        }
    }

    @Test
    func rejectsMultiRootAndOversizedBocs() throws {
        let cell = try Builder().store(uint: 1, bits: 8).endCell()
        let single = try cell.toBoc(idx: false, crc32: false)
        // Corrupt the BoC header (root_count byte := 2 with a single cell): parser must not accept it as one root.
        var twoRoots = single
        twoRoots[twoRoots.startIndex + 7] = 2

        #expect(throws: TonConnectError.badRequest("messages[0].payload is not a valid BoC: root count is not 1")) {
            try validator.validate(payload(messages: [.init(address: Self.destinationBounceable, amount: "1", payload: twoRoots.base64EncodedString())]), for: account)
        }

        let oversized = Data(repeating: 0xB5, count: TonConnectBoc.maxSerializedByteCount + 1).base64EncodedString()
        #expect(throws: TonConnectError.badRequest("messages[0].payload exceeds \(TonConnectBoc.maxSerializedByteCount) bytes")) {
            try validator.validate(payload(messages: [.init(address: Self.destinationBounceable, amount: "1", payload: oversized)]), for: account)
        }
    }
}
