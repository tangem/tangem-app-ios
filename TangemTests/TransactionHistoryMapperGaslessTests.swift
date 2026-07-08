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
import TangemLocalization
@testable import BlockchainSdk
@testable import Tangem

@Suite("TransactionHistoryMapper gasless transaction classification", .serialized)
final class TransactionHistoryMapperGaslessTests {
    private static let walletAddress = "0xWalletAddress"
    private static let feeRecipientAddress = "0xFeeRecipient"
    fileprivate static let gaslessMethodId = "0x6234d42b"

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

    @Test("Gasless without cached fee recipient → operation")
    func gaslessWithoutFeeRecipient_classifiedAsOperation() {
        InjectedValues[\.gaslessTransactionsNetworkManager] = StubGaslessTransactionsNetworkManager(
            cachedFeeRecipientAddress: nil
        )

        let mapper = makeSUT()
        let record = Self.makeGaslessTransactionRecord(isOutgoing: true, tokenTransferDestination: Self.feeRecipientAddress)
        let viewModel = mapper.mapTransactionViewModel(record)
        #expect(viewModel.name == "gaslessTransaction")
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

    @Test("mapGaslessTransaction only ever returns .operation, .gaslessTransactionFee or .gaslessTransfer")
    func mapGaslessTransaction_returnsOnlyGaslessTypes() {
        func expectGaslessType(_ type: TransactionViewModel.TransactionType, sourceLocation: SourceLocation = #_sourceLocation) {
            switch type {
            case .operation, .gaslessTransactionFee, .gaslessTransfer:
                break
            default:
                Issue.record("mapGaslessTransaction returned a forbidden type: \(type)", sourceLocation: sourceLocation)
            }
        }

        let mapper = makeSUT()

        // Fee payment, plain transfer and incoming branches (fee recipient is cached).
        let cachedFeeRecipientRecords = [
            Self.makeGaslessTransactionRecord(
                isOutgoing: true,
                recordDestination: Self.feeRecipientAddress,
                tokenTransferDestination: Self.feeRecipientAddress
            ),
            Self.makeGaslessTransactionRecord(isOutgoing: true, tokenTransferDestination: "0xSomeOtherAddress"),
            Self.makeGaslessTransactionRecord(isOutgoing: false, tokenTransferDestination: "0xSomeOtherAddress"),
        ]
        for record in cachedFeeRecipientRecords {
            expectGaslessType(mapper.mapGaslessTransaction(contractMethodName: "gaslessTransaction", transactionRecord: record))
        }

        // No cached fee recipient branch.
        InjectedValues[\.gaslessTransactionsNetworkManager] = StubGaslessTransactionsNetworkManager(cachedFeeRecipientAddress: nil)
        let noFeeRecipientMapper = makeSUT()
        let record = Self.makeGaslessTransactionRecord(isOutgoing: true, tokenTransferDestination: "0xSomeOtherAddress")
        expectGaslessType(noFeeRecipientMapper.mapGaslessTransaction(contractMethodName: "gaslessTransaction", transactionRecord: record))
    }

    @Test("A regular outgoing transfer is still suggested as a recipient")
    func regularTransfer_isSuggested() {
        let mapper = makeSUT()
        let record = TransactionRecord(
            hash: "0xRegularHash",
            index: 0,
            source: .single(.init(address: Self.walletAddress, amount: 10)),
            destination: .single(.init(address: .user("0xReceiverAddress"), amount: 10)),
            fee: Fee(Amount(type: .coin, currencySymbol: "ETH", value: 0, decimals: 18)),
            status: .confirmed,
            isOutgoing: true,
            type: .transfer,
            date: Date(),
            tokenTransfers: [],
            nonce: nil
        )
        let suggested = mapper.mapSuggestedRecord(record)
        #expect(suggested?.address == "0xReceiverAddress")
    }
}

// MARK: - Helpers

private extension TransactionHistoryMapperGaslessTests {
    func makeSUT() -> Tangem.TransactionHistoryMapper {
        Tangem.TransactionHistoryMapper(
            currencySymbol: "USDT",
            addressesProvider: StubTransactionHistoryAddressesProvider(walletAddresses: [Self.walletAddress]),
            showSign: true,
            isToken: true
        )
    }

    static func makeGaslessTransactionRecord(
        isOutgoing: Bool,
        recordDestination: String? = nil,
        tokenTransferDestination: String
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
            type: .contractMethodIdentifier(id: gaslessMethodId),
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
    func getName(for method: String) -> String? {
        method == TransactionHistoryMapperGaslessTests.gaslessMethodId ? "gaslessTransaction" : nil
    }
}

private final class StubGaslessTransactionsNetworkManager: GaslessTransactionsNetworkManager {
    var cachedFeeRecipientAddress: String?

    var availableFeeTokens: [GaslessTransactionsDTO.Response.FeeToken] { [] }
    var availableFeeTokensPublisher: AnyPublisher<[GaslessTransactionsDTO.Response.FeeToken], Never> {
        Just([]).eraseToAnyPublisher()
    }

    var currentHost: String { "" }

    init(cachedFeeRecipientAddress: String?) {
        self.cachedFeeRecipientAddress = cachedFeeRecipientAddress
    }

    func updateAvailableTokens() {}
    func sendGaslessTransaction(_ transaction: GaslessTransactionsDTO.Request.GaslessTransaction) async throws -> String { "" }
    func sendGaslessBatchTransaction(_ transaction: GaslessTransactionsDTO.Request.GaslessBatchTransaction) async throws -> String { "" }
    func initialize() {}
    var feeRecipientAddress: String? { cachedFeeRecipientAddress }
    func preloadFeeRecipientAddress() {}
}
