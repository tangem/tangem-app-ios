//
//  UTXOTransactionHistoryMapperTests.swift
//  BlockchainSdkTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import BlockchainSdk

struct UTXOTransactionHistoryMapperTests {
    private let walletAddress = "DFpN6QqFfUm3gKNaxN6tNcab1FArL9cZLE"
    private let attackerAddress = "D5kTEGxmas71USKAcAaJptKjq8NJc6EK8C"
    private let recipientAddress = "DBHKtAHTwf1nQWDKcX3SnY6L1G4puqadJf"

    @Test("A non-address multisig input containing the wallet address is not outgoing")
    func nonAddressMultisigInputIsNotOutgoing() throws {
        let transaction = makeTransaction(
            vin: [
                makeVin(addresses: [attackerAddress, walletAddress], isAddress: false),
            ]
        )

        let record = try makeSUT(blockchain: .dogecoin).mapToTransactionRecord(
            transaction: transaction,
            walletAddress: [walletAddress]
        )

        #expect(!record.isOutgoing)
    }

    @Test("A single non-address input matching the wallet address is not outgoing")
    func singleNonAddressInputIsNotOutgoing() throws {
        let transaction = makeTransaction(
            vin: [
                makeVin(addresses: [walletAddress], isAddress: false),
            ]
        )

        let record = try makeSUT(blockchain: .dogecoin).mapToTransactionRecord(
            transaction: transaction,
            walletAddress: [walletAddress]
        )

        #expect(!record.isOutgoing)
    }

    @Test("A single address input matching the wallet address is outgoing")
    func singleAddressInputIsOutgoing() throws {
        let transaction = makeTransaction(
            vin: [
                makeVin(addresses: [walletAddress], isAddress: true),
            ]
        )

        let record = try makeSUT(blockchain: .dogecoin).mapToTransactionRecord(
            transaction: transaction,
            walletAddress: [walletAddress]
        )

        #expect(record.isOutgoing)
    }

    @Test("A multi-address input is not outgoing even when marked as an address")
    func multiAddressInputIsNotOutgoing() throws {
        let transaction = makeTransaction(
            vin: [
                makeVin(addresses: [attackerAddress, walletAddress], isAddress: true),
            ]
        )

        let record = try makeSUT(blockchain: .dogecoin).mapToTransactionRecord(
            transaction: transaction,
            walletAddress: [walletAddress]
        )

        #expect(!record.isOutgoing)
    }

    @Test("A non-address multisig input containing a Bitcoin legacy wallet address is not outgoing")
    func nonAddressMultisigInputWithLegacyBitcoinAddressIsNotOutgoing() throws {
        let legacyAddress = "1BgGZ9tcN4rm9KBzDn7KprQz87SZ26SAMH"
        let transaction = makeTransaction(
            vin: [
                makeVin(addresses: ["1AttackerAddress", legacyAddress], isAddress: false),
            ]
        )

        let record = try makeSUT(blockchain: .bitcoin(testnet: false)).mapToTransactionRecord(
            transaction: transaction,
            walletAddress: ["bc1qowner", legacyAddress]
        )

        #expect(!record.isOutgoing)
    }

    @Test("A non-address multisig output is not mapped as a destination")
    func nonAddressMultisigOutputIsNotDestination() throws {
        let transaction = makeTransaction(
            vin: [
                makeVin(addresses: [walletAddress], isAddress: true),
            ],
            vout: [
                makeVout(value: "149900000000", addresses: [walletAddress, attackerAddress], isAddress: false),
                makeVout(value: "1000000", addresses: [walletAddress], isAddress: true),
            ]
        )

        let record = try makeSUT(blockchain: .dogecoin).mapToTransactionRecord(
            transaction: transaction,
            walletAddress: [walletAddress]
        )

        guard case .single(let destination) = record.destination else {
            Issue.record("Expected only the valid single-address output")
            return
        }

        let expectedAmount = try #require(Decimal(stringValue: "0.01"))
        #expect(destination.address.string == walletAddress)
        #expect(destination.amount == expectedAmount)
    }
}

private extension UTXOTransactionHistoryMapperTests {
    func makeSUT(blockchain: Blockchain) -> UTXOTransactionHistoryMapper {
        UTXOTransactionHistoryMapper(blockchain: blockchain)
    }

    func makeTransaction(
        vin: [BlockBookAddressResponse.Vin],
        vout: [BlockBookAddressResponse.Vout]? = nil
    ) -> BlockBookAddressResponse.Transaction {
        BlockBookAddressResponse.Transaction(
            txid: "transaction",
            contractType: nil,
            contractName: nil,
            version: nil,
            vin: vin,
            vout: vout ?? [
                makeVout(value: "149900000000", addresses: [recipientAddress], isAddress: true),
                makeVout(value: "1000000", addresses: [walletAddress], isAddress: true),
            ],
            blockHash: nil,
            blockHeight: 1,
            confirmations: 1,
            blockTime: 1_700_000_000,
            value: "149901000000",
            valueIn: "149902000000",
            fees: "1000000",
            hex: nil,
            tokenTransfers: nil,
            ethereumSpecific: nil,
            chainExtraData: nil,
            tronTXReceipt: nil,
            fromAddress: nil,
            toAddress: nil,
            voteList: nil
        )
    }

    func makeVin(addresses: [String], isAddress: Bool) -> BlockBookAddressResponse.Vin {
        BlockBookAddressResponse.Vin(
            txid: "input",
            sequence: 0,
            n: 0,
            addresses: addresses,
            isAddress: isAddress,
            value: "149902000000",
            hex: nil,
            vout: 0,
            isOwn: nil
        )
    }

    func makeVout(value: String, addresses: [String], isAddress: Bool) -> BlockBookAddressResponse.Vout {
        BlockBookAddressResponse.Vout(
            value: value,
            n: 0,
            hex: nil,
            addresses: addresses,
            isAddress: isAddress,
            spent: nil,
            isOwn: nil
        )
    }
}
