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

    @Test("Incoming gasless → transfer")
    func incomingGasless_classifiedAsTransfer() {
        let mapper = makeSUT()
        let record = Self.makeGaslessTransactionRecord(isOutgoing: false, tokenTransferDestination: Self.feeRecipientAddress)
        let viewModel = mapper.mapTransactionViewModel(record)
        #expect(viewModel.name == Localization.commonTransfer)
    }

    @Test("Outgoing gasless to non-fee address → transfer")
    func outgoingGaslessToOtherAddress_classifiedAsTransfer() {
        let mapper = makeSUT()
        let record = Self.makeGaslessTransactionRecord(isOutgoing: true, tokenTransferDestination: "0xSomeOtherAddress")
        let viewModel = mapper.mapTransactionViewModel(record)
        #expect(viewModel.name == Localization.commonTransfer)
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
}

// MARK: - Helpers

private extension TransactionHistoryMapperGaslessTests {
    func makeSUT() -> Tangem.TransactionHistoryMapper {
        Tangem.TransactionHistoryMapper(
            currencySymbol: "USDT",
            walletAddresses: [Self.walletAddress],
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
