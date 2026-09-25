//
//  TransactionHistoryMapperGaslessTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import Testing
import TangemFoundation
import TangemLocalization
@testable import BlockchainSdk
@testable import Tangem

@Suite("TransactionHistoryMapper gasless transaction classification", .serialized)
final class TransactionHistoryMapperGaslessTests {
    private static let walletAddress = "0xWalletAddress"
    private static let feeRecipientAddress = "0xFeeRecipient"
    /// One of the collectors the spec names, which the wallet knows without asking the gasless service.
    private static let knownFeeRecipientAddress = "0xFc719364BcCdc92D055d8C3164eF1ab4f5A9182c"
    fileprivate static let gaslessMethodId = "0x6234d42b"
    fileprivate static let yieldSendMethodId = "0x0779afe6"

    private let previousSmartContractMethodMapper: SmartContractMethodMapper
    private let previousGaslessTransactionsNetworkManager: GaslessTransactionsNetworkManager

    init() {
        previousSmartContractMethodMapper = InjectedValues[\.smartContractMethodMapper]
        previousGaslessTransactionsNetworkManager = InjectedValues[\.gaslessTransactionsNetworkManager]

        InjectedValues[\.smartContractMethodMapper] = StubSmartContractMethodMapper()
        InjectedValues[\.gaslessTransactionsNetworkManager] = StubGaslessTransactionsNetworkManager(
            cachedFeeRecipientAddress: Self.feeRecipientAddress
        )
    }

    deinit {
        InjectedValues[\.smartContractMethodMapper] = previousSmartContractMethodMapper
        InjectedValues[\.gaslessTransactionsNetworkManager] = previousGaslessTransactionsNetworkManager
    }

    @Test("Outgoing gasless with fee transfer → gaslessTransactionFee")
    func outgoingGaslessWithFee_classifiedAsTransactionFee() {
        let mapper = makeSUT()
        let record = Self.makeGaslessTransactionRecord(
            isOutgoing: true,
            recordDestination: Self.feeRecipientAddress,
            tokenTransferDestination: Self.feeRecipientAddress
        )
        let viewModel = mapper.mapTransactionViewModel(record)
        #expect(viewModel.name == Localization.gaslessTransactionFee)
    }

    @Test("Incoming gasless → gaslessTransfer (shown as Operation)")
    func incomingGasless_classifiedAsGaslessTransfer() {
        let mapper = makeSUT()
        let record = Self.makeGaslessTransactionRecord(isOutgoing: false, tokenTransferDestination: Self.feeRecipientAddress)
        let viewModel = mapper.mapTransactionViewModel(record)
        #expect(viewModel.name == Localization.transactionHistoryOperation)
    }

    @Test("Outgoing gasless to non-fee address → gaslessTransfer (shown as Operation)")
    func outgoingGaslessToNonFeeAddress_classifiedAsGaslessTransfer() {
        let mapper = makeSUT()
        let record = Self.makeGaslessTransactionRecord(isOutgoing: true, tokenTransferDestination: "0xSomeOtherAddress")
        let viewModel = mapper.mapTransactionViewModel(record)
        #expect(viewModel.name == Localization.transactionHistoryOperation)
    }

    @Test("The collectors named in the spec identify the fee before the gasless service answers")
    func gaslessWithoutFeeRecipient_stillRecognizesKnownCollector() {
        InjectedValues[\.gaslessTransactionsNetworkManager] = StubGaslessTransactionsNetworkManager(
            cachedFeeRecipientAddress: nil
        )

        let mapper = makeSUT()
        let record = Self.makeGaslessTransactionRecord(
            isOutgoing: true,
            recordDestination: Self.knownFeeRecipientAddress,
            tokenTransferDestination: Self.knownFeeRecipientAddress
        )
        let viewModel = mapper.mapTransactionViewModel(record)
        #expect(viewModel.name == Localization.gaslessTransactionFee)
    }

    @Test("Both gasless transaction types exist and are excluded from recipient suggestions")
    func gaslessTypes_existAndAreNeverSuggested() {
        // Compile-time guard: referencing both cases means removing either from
        // `TransactionViewModel.TransactionType` breaks this test.
        _ = [TransactionViewModel.TransactionType.gaslessTransactionFee, .gaslessTransfer]

        let mapper = makeSUT()

        // Outgoing gasless paying the fee → classified as `.gaslessTransactionFee`.
        let feeRecord = Self.makeGaslessTransactionRecord(
            isOutgoing: true,
            recordDestination: Self.feeRecipientAddress,
            tokenTransferDestination: Self.feeRecipientAddress
        )
        #expect(mapper.mapTransactionViewModel(feeRecord).name == Localization.gaslessTransactionFee)
        #expect(mapper.mapSuggestedRecord(feeRecord) == nil)

        // Outgoing gasless transfer → classified as `.gaslessTransfer`. A user-looking destination would
        // otherwise pass the `guard case .user` check, so this proves the type gate is what excludes it.
        let transferRecord = Self.makeGaslessTransactionRecord(
            isOutgoing: true,
            recordDestination: "0xSomeOtherAddress",
            tokenTransferDestination: "0xSomeOtherAddress"
        )
        #expect(mapper.mapTransactionViewModel(transferRecord).name == Localization.transactionHistoryOperation)
        #expect(mapper.mapSuggestedRecord(transferRecord) == nil)
    }

    @Test(
        "Every entry point the executor is reached through pays the fee",
        arguments: ["0x6234d42b", "0x4b072692", "0xf9b181bf", TransactionHistoryMapperGaslessTests.yieldSendMethodId]
    )
    func everyGaslessMethodPayingACollector_classifiedAsTransactionFee(methodId: String) {
        let mapper = makeSUT()
        let record = Self.makeGaslessTransactionRecord(
            isOutgoing: true,
            recordDestination: Self.knownFeeRecipientAddress,
            tokenTransferDestination: Self.knownFeeRecipientAddress,
            methodId: methodId
        )

        #expect(mapper.mapTransactionViewModel(record).name == Localization.gaslessTransactionFee)
    }

    /// `send` is both how the fee leaves the Yield contract and how the wallet moves its own money, so the
    /// address it pays is the only thing that can tell the two apart.
    @Test("A Yield-mode send that pays no collector is no fee")
    func yieldSendToOrdinaryAddress_isNotTransactionFee() {
        let mapper = makeSUT()
        let record = Self.makeGaslessTransactionRecord(
            isOutgoing: true,
            recordDestination: "0xSomeOtherAddress",
            tokenTransferDestination: "0xSomeOtherAddress",
            methodId: Self.yieldSendMethodId
        )

        #expect(mapper.mapTransactionViewModel(record).name != Localization.gaslessTransactionFee)
    }

    /// Android names such a row after the money as well; the executor the transfer went through is plumbing.
    @Test("A gasless transfer is named like any other transfer, while the fee keeps its own name")
    func gaslessTransferIsNamedLikeATransfer() {
        let mapper = makeSUT()
        let incoming = Self.makeGaslessTransactionRecord(isOutgoing: false, tokenTransferDestination: "0xSomeOtherAddress")
        let outgoing = Self.makeGaslessTransactionRecord(
            isOutgoing: true,
            recordDestination: "0xSomeOtherAddress",
            tokenTransferDestination: "0xSomeOtherAddress"
        )
        let fee = Self.makeGaslessTransactionRecord(
            isOutgoing: true,
            recordDestination: Self.knownFeeRecipientAddress,
            tokenTransferDestination: Self.knownFeeRecipientAddress
        )

        #expect(mapper.mapTransactionViewModel(incoming).display.title.fullText == Localization.commonReceived)
        #expect(mapper.mapTransactionViewModel(outgoing).display.title.fullText == Localization.commonSent)
        #expect(mapper.mapTransactionViewModel(fee).display.title.fullText == Localization.commonNetworkFeeTitle)
    }

    @Test("The fee row says what it bought instead of naming the collector")
    func theFeeRowIsSubtitledByWhatItPaidFor() {
        let fee = Self.makeGaslessTransactionRecord(
            isOutgoing: true,
            recordDestination: Self.knownFeeRecipientAddress,
            tokenTransferDestination: Self.knownFeeRecipientAddress
        )

        let subtitle = makeSUT().mapTransactionViewModel(fee).display.subtitle

        #expect(subtitle == .text(Localization.transactionHistoryFeeForSending))
    }

    @Test("A regular outgoing transfer is still suggested as a recipient")
    func regularTransfer_isSuggested() {
        let suggested = makeSUT().mapSuggestedRecord(Self.makeTransferRecord())

        #expect(suggested?.address == "0xReceiverAddress")
    }

    /// A folded row names the balance the wallet ended up with, and the counterparty it shows can be the pool it
    /// swapped through rather than anyone it paid.
    @Test("A folded row is not suggested as a recipient")
    func foldedTransfer_isNotSuggested() {
        #expect(makeSUT().mapSuggestedRecord(Self.makeTransferRecord(isFolded: true)) == nil)
    }

    @Test("Tron gasless compensation transfer stays in the history but is not suggested as a recipient")
    func tronGaslessCompensationTransfer_isNotSuggested() {
        let mapper = makeSUT()
        let record = TransactionRecord(
            hash: "0xCompensationHash",
            index: 0,
            source: .single(.init(address: Self.walletAddress, amount: 1)),
            destination: .single(.init(address: .user("TSWsmaEDgWaE2VsP9tCBGh5GbBRbrdHSuZ"), amount: 1)),
            fee: Fee(Amount(type: .coin, currencySymbol: "TRX", value: 0, decimals: 6)),
            status: .confirmed,
            isOutgoing: true,
            type: .transfer,
            date: Date(),
            tokenTransfers: [],
            nonce: nil
        )
        #expect(mapper.mapSuggestedRecord(record) == nil)

        let historyItems = mapper.mapTransactionListItem(
            from: [record],
            groupingStyle: .day(.short),
            dustFilter: TransactionHistoryDustFilter(usdRate: nil),
            subtitleOwnerResolver: nil
        )
        #expect(historyItems.flatMap(\.items).map(\.hash) == ["0xCompensationHash"])
    }
}

// MARK: - Helpers

private extension TransactionHistoryMapperGaslessTests {
    func makeSUT() -> Tangem.TransactionHistoryMapper {
        Tangem.TransactionHistoryMapper(
            currencySymbol: "USDT",
            blockchain: .ethereum(testnet: false),
            addressesProvider: StubTransactionHistoryAddressesProvider(walletAddresses: [Self.walletAddress]),
            showSign: true,
            isToken: true,
            stakingNetwork: .ethereum
        )
    }

    static func makeTransferRecord(isFolded: Bool = false) -> TransactionRecord {
        TransactionRecord(
            hash: "0xRegularHash",
            index: 0,
            source: .single(.init(address: walletAddress, amount: 10)),
            destination: .single(.init(address: .user("0xReceiverAddress"), amount: 10)),
            fee: Fee(Amount(type: .coin, currencySymbol: "ETH", value: 0, decimals: 18)),
            status: .confirmed,
            isOutgoing: true,
            type: .transfer,
            date: Date(),
            tokenTransfers: [],
            isFolded: isFolded,
            nonce: nil
        )
    }

    static func makeGaslessTransactionRecord(
        isOutgoing: Bool,
        recordDestination: String? = nil,
        tokenTransferDestination: String,
        methodId: String = TransactionHistoryMapperGaslessTests.gaslessMethodId
    ) -> TransactionRecord {
        let source = isOutgoing ? walletAddress : "0xSenderAddress"
        let destination = recordDestination ?? (isOutgoing ? "0xReceiverAddress" : walletAddress)

        return TransactionRecord(
            hash: "0xTestHash",
            index: 0,
            source: .single(.init(address: source, amount: 10)),
            destination: .single(.init(address: .user(destination), amount: 10)),
            fee: Fee(Amount(type: .coin, currencySymbol: "ETH", value: 0, decimals: 18)),
            status: .confirmed,
            isOutgoing: isOutgoing,
            type: .contractMethodIdentifier(id: methodId),
            date: Date(),
            tokenTransfers: [
                .init(
                    source: source,
                    destination: tokenTransferDestination,
                    amount: 7.96,
                    name: "Tether",
                    symbol: "USDT",
                    decimals: 6,
                    contract: "0xdAC17F958D2ee523a2206206994597C13D831ec7"
                ),
            ],
            nonce: nil
        )
    }
}

// MARK: - Stubs

private struct StubTransactionHistoryAddressesProvider: WalletModelTransactionHistoryAddressesProvider {
    let walletAddresses: [String]
}

private final class StubSmartContractMethodMapper: SmartContractMethodMapper {
    /// Mirrors the names the shipped `contract_methods.json` gives the methods these tests use.
    private static let names = [
        TransactionHistoryMapperGaslessTests.gaslessMethodId: "gaslessTransaction",
        TransactionHistoryMapperGaslessTests.yieldSendMethodId: "yieldSend",
        "0x4b072692": "gaslessTransaction",
        "0xf9b181bf": "gaslessTransaction",
    ]

    func getName(for method: String) -> String? {
        Self.names[method]
    }
}

private final class StubGaslessTransactionsNetworkManager: GaslessTransactionsNetworkManager {
    var cachedFeeRecipientAddress: String?

    var availableFeeTokens: [GaslessTransactionsDTO.Response.FeeToken] { [] }
    var availableFeeTokensPublisher: AnyPublisher<[GaslessTransactionsDTO.Response.FeeToken], Never> {
        Just([]).eraseToAnyPublisher()
    }

    var availableTronFeeTokens: [GaslessTransactionsDTO.Response.TronFeeToken] { [] }
    var availableTronFeeTokensPublisher: AnyPublisher<[GaslessTransactionsDTO.Response.TronFeeToken], Never> {
        Just([]).eraseToAnyPublisher()
    }

    var currentHost: String { "" }

    init(cachedFeeRecipientAddress: String?) {
        self.cachedFeeRecipientAddress = cachedFeeRecipientAddress
    }

    func updateAvailableTokens() {}
    func sendGaslessTransaction(
        _ transaction: GaslessTransactionsDTO.Request.GaslessTransaction,
        executorVersion: GaslessExecutorVersion
    ) async throws -> String { "" }
    func sendGaslessBatchTransaction(_ transaction: GaslessTransactionsDTO.Request.GaslessBatchTransaction) async throws -> String { "" }
    func estimateTronGaslessTransaction(
        _ request: GaslessTransactionsDTO.Request.TronEstimate,
        userWalletId: UserWalletId
    ) async throws -> GaslessTransactionsDTO.Response.TronEstimate {
        throw CancellationError()
    }

    func submitTronGaslessTransaction(
        _ request: GaslessTransactionsDTO.Request.TronSubmit,
        userWalletId: UserWalletId
    ) async throws -> GaslessTransactionsDTO.Response.TronSubmit {
        throw CancellationError()
    }

    func initialize() {}
    var feeRecipientAddress: String? { cachedFeeRecipientAddress }
    func preloadFeeRecipientAddress() {}
}
