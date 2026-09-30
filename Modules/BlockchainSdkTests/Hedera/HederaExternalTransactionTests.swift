//
//  HederaExternalTransactionTests.swift
//  BlockchainSdkTests
//
//  Created by Dean Rie
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemSdk
import WalletCore
@testable import BlockchainSdk

/// HIP-820 support: decoding dApp-built transaction bytes back into a summary, wrapping bare bodies, and the
/// hand-rolled `SignatureMap` / signed-message encodings.
struct HederaExternalTransactionTests {
    private let blockchain = Blockchain.hedera(curve: .ed25519_slip0010, testnet: true)
    // Any 32-byte EdDSA key: it only ends up as the `pubKeyPrefix` of signature maps in these tests.
    private let publicKey = Data(hexString: "0x4d1bc8bdd0cbe80f5c1fb2a6bd3b0f3d5b2ad9a2d72d8a12a5d6fb3c5f52a3f1")

    private func makeBuilder() -> HederaTransactionBuilder {
        HederaTransactionBuilder(publicKey: publicKey, curve: blockchain.curve, isTestnet: blockchain.isTestnet)
    }

    /// A dApp-built transfer: 7.2 ℏ from 0.0.3573746 to 0.0.1654 with a memo, addressed to nodes 0.0.3 and 0.0.6.
    private func makeTransferBytes(builder: HederaTransactionBuilder) throws -> Data {
        let transaction = Transaction(
            amount: Amount(with: blockchain, type: .coin, value: 7.2),
            fee: Fee(Amount(with: blockchain, value: 1), parameters: HederaFeeParams(additionalHBARFee: .zero, erc20TransferConfiguration: nil)),
            sourceAddress: "0.0.3573746",
            destinationAddress: "0.0.1654",
            changeAddress: "0.0.1654",
            params: HederaTransactionParams(memo: "wc test")
        )
        return try builder.buildTransferTransactionForSign(
            transaction: transaction,
            validStartDate: UnixTimestamp(seconds: 1_708_443_033, nanoseconds: 758_181_256),
            nodeAccountIds: [3, 6]
        ).toBytes()
    }

    @Test
    func decodesTransactionListIntoSummary() throws {
        let builder = makeBuilder()
        let bytes = try makeTransferBytes(builder: builder)

        let summary = try builder.buildCompiledTransaction(fromBytes: bytes).makeSummary()

        #expect(summary.transactionType == "TransferTransaction")
        #expect(summary.payerAccountId == "0.0.3573746")
        #expect(summary.transactionId == "0.0.3573746@1708443033.758181256")
        #expect(summary.nodeAccountIds == ["0.0.3", "0.0.6"])
        #expect(summary.memo == "wc test")
        #expect(summary.maxFeeTinybars == 100_000_000)
        #expect(summary.hbarTransfers == [
            .init(accountId: "0.0.1654", tinybars: 720_000_000),
            .init(accountId: "0.0.3573746", tinybars: -720_000_000),
        ])
        #expect(summary.tokenTransfers.isEmpty)
    }

    @Test
    func decodedTransactionSignsTheSameBodiesAsTheOriginal() throws {
        let builder = makeBuilder()
        let bytes = try makeTransferBytes(builder: builder)

        let original = try builder.buildTransferTransactionForSign(
            transaction: Transaction(
                amount: Amount(with: blockchain, type: .coin, value: 7.2),
                fee: Fee(Amount(with: blockchain, value: 1), parameters: HederaFeeParams(additionalHBARFee: .zero, erc20TransferConfiguration: nil)),
                sourceAddress: "0.0.3573746",
                destinationAddress: "0.0.1654",
                changeAddress: "0.0.1654",
                params: HederaTransactionParams(memo: "wc test")
            ),
            validStartDate: UnixTimestamp(seconds: 1_708_443_033, nanoseconds: 758_181_256),
            nodeAccountIds: [3, 6]
        )
        let decoded = try builder.buildCompiledTransaction(fromBytes: bytes)

        #expect(try decoded.hashesToSign() == original.hashesToSign())
        #expect(try decoded.hashesToSign().count == 2, "one body per node")
    }

    @Test
    func wrappedTransactionBodyDecodesToTheSameSummary() throws {
        let builder = makeBuilder()
        let bytes = try makeTransferBytes(builder: builder)
        let compiled = try builder.buildCompiledTransaction(fromBytes: bytes)
        let bodyBytes = try compiled.hashesToSign()[0] // EdDSA: hashesToSign are the raw body bytes

        let wrapped = try builder.buildCompiledTransaction(fromBytes: HederaProtobufCodec.transaction(wrappingBody: bodyBytes))
        let summary = wrapped.makeSummary()

        #expect(summary.transactionType == "TransferTransaction")
        #expect(summary.nodeAccountIds == ["0.0.3"])
        #expect(summary.hbarTransfers.count == 2)
        #expect(try wrapped.hashesToSign() == [bodyBytes])
    }

    @Test
    func rejectsBytesThatAreNotATransactionList() {
        let builder = makeBuilder()

        #expect(throws: HederaExternalTransactionError.self) {
            try builder.buildCompiledTransaction(fromBytes: Data([0x01, 0x02, 0x03]))
        }
        #expect(throws: HederaExternalTransactionError.self) {
            try builder.buildCompiledTransaction(fromBytes: HederaProtobufCodec.transaction(wrappingBody: Data("nope".utf8)))
        }
    }

    @Test
    func consensusNodesAreKnownForTestnet() {
        let nodes = makeBuilder().consensusNodeAccountIds

        #expect(!nodes.isEmpty)
        #expect(nodes.allSatisfy { $0.hasPrefix("0.0.") })
        #expect(nodes == nodes.sorted())
    }

    // MARK: - Protobuf codec

    @Test
    func signatureMapEncodesEd25519AndEcdsaPairs() {
        let key = Data(repeating: 0x11, count: 32)
        let signature = Data(repeating: 0x22, count: 64)

        let ed25519 = HederaProtobufCodec.signatureMap(publicKey: key, signature: signature, kind: .ed25519)
        // SignatureMap.sigPair (field 1, len 100) { pubKeyPrefix (field 1, len 32) ‖ ed25519 (field 3, len 64) }
        var expected = Data([0x0A, 100, 0x0A, 32])
        expected.append(key)
        expected.append(Data([0x1A, 64]))
        expected.append(signature)
        #expect(ed25519 == expected)

        let ecdsa = HederaProtobufCodec.signatureMap(publicKey: key, signature: signature, kind: .ecdsaSecp256k1)
        var expectedEcdsa = Data([0x0A, 100, 0x0A, 32])
        expectedEcdsa.append(key)
        expectedEcdsa.append(Data([0x32, 64]))
        expectedEcdsa.append(signature)
        #expect(ecdsa == expectedEcdsa)
    }

    @Test
    func transactionWrapperUsesSignedTransactionBytesField() {
        let body = Data([0xAA, 0xBB, 0xCC])

        // Transaction.signedTransactionBytes (field 5) { SignedTransaction.bodyBytes (field 1) }
        let expected = Data([0x2A, 5, 0x0A, 3, 0xAA, 0xBB, 0xCC])
        #expect(HederaProtobufCodec.transaction(wrappingBody: body) == expected)
    }

    @Test
    func signedMessageBytesUseTheReferencePrefixAndUTF16Length() {
        #expect(HederaProtobufCodec.signedMessageBytes("hello") == Data("\u{19}Hedera Signed Message:\n5hello".utf8))
        // `@hashgraph/hedera-wallet-connect` counts JavaScript string length (UTF-16 units): 6, not 12 bytes.
        #expect(HederaProtobufCodec.signedMessageBytes("Привет") == Data("\u{19}Hedera Signed Message:\n6Привет".utf8))
        #expect(HederaProtobufCodec.signedMessageBytes("") == Data("\u{19}Hedera Signed Message:\n0".utf8))
    }

    @Test
    func signatureMapBuilderUsesCurveSpecificPrefixAndHash() throws {
        let ed = HederaTransactionBuilder(publicKey: publicKey, curve: .ed25519_slip0010, isTestnet: true)
        let body = Data("body".utf8)
        #expect(try ed.hashToSign(for: body) == body)
        #expect(try ed.makeSignatureMap(signature: Data(repeating: 1, count: 64)).prefix(4) == Data([0x0A, 100, 0x0A, 32]))

        let secpKey = try #require(PrivateKey(data: Data(repeating: 0x42, count: 32))).getPublicKeyByType(pubkeyType: .init(Blockchain.hedera(curve: .secp256k1, testnet: true))).data
        let ecdsa = HederaTransactionBuilder(publicKey: secpKey, curve: .secp256k1, isTestnet: true)
        #expect(try ecdsa.hashToSign(for: body) == body.sha3(.keccak256))
        let map = try ecdsa.makeSignatureMap(signature: Data(repeating: 1, count: 64))
        #expect(map.prefix(4) == Data([0x0A, 101, 0x0A, 33]), "compressed secp256k1 key as prefix")
        #expect(map[map.startIndex + 4 + 33] == 0x32, "ECDSA_secp256k1 field")
    }
}
