//
//  WalletConnectHederaRequestParserTests.swift
//  TangemTests
//
//  Created by Dean Rie
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import BlockchainSdk
@testable import Tangem

struct WalletConnectHederaRequestParserTests {
    private let mainnet = Blockchain.hedera(curve: .ed25519_slip0010, testnet: false)
    private let testnet = Blockchain.hedera(curve: .ed25519_slip0010, testnet: true)

    @Test
    func parsesSignerAccountIdWithAndWithoutChecksum() throws {
        #expect(try WalletConnectHederaRequestParser.parseSignerAccountId("hedera:testnet:0.0.12345")
            == .init(network: "testnet", accountId: "0.0.12345"))
        #expect(try WalletConnectHederaRequestParser.parseSignerAccountId("hedera:mainnet:0.0.12345-vfmkw")
            == .init(network: "mainnet", accountId: "0.0.12345"))
        #expect(try WalletConnectHederaRequestParser.parseSignerAccountId("HEDERA:Mainnet:1.2.3")
            == .init(network: "mainnet", accountId: "1.2.3"))
    }

    @Test(arguments: ["0.0.12345", "hedera:0.0.12345", "hedera::0.0.1", "hedera:mainnet:0.0", "hedera:mainnet:0.0.x", "hedera:mainnet:0x1234", "eip155:1:0.0.1", "hedera:mainnet:0.0.1:extra"])
    func rejectsMalformedSignerAccountIds(raw: String) {
        #expect(throws: WalletConnectHederaRequestError.invalidSignerAccountId) {
            try WalletConnectHederaRequestParser.parseSignerAccountId(raw)
        }
    }

    @Test
    func signerMustMatchNetworkAndConnectedAccount() throws {
        let signer = try WalletConnectHederaRequestParser.parseSignerAccountId("hedera:mainnet:0.0.777")

        #expect(throws: Never.self) {
            try WalletConnectHederaRequestParser.validateSigner(signer, accountId: "0.0.777", blockchain: mainnet)
        }
        #expect(throws: WalletConnectHederaRequestError.networkMismatch("mainnet")) {
            try WalletConnectHederaRequestParser.validateSigner(signer, accountId: "0.0.777", blockchain: testnet)
        }
        #expect(throws: WalletConnectHederaRequestError.signerMismatch) {
            try WalletConnectHederaRequestParser.validateSigner(signer, accountId: "0.0.778", blockchain: mainnet)
        }
    }

    @Test
    func decodesBase64WithinBounds() throws {
        #expect(try WalletConnectHederaRequestParser.decodeTransactionBytes("AQID", field: "transactionList") == Data([1, 2, 3]))

        #expect(throws: WalletConnectHederaRequestError.invalidBase64("transactionList")) {
            try WalletConnectHederaRequestParser.decodeTransactionBytes("***", field: "transactionList")
        }
        #expect(throws: WalletConnectHederaRequestError.invalidBase64("transactionBody")) {
            try WalletConnectHederaRequestParser.decodeTransactionBytes("", field: "transactionBody")
        }
        let oversized = Data(repeating: 0, count: WalletConnectHederaRequestParser.maxTransactionByteCount + 1).base64EncodedString()
        #expect(throws: WalletConnectHederaRequestError.tooLarge("transactionList")) {
            try WalletConnectHederaRequestParser.decodeTransactionBytes(oversized, field: "transactionList")
        }
    }

    @Test
    func chainIDsNamespaceAndMethodsAreRegistered() {
        #expect(mainnet.wcChainID == ["mainnet"])
        #expect(testnet.wcChainID == ["testnet"])
        #expect(WalletConnectSupportedNamespace(rawValue: "hedera") == .hedera)
        #expect(WalletConnectMethod(rawValue: "hedera_signAndExecuteTransaction") == .hederaSignAndExecuteTransaction)
        #expect(WalletConnectMethod(rawValue: "hedera_signTransaction") == .hederaSignTransaction)
        #expect(WalletConnectMethod(rawValue: "hedera_signMessage") == .hederaSignMessage)
        #expect(WalletConnectMethod(rawValue: "hedera_getNodeAddresses") == .hederaGetNodeAddresses)
        #expect(WalletConnectMethod.hederaSignAndExecuteTransaction.isSendTransaction)
        #expect(!WalletConnectMethod.hederaSignTransaction.isSendTransaction)
    }

    @Test
    func detailsModelRendersTransfersFeeAndMemo() throws {
        let summary = HederaExternalTransactionSummary(
            transactionType: "TransferTransaction",
            payerAccountId: "0.0.3573746",
            transactionId: "0.0.3573746@1708443033.758181256",
            nodeAccountIds: ["0.0.3", "0.0.6"],
            memo: "wc test",
            maxFeeTinybars: 100_000_000,
            hbarTransfers: [.init(accountId: "0.0.1654", tinybars: 720_000_000), .init(accountId: "0.0.3573746", tinybars: -720_000_000)],
            tokenTransfers: [.init(tokenId: "0.0.456858", accountId: "0.0.1654", amount: 5)]
        )
        let source = try JSONEncoder().encode(WalletConnectHederaTransactionDetails(summary))

        let sections = WCHederaTransactionDetailsModel(for: .hederaSignAndExecuteTransaction, source: source).data
        let items = sections.flatMap { $0.items }.map { ($0.title, $0.value) }

        #expect(items.contains { $0 == ("Transaction", "TransferTransaction") })
        #expect(items.contains { $0 == ("Payer", "0.0.3573746") })
        #expect(items.contains { $0 == ("Nodes", "0.0.3, 0.0.6") })
        #expect(items.contains { $0 == ("Max fee", "1 HBAR") })
        #expect(items.contains { $0 == ("Memo", "wc test") })
        #expect(items.contains { $0 == ("0.0.1654", "+7.2 HBAR") })
        #expect(items.contains { $0 == ("0.0.3573746", "-7.2 HBAR") })
        #expect(items.contains { $0 == ("0.0.456858 → 0.0.1654", "5") })
        #expect(sections.map { $0.sectionTitle } == [nil, "Transaction", "HBAR transfers", "Token transfers"])
        #expect(WCHederaTransactionDetailsModel(for: .hederaSignTransaction, source: Data("nope".utf8)).data.isEmpty)
    }
}
