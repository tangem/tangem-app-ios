//
//  TezosTests.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

@testable import BlockchainSdk
import Testing
import CryptoKit
import TangemSdk
import WalletCore

struct TezosTests {
    @Test(arguments: [Configuration.ed25519_slip0010, .secp256k1])
    func correctCoinTransaction(config: Configuration) throws {
        // given
        let transaction = try makeTransaction(publickKey: config.publicKey, curve: config.curve)
        let txBuilder = try makeTXBuilder(pubKey: config.publicKey, curve: config.curve)

        // when
        let contents = txBuilder.buildContents(transaction: transaction)!
        let forged = try txBuilder
            .forgeContents(headerHash: makeTezosHeader().hash, contents: contents)
        let messageToSign = txBuilder.buildToSign(forgedContents: forged)
        let messageToSend = txBuilder.buildToSend(signature: config.signature, forgedContents: forged)

        // then
        #expect(messageToSign?.hexString == config.expectedPlainMessage)
        #expect(messageToSend == config.expectedSignedMessage)
    }

    @Test(arguments: [Configuration.ed25519_slip0010, .secp256k1])
    func testTransactionSize(config: Configuration) throws {
        // given
        let transaction = try makeTransaction(publickKey: config.publicKey, curve: config.curve)
        let txBuilder = try makeTXBuilder(pubKey: config.publicKey, curve: config.curve)

        // when
        let contents = txBuilder.buildContents(transaction: transaction)!
        let forged = try txBuilder
            .forgeContents(headerHash: makeTezosHeader().hash, contents: contents)
        let messageToSign = txBuilder.buildToSign(forgedContents: forged)

        // then
        TransactionSizeTesterUtility().testTxSize(messageToSign)
    }
}

// MARK: - Helpers

extension TezosTests {
    private func makeTXBuilder(pubKey: Data, curve: EllipticCurve) throws -> TezosTransactionBuilder {
        let txBuilder = try TezosTransactionBuilder(walletPublicKey: pubKey, curve: curve)
        txBuilder.isPublicKeyRevealed = false
        txBuilder.counter = 1
        return txBuilder
    }

    private func makeTezosHeader() -> TezosHeader {
        // Obtained from https://rpc.tzbeta.net/chains/main/blocks/head/header (run in Postman)
        TezosHeader(
            protocol: "PsQuebecnLByd3JwTiGadoG4nGWi3HYiLXUjkibeFV8dCFeVMUg",
            hash: "BKjxryQVr7vPJo7dhH8MAxmBu6GjWjx6cTYXQ9Ekq7pjUnfvT6Z"
        )
    }

    private func makeTransaction(publickKey: Data, curve: EllipticCurve) throws -> Transaction {
        let blockchain = Blockchain.tezos(curve: curve)
        let address = try TezosAddressService(curve: curve).makeAddress(
            for: Wallet.PublicKey(seedKey: publickKey, derivationType: .none),
            with: .default
        )

        return Transaction(
            amount: .init(with: blockchain, value: Decimal(stringValue: "0.5")!),
            fee: .init(.init(with: blockchain, value: Decimal(stringValue: "0.001")!)),
            sourceAddress: address.value,
            destinationAddress: "tz1R4PuhxUxBBZhfLJDx2nNjbr7WorAPX1oC", // Random address from explorer
            changeAddress: address.value
        )
    }
}

// MARK: - Configuration

extension TezosTests {
    struct Configuration {
        let curve: EllipticCurve
        let privateKeyForCurve: Data
        let publicKey: Data
        let signature: Data
        let expectedPlainMessage: String
        let expectedSignedMessage: String

        static var ed25519_slip0010: Self {
            let edPrivateKey = try! Curve25519.Signing.PrivateKey(
                rawRepresentation: Data(hexString: "0x85fca134b3fe3fd523d8b528608d803890e26c93c86dc3d97b8d59c7b3540c97")
            )
            let signature = Data(repeating: 0, count: 64)

            return Configuration(
                curve: .ed25519_slip0010,
                privateKeyForCurve: edPrivateKey.rawRepresentation,
                publicKey: edPrivateKey.publicKey.rawRepresentation,
                signature: signature,
                expectedPlainMessage: "7A56CAE5BA005CF622F4A2790FC2D8913F2D6F446B279A4EF5A73E27CE3313F4",
                expectedSignedMessage: "03D16B50C98C184479926792842864AFF680A1DB6F56C02C4C205CE2D32C199B6b0031AF3AE2C74FE58134DFF23B4AC25F8861BA3E4A940a02904e0000E0B3FCCCFE0283CC0F8C105C68B5690AAB8C5C1692A868E55EACA836C87790856c0031AF3AE2C74FE58134DFF23B4AC25F8861BA3E4A8c0b03e852ac02a0c21e00003B7452B5D482D30CC183DA2225AFD72F3E3143230000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
            )
        }

        static var secp256k1: Self {
            let secpPrivateKey = Data(hexString: "83686EF30173D2A05FD7E2C8CB30941534376013B903A2122CF4FF3E8668355A")
            let publicKey = PrivateKey(data: secpPrivateKey)!.getPublicKeySecp256k1(compressed: false).data
            let signature = Data(repeating: 0, count: 64)

            return Configuration(
                curve: .secp256k1,
                privateKeyForCurve: secpPrivateKey,
                publicKey: publicKey,
                signature: signature,
                expectedPlainMessage: "EB5231E6C984EDD9E871B77A1B08E9DA5496889DC18A02AB627DC1614CAD2389",
                expectedSignedMessage: "03D16B50C98C184479926792842864AFF680A1DB6F56C02C4C205CE2D32C199B6b01C8DF602119E8F9F8976F2BE2952271EB67A74147940a02904e00010241DCD64B5F4A039FC339A16300A833A883B218909F2EBCAF3906651C76842C456c01C8DF602119E8F9F8976F2BE2952271EB67A741478c0b03e852ac02a0c21e00003B7452B5D482D30CC183DA2225AFD72F3E3143230000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"
            )
        }
    }
}
