//
//  ExpressPendingTransactionRecordTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import Testing
@testable import Tangem
@testable import BlockchainSdk

@Suite("ExpressPendingTransactionRecord.isRelated")
struct ExpressPendingTransactionRecordTests {
    private let sender = UserWalletId(value: Data([0x01]))
    private let receiver = UserWalletId(value: Data([0x02]))

    private static let network = BlockchainNetwork(.polygon(testnet: false), derivationPath: nil)

    private let polygon = TokenItem.blockchain(network)
    private let usdc = TokenItem.token(
        Token(name: "USD Coin", symbol: "USDC", contractAddress: "0xUSDC", decimalCount: 6),
        network
    )

    @Test("The source wallet matches only the source token, the destination wallet only the destination token")
    func sourceAndDestinationMatching() {
        let record = makeRecord(sourceWallet: sender, destinationWallet: receiver)

        #expect(record.isRelated(to: sender, tokenItem: usdc))
        #expect(record.isRelated(to: receiver, tokenItem: polygon))
        #expect(!record.isRelated(to: sender, tokenItem: polygon))
        #expect(!record.isRelated(to: receiver, tokenItem: usdc))
    }

    @Test("A record without a destination wallet is related to the source wallet only")
    func recordWithoutDestinationWallet() {
        let record = makeRecord(sourceWallet: sender, destinationWallet: nil)

        #expect(record.isRelated(to: sender, tokenItem: polygon))
        #expect(!record.isRelated(to: receiver, tokenItem: polygon))
    }

    @Test("A record without wallets is related to nothing")
    func legacyRecord() {
        let record = makeRecord(sourceWallet: nil, destinationWallet: nil)

        #expect(!record.isRelated(to: sender, tokenItem: usdc))
    }

    @Test("A hidden record is related to nothing")
    func hiddenRecord() {
        let record = makeRecord(sourceWallet: sender, destinationWallet: receiver, isHidden: true)

        #expect(!record.isRelated(to: sender, tokenItem: usdc))
    }

    @Test("A record of a provider without status tracking is related to nothing")
    func providerWithoutStatusTracking() {
        let record = makeRecord(sourceWallet: sender, destinationWallet: receiver, providerType: .unknown)

        #expect(!record.isRelated(to: sender, tokenItem: usdc))
    }
}

// MARK: - Fixtures

private extension ExpressPendingTransactionRecordTests {
    func makeRecord(
        sourceWallet: UserWalletId?,
        destinationWallet: UserWalletId?,
        providerType: ExpressPendingTransactionRecord.ProviderType = .cex,
        isHidden: Bool = false
    ) -> ExpressPendingTransactionRecord {
        ExpressPendingTransactionRecord(
            expressTransactionId: "express_tx_1",
            transactionType: .swap,
            transactionHash: "0xHash",
            expressUserWalletId: sourceWallet?.stringValue,
            sourceTokenTxInfo: .init(
                userWalletId: sourceWallet?.stringValue,
                tokenItem: usdc,
                address: "0xAddress",
                amountString: "100",
                isCustom: false
            ),
            destinationTokenTxInfo: .init(
                userWalletId: destinationWallet?.stringValue,
                tokenItem: polygon,
                address: "0xAddress",
                amountString: "100",
                isCustom: false
            ),
            feeString: "0.1",
            provider: .init(id: "changelly", name: "Changelly", iconURL: nil, type: providerType),
            date: Date(timeIntervalSince1970: 1_700_000_000),
            isHidden: isHidden,
            transactionStatus: .awaitingDeposit
        )
    }
}
