//
//  TransactionHistoryMapperGaslessTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Testing
import TangemLocalization
@testable import BlockchainSdk
@testable import Tangem

@Suite("TransactionHistoryMapper gasless transaction classification", .serialized)
struct TransactionHistoryMapperGaslessTests {
    private static let walletAddress = "0xWalletAddress"
    private static let feeRecipientAddress = "0xFeeRecipient"
    fileprivate static let gaslessMethodId = "0x6234d42b"

    @Test("Incoming gasless transaction is classified as gaslessTransfer, not gaslessTransactionFee")
    func incomingGaslessTransaction_classifiedAsGaslessTransfer() async {
        await withInjectedStubs {
            let mapper = Self.makeMapper()

            let record = Self.makeGaslessTransactionRecord(
                isOutgoing: false,
                tokenTransferDestination: Self.feeRecipientAddress
            )

            let viewModel = mapper.mapTransactionViewModel(record)
            #expect(viewModel.name == Localization.transactionHistoryOperation)
        }
    }

    @Test("Regular ERC20 transfer is not classified as gasless")
    func regularTransfer_notClassifiedAsGasless() async {
        await withInjectedStubs {
            let mapper = Self.makeMapper()

            let record = TransactionRecord(
                hash: "0xRegularHash",
                index: 0,
                source: .single(.init(address: Self.walletAddress, amount: 50)),
                destination: .single(.init(address: .user("0xReceiverAddress"), amount: 50)),
                fee: Fee(Amount(type: .coin, currencySymbol: "ETH", value: 0.001, decimals: 18)),
                status: .confirmed,
                isOutgoing: true,
                type: .transfer,
                date: Date()
            )

            let viewModel = mapper.mapTransactionViewModel(record)
            #expect(viewModel.name == Localization.commonTransfer)
            #expect(viewModel.name != Localization.gaslessTransactionFee)
            #expect(viewModel.name != Localization.transactionHistoryOperation)
        }
    }

    @Test("Transaction with unknown contract method is not classified as gasless")
    func unknownContractMethod_notClassifiedAsGasless() async {
        await withInjectedStubs {
            let mapper = Self.makeMapper()

            let record = TransactionRecord(
                hash: "0xUnknownHash",
                index: 0,
                source: .single(.init(address: Self.walletAddress, amount: 10)),
                destination: .single(.init(address: .user("0xReceiverAddress"), amount: 10)),
                fee: Fee(Amount(type: .coin, currencySymbol: "ETH", value: 0.001, decimals: 18)),
                status: .confirmed,
                isOutgoing: true,
                type: .contractMethodIdentifier(id: "0xdeadbeef"),
                date: Date(),
                tokenTransfers: [
                    .init(
                        source: Self.walletAddress,
                        destination: Self.feeRecipientAddress,
                        amount: 5,
                        name: "Tether",
                        symbol: "USDT",
                        decimals: 6,
                        contract: "0xdAC17F958D2ee523a2206206994597C13D831ec7"
                    ),
                ]
            )

            let viewModel = mapper.mapTransactionViewModel(record)
            #expect(viewModel.name != Localization.gaslessTransactionFee)
        }
    }

    @Test("Outgoing gasless transaction with fee transfer is classified as gaslessTransactionFee")
    func outgoingGaslessTransactionWithFee_classifiedAsGaslessTransactionFee() async {
        await withInjectedStubs {
            let mapper = Self.makeMapper()

            let record = Self.makeGaslessTransactionRecord(
                isOutgoing: true,
                tokenTransferDestination: Self.feeRecipientAddress
            )

            let viewModel = mapper.mapTransactionViewModel(record)
            #expect(viewModel.name == Localization.gaslessTransactionFee)
        }
    }
}

// MARK: - DI Isolation

/// Serializes access to global `InjectedValues` across suites that mutate gasless-related dependencies.
actor TransactionHistoryMapperTestsDependencyIsolation {
    static let shared = TransactionHistoryMapperTestsDependencyIsolation()

    func run<T>(_ operation: () throws -> T) rethrows -> T {
        try operation()
    }
}

// MARK: - Helpers

private extension TransactionHistoryMapperGaslessTests {
    /// Injects stubs into global DI, runs `operation`, then restores originals.
    /// Uses actor to serialize access across suites + `.serialized` for intra-suite safety.
    func withInjectedStubs(_ operation: () -> Void) async {
        await TransactionHistoryMapperTestsDependencyIsolation.shared.run {
            let previousMethodMapper = InjectedValues[\.smartContractMethodMapper]
            let previousNetworkManager = InjectedValues[\.gaslessTransactionsNetworkManager]

            InjectedValues[\.smartContractMethodMapper] = StubSmartContractMethodMapper()
            InjectedValues[\.gaslessTransactionsNetworkManager] = StubGaslessTransactionsNetworkManager(
                cachedFeeRecipientAddress: Self.feeRecipientAddress
            )

            defer {
                InjectedValues[\.smartContractMethodMapper] = previousMethodMapper
                InjectedValues[\.gaslessTransactionsNetworkManager] = previousNetworkManager
            }

            operation()
        }
    }

    static func makeMapper() -> Tangem.TransactionHistoryMapper {
        Tangem.TransactionHistoryMapper(
            currencySymbol: "USDT",
            walletAddresses: [walletAddress],
            showSign: true,
            isToken: true
        )
    }

    static func makeGaslessTransactionRecord(
        isOutgoing: Bool,
        tokenTransferDestination: String
    ) -> TransactionRecord {
        let source = isOutgoing ? walletAddress : "0xSenderAddress"
        let destination = isOutgoing ? "0xReceiverAddress" : walletAddress

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
            ]
        )
    }
}

// MARK: - Stubs

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
    func initialize() {}
    var feeRecipientAddress: String? { cachedFeeRecipientAddress }
    func preloadFeeRecipientAddress() {}
}
