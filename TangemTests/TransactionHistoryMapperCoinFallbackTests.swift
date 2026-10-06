//
//  TransactionHistoryMapperCoinFallbackTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemFoundation
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
    private static var feeValue: Decimal {
        get throws {
            try #require(Decimal(stringValue: "0.00003936"))
        }
    }

    /// A token transfer and a Yield-module call reach the coin history only because the wallet paid their gas;
    /// a call the wallet cannot name has nothing else to show either.
    @Test(
        "A coin transaction that moved no coin is shown as the fee it cost",
        arguments: [
            nil,
            "transfer",
            "yieldSend",
            "yieldDeploy",
            "yieldEnter",
            "yieldInit",
            "yieldWithdraw",
            "yieldReactivate",
            "yieldTopup",
        ] as [String?]
    )
    func aCoinTransactionThatMovedNoCoinIsTheFee(methodName: String?) throws {
        let sut = makeSUT(isToken: false)
        let record = try makeRecord(methodName: methodName)
        let viewModel = sut.mapTransactionViewModel(record)
        let feeValue = try Self.feeValue

        #expect(viewModel.display.title.fullText == Localization.commonNetworkFeeTitle)
        #expect(viewModel.amount.amount.hasSuffix(BalanceFormatter().formatCryptoBalance(feeValue, currencyCode: "ETH")))
        // The details sheet converts this value to fiat, so it has to be the fee too, not the zero transfer.
        #expect(sut.displayedAmountValue(from: record) == feeValue)
    }

    @Test("The fee for a send says it paid for sending", arguments: ["transfer", "yieldSend"])
    func theFeeForASendIsForSending(methodName: String) throws {
        let viewModel = try makeSUT(isToken: false).mapTransactionViewModel(makeRecord(methodName: methodName))

        #expect(viewModel.display.subtitle == .text(Localization.transactionHistoryFeeForSending))
    }

    @Test("The fee for a call the wallet cannot name says it paid for an operation")
    func theFeeForAnUnnamedCallIsForAnOperation() throws {
        let viewModel = try makeSUT(isToken: false).mapTransactionViewModel(makeRecord(methodName: nil))

        #expect(viewModel.display.subtitle == .text(Localization.transactionHistoryFeeForOperation))
    }

    @Test(
        "The fee for a Yield-module call names the Yield mode operation it paid for",
        arguments: [
            ("yieldEnter", Localization.transactionHistoryFeeForYieldModeActivation),
            ("yieldTopup", Localization.transactionHistoryFeeForYieldModeTopUp),
            ("yieldWithdraw", Localization.transactionHistoryFeeForYieldModeDeactivation),
            ("yieldDeploy", Localization.transactionHistoryFeeForYieldModeDeployment),
            ("yieldInit", Localization.transactionHistoryFeeForYieldModeInitialization),
            ("yieldReactivate", Localization.transactionHistoryFeeForYieldModeReactivation),
        ]
    )
    func theFeeForAYieldCallNamesItsOperation(methodName: String, expectedSubtitle: String) throws {
        let viewModel = try makeSUT(isToken: false).mapTransactionViewModel(makeRecord(methodName: methodName))

        #expect(viewModel.display.subtitle == .text(expectedSubtitle))
    }

    /// The aggregator takes its cut of the same token, so the details have to add up everything that left the wallet.
    /// The provider reports the amounts raw, so reading them takes the token's decimals.
    @Test("The fee names the tokens that moved for the details, while the row keeps its plain subtitle")
    func theFeeNamesWhatItPaidFor() throws {
        let record = try makeRecord(
            methodName: nil,
            tokenTransfers: [
                makeTokenTransfer(from: Self.walletAddress, amount: 262_500),
                makeTokenTransfer(from: Self.walletAddress, amount: 20_737_500),
                makeTokenTransfer(from: "0xRouterAddress", amount: 20_737_500),
            ]
        )

        let viewModel = makeSUT(isToken: false).mapTransactionViewModel(record)

        #expect(sentTokens(of: viewModel)?.amount == "21.00\u{a0}USDT")
        #expect(viewModel.display.subtitle == .text(Localization.transactionHistoryFeeForOperation))
    }

    @Test("A transaction that moved several tokens has no single amount to name")
    func severalTokensLeaveTheFeeUnnamed() throws {
        let record = try makeRecord(
            methodName: nil,
            tokenTransfers: [
                makeTokenTransfer(from: Self.walletAddress, amount: 262_500),
                makeTokenTransfer(from: Self.walletAddress, amount: 1, contract: "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48"),
            ]
        )

        let viewModel = makeSUT(isToken: false).mapTransactionViewModel(record)

        #expect(viewModel.transactionType.isNetworkFee)
        #expect(sentTokens(of: viewModel) == nil)
    }

    /// The contract is one no stub registers: this suite reads the process-global aux data repository while the
    /// `TransactionHistoryAuxDataRepositoryDependentTests` ones swap it, and a resolved token brings its own ticker.
    @Test("A fee whose token has an empty ticker names no amount rather than a bare number")
    func emptyTickerLeavesTheFeeUnnamed() throws {
        let record = try makeRecord(
            methodName: nil,
            tokenTransfers: [
                makeTokenTransfer(
                    from: Self.walletAddress,
                    amount: 262_500,
                    symbol: "",
                    contract: "0x000000000000000000000000000000000000dEaD"
                ),
            ]
        )

        let viewModel = makeSUT(isToken: false).mapTransactionViewModel(record)

        #expect(viewModel.transactionType.isNetworkFee)
        #expect(sentTokens(of: viewModel) == nil)
    }

    @Test("The same call on a token screen keeps its operation row")
    func unnamedTokenCallStaysAnOperation() throws {
        let viewModel = try makeSUT(isToken: true).mapTransactionViewModel(makeRecord(methodName: nil))

        #expect(viewModel.display.title.fullText == Localization.transactionHistoryOperation)
    }

    @Test("A coin call the wallet can name keeps that name")
    func namedCoinCallKeepsItsName() throws {
        let viewModel = try makeSUT(isToken: false).mapTransactionViewModel(makeRecord(methodName: "multicall"))

        #expect(viewModel.display.title.fullText == "Multicall")
    }

    /// Staking is available for the coin itself, so its rows stay recognisable instead of turning into a fee.
    @Test(
        "A coin staking call that moved no coin keeps its staking row",
        arguments: [
            ("buyVoucherPOL", TransactionViewModel.TransactionType.stake),
            ("delegate", .stake),
            ("sellVoucher_newPOL", .unstake),
            ("withdrawRewardsPOL", .claimRewards),
        ]
    )
    func stakingCallKeepsItsRow(methodName: String, expectedType: TransactionViewModel.TransactionType) throws {
        let viewModel = try makeSUT(isToken: false).mapTransactionViewModel(makeRecord(methodName: methodName))

        #expect(viewModel.transactionType == expectedType)
    }

    /// A fee row's counterparty is whatever contract the wallet called, so it must never be offered as a recipient.
    @Test(
        "A coin transaction shown as a fee never becomes a recipient suggestion",
        arguments: [
            nil,
            "transfer",
            "yieldSend",
            "yieldDeploy",
            "yieldEnter",
            "yieldInit",
            "yieldWithdraw",
            "yieldReactivate",
            "yieldTopup",
        ] as [String?]
    )
    func aFeeRowIsNeverSuggested(methodName: String?) throws {
        let record = try makeRecord(methodName: methodName, destination: .user(Self.contractAddress))

        #expect(makeSUT(isToken: false).mapSuggestedRecord(record) == nil)
    }

    @Test("A coin transfer that moved coin to a person is still suggested")
    func aCoinTransferToAPersonIsSuggested() throws {
        let record = try makeRecord(methodName: nil, amount: 1, type: .transfer, destination: .user("0xRecipient"))

        #expect(makeSUT(isToken: false).mapSuggestedRecord(record)?.address == "0xRecipient")
    }

    @Test("A zero-value token transfer is not suggested")
    func aZeroValueTokenTransferIsNotSuggested() throws {
        let record = try makeRecord(methodName: nil, type: .transfer, destination: .user("0xRecipient"))

        #expect(makeSUT(isToken: true).mapSuggestedRecord(record) == nil)
    }

    /// The coin history names a token transfer a transfer of its own, and the wallet only paid its gas.
    @Test("A token transfer the coin history reports as a transfer is shown as the fee it cost")
    func aTransferTypedRecordIsTheFee() throws {
        let record = try makeRecord(methodName: nil, type: .transfer)

        #expect(makeSUT(isToken: false).mapTransactionViewModel(record).display.title.fullText == Localization.commonNetworkFeeTitle)
    }

    /// An incoming transaction cost the wallet nothing, so its fee is someone else's.
    @Test("An incoming transaction that moved no coin keeps its own row")
    func anIncomingTransactionKeepsItsRow() throws {
        let record = try makeRecord(methodName: nil, isOutgoing: false)

        #expect(makeSUT(isToken: false).mapTransactionViewModel(record).display.title.fullText == Localization.transactionHistoryOperation)
    }

    @Test("A coin call that did move coin keeps its own row")
    func aCallThatMovedCoinKeepsItsRow() throws {
        let viewModel = try makeSUT(isToken: false).mapTransactionViewModel(makeRecord(methodName: nil, amount: 1))

        #expect(viewModel.display.title.fullText == Localization.transactionHistoryOperation)
    }

    // MARK: - Helpers

    private func sentTokens(of viewModel: TransactionViewModel) -> TransactionViewModel.SentTokens? {
        guard case .networkFee(_, let sent) = viewModel.transactionType else { return nil }
        return sent
    }

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
        symbol: String = "USDT",
        contract: String = "0xdAC17F958D2ee523a2206206994597C13D831ec7"
    ) -> TransactionRecord.TokenTransfer {
        .init(
            source: source,
            destination: "0xRecipient",
            amount: amount,
            name: "Tether",
            symbol: symbol,
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
        destination: TransactionRecord.Destination.Address? = nil,
        tokenTransfers: [TransactionRecord.TokenTransfer] = []
    ) throws -> TransactionRecord {
        try TransactionRecord(
            hash: "0xHash",
            index: 0,
            source: .single(.init(address: isOutgoing ? Self.walletAddress : Self.contractAddress, amount: amount)),
            destination: .single(.init(
                address: destination ?? (isOutgoing ? .contract(Self.contractAddress) : .user(Self.walletAddress)),
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
