//
//  TransactionHistoryMapperCoinFallbackTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemLocalization
@testable import BlockchainSdk
@testable import Tangem

@Suite(
    "TransactionHistoryMapper coin fallback",
    .enabled(if: FeatureProvider.isAvailable(.transactionHistoryV2))
)
struct TransactionHistoryMapperCoinFallbackTests {
    private static let walletAddress = "0xWalletAddress"
    private static let contractAddress = "0xContractAddress"
    private static let feeValue = Decimal(string: "0.00003936")!

    /// A token transfer and a Yield-module send reach the coin history only because the wallet paid their gas;
    /// a call the wallet cannot name has nothing else to show either.
    @Test(
        "A coin transaction that moved no coin is shown as the fee it cost",
        arguments: [nil, "transfer", "yieldSend"] as [String?]
    )
    func aCoinTransactionThatMovedNoCoinIsTheFee(methodName: String?) {
        let viewModel = makeSUT(isToken: false).mapTransactionViewModel(makeRecord(methodName: methodName))

        #expect(viewModel.display.title.fullText == Localization.commonNetworkFeeTitle)
        #expect(viewModel.display.subtitle == .text(Localization.transactionHistoryFeeForSending))
        #expect(viewModel.amount.amount.hasSuffix(BalanceFormatter().formatCryptoBalance(Self.feeValue, currencyCode: "ETH")))
    }

    /// The aggregator takes its cut of the same token, so the row has to add up everything that left the wallet.
    /// The provider reports the amounts raw, so reading them takes the token's decimals.
    @Test("The fee row says what it paid for when the wallet can name the tokens that moved")
    func theFeeRowNamesWhatItPaidFor() {
        let record = makeRecord(
            methodName: nil,
            tokenTransfers: [
                makeTokenTransfer(from: Self.walletAddress, amount: 262_500),
                makeTokenTransfer(from: Self.walletAddress, amount: 20_737_500),
                makeTokenTransfer(from: "0xRouterAddress", amount: 20_737_500),
            ]
        )

        let viewModel = makeSUT(isToken: false).mapTransactionViewModel(record)
        let sent = BalanceFormatter().formatCryptoBalance(21, currencyCode: "USDT")

        #expect(viewModel.display.subtitle == .text(Localization.commonSend + " " + sent))
    }

    @Test("A transaction that moved several tokens has no single amount to name")
    func severalTokensLeaveTheFeeRowUnnamed() {
        let record = makeRecord(
            methodName: nil,
            tokenTransfers: [
                makeTokenTransfer(from: Self.walletAddress, amount: 262_500),
                makeTokenTransfer(from: Self.walletAddress, amount: 1, contract: "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48"),
            ]
        )

        let viewModel = makeSUT(isToken: false).mapTransactionViewModel(record)

        #expect(viewModel.display.subtitle == .text(Localization.transactionHistoryFeeForSending))
    }

    @Test("The same call on a token screen keeps its operation row")
    func unnamedTokenCallStaysAnOperation() {
        let viewModel = makeSUT(isToken: true).mapTransactionViewModel(makeRecord(methodName: nil))

        #expect(viewModel.display.title.fullText == Localization.transactionHistoryOperation)
    }

    @Test("A coin call the wallet can name keeps that name")
    func namedCoinCallKeepsItsName() {
        let viewModel = makeSUT(isToken: false).mapTransactionViewModel(makeRecord(methodName: "multicall"))

        #expect(viewModel.display.title.fullText == "Multicall")
    }

    /// The coin history names a token transfer a transfer of its own, and the wallet only paid its gas.
    @Test("A token transfer the coin history reports as a transfer is shown as the fee it cost")
    func aTransferTypedRecordIsTheFee() {
        let record = makeRecord(methodName: nil, type: .transfer)

        #expect(makeSUT(isToken: false).mapTransactionViewModel(record).display.title.fullText == Localization.commonNetworkFeeTitle)
    }

    /// An incoming transaction cost the wallet nothing, so its fee is someone else's.
    @Test("An incoming transaction that moved no coin keeps its own row")
    func anIncomingTransactionKeepsItsRow() {
        let record = makeRecord(methodName: nil, isOutgoing: false)

        #expect(makeSUT(isToken: false).mapTransactionViewModel(record).display.title.fullText == Localization.transactionHistoryOperation)
    }

    @Test("A coin call that did move coin keeps its own row")
    func aCallThatMovedCoinKeepsItsRow() {
        let viewModel = makeSUT(isToken: false).mapTransactionViewModel(makeRecord(methodName: nil, amount: 1))

        #expect(viewModel.display.title.fullText == Localization.transactionHistoryOperation)
    }

    // MARK: - Helpers

    private func makeSUT(isToken: Bool) -> Tangem.TransactionHistoryMapper {
        Tangem.TransactionHistoryMapper(
            currencySymbol: "ETH",
            blockchain: .ethereum(testnet: false),
            addressesProvider: StubCoinFallbackAddressesProvider(walletAddresses: [Self.walletAddress]),
            showSign: true,
            isToken: isToken,
            stakingNetwork: nil
        )
    }

    private func makeTokenTransfer(
        from source: String,
        amount: Decimal,
        contract: String = "0xdAC17F958D2ee523a2206206994597C13D831ec7"
    ) -> TransactionRecord.TokenTransfer {
        .init(
            source: source,
            destination: "0xRecipient",
            amount: amount,
            name: "Tether",
            symbol: "USDT",
            decimals: 6,
            contract: contract
        )
    }

    /// The transaction this is modelled on moved nothing the wallet could see and only cost a fee.
    private func makeRecord(
        methodName: String?,
        amount: Decimal = 0,
        isOutgoing: Bool = true,
        type: TransactionRecord.TransactionType? = nil,
        tokenTransfers: [TransactionRecord.TokenTransfer] = []
    ) -> TransactionRecord {
        TransactionRecord(
            hash: "0xHash",
            index: 0,
            source: .single(.init(address: isOutgoing ? Self.walletAddress : Self.contractAddress, amount: amount)),
            destination: .single(.init(
                address: isOutgoing ? .contract(Self.contractAddress) : .user(Self.walletAddress),
                amount: amount
            )),
            fee: Fee(Amount(type: .coin, currencySymbol: "ETH", value: Self.feeValue, decimals: 18)),
            status: .confirmed,
            isOutgoing: isOutgoing,
            type: type ?? .contractMethodName(name: methodName),
            date: Date(),
            tokenTransfers: tokenTransfers,
            nonce: nil
        )
    }
}

// MARK: - Stubs

private struct StubCoinFallbackAddressesProvider: WalletModelTransactionHistoryAddressesProvider {
    let walletAddresses: [String]
}
