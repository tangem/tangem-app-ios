//
//  TransactionHistoryMapperInteractionAddressTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import BlockchainSdk
@testable import Tangem

@Suite("TransactionHistoryMapper counterparty")
struct TransactionHistoryMapperInteractionAddressTests {
    private static let walletAddress = "0xWalletAddress"
    private static let sender = "0xSenderAddress"
    private static let contract = "0xContractAddress"

    @Test("An incoming contract call names whoever sent the money, not where the transaction went")
    func incomingContractCallNamesTheSender() {
        let record = makeRecord(isOutgoing: false, source: Self.sender, destination: .user(Self.walletAddress))

        #expect(makeSUT().mapTransactionViewModel(record).interactionAddress == .user(Self.sender))
    }

    @Test("An outgoing contract call still names the contract it was sent to")
    func outgoingContractCallNamesTheContract() {
        let record = makeRecord(isOutgoing: true, source: Self.walletAddress, destination: .contract(Self.contract))

        #expect(makeSUT().mapTransactionViewModel(record).interactionAddress == .contract(Self.contract))
    }

    // MARK: - Helpers

    private func makeSUT() -> Tangem.TransactionHistoryMapper {
        Tangem.TransactionHistoryMapper(
            currencySymbol: "USDC",
            blockchain: .polygon(testnet: false),
            addressesProvider: StubInteractionAddressesProvider(walletAddresses: [Self.walletAddress]),
            showSign: true,
            isToken: true,
            stakingNetwork: nil
        )
    }

    private func makeRecord(
        isOutgoing: Bool,
        source: String,
        destination: TransactionRecord.Destination.Address
    ) -> TransactionRecord {
        TransactionRecord(
            hash: "0xHash",
            index: 0,
            source: .single(.init(address: source, amount: 10)),
            destination: .single(.init(address: destination, amount: 10)),
            fee: Fee(Amount(type: .coin, currencySymbol: "POL", value: 0, decimals: 18)),
            status: .confirmed,
            isOutgoing: isOutgoing,
            type: .contractMethodIdentifier(id: "0xe21fd0e9"),
            date: Date(),
            tokenTransfers: [],
            nonce: nil
        )
    }
}

// MARK: - Stubs

private struct StubInteractionAddressesProvider: WalletModelTransactionHistoryAddressesProvider {
    let walletAddresses: [String]
}
