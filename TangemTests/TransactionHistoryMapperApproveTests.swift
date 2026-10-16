//
//  TransactionHistoryMapperApproveTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemExpress
@testable import BlockchainSdk
@testable import Tangem

extension TransactionHistoryAuxDataRepositoryDependentTests {
    /// An approve is denominated in the token it grants, which is not the viewed currency when it shows up in the coin
    /// history. Etherscan-like providers (e.g. on Polygon) know nothing about that token, so the mapper finds it by the
    /// contract the approve was sent to.
    @Suite("TransactionHistoryMapper approve amount")
    final class TransactionHistoryMapperApproveTests {
        private static let blockchain = Blockchain.polygon(testnet: false)
        private static let walletAddress = "0x90e4d59c8583e37426b37d1d7394b6008a987c67"
        private static let spender = "0x1231deb6f5749ef6ce6943a275a1d3e7486f4eae"
        /// Mixed-case on purpose: the lookup must normalize it the way the aux data cache keys its tokens.
        private static let usdcContract = "0x3c499c542cEF5E3811e1192ce70d8cC03d5c3359"

        private let auxDataRepository = TransactionHistoryAuxDataRepositoryStub()

        // MARK: - Formatting

        @Test("A limited allowance is denominated in the approved token, with the ticker after the number")
        func limitedAllowanceTakesTokenSymbol() async {
            let viewModel = await withStubbedDependencies { map(makeApproveRecord(symbol: "USDC", allowance: .limited(28))) }
            let formatted = BalanceFormatter().formatDecimal(28)

            #expect(viewModel.amount.currencyCode == "USDC")
            #expect(viewModel.amount.value == formatted)
            #expect(viewModel.amount.amountWithCurrencyCode == "28.00\u{a0}USDC")
        }

        @Test("A revoke of an unresolved token goes without a symbol rather than 'Unknown' or the viewed currency")
        func revokeOfUnresolvedTokenHasNoSymbol() async {
            let viewModel = await withStubbedDependencies { map(makeApproveRecord(symbol: nil, allowance: .revoked)) }

            #expect(viewModel.amount.currencyCode.isEmpty)
            #expect(viewModel.amount.value == BalanceFormatter().formatDecimal(0))
        }

        @Test("An unscaled allowance of an unresolved token shows no amount instead of the transaction's zero coin value")
        func unscaledAllowanceOfUnresolvedTokenHasNoAmount() async {
            let viewModel = await withStubbedDependencies { map(makeApproveRecord(symbol: nil, allowance: .unscaled(1_000_000_000))) }

            #expect(viewModel.transactionType == .approve)
            #expect(viewModel.amount.value.isEmpty)
            #expect(viewModel.amount.currencyCode.isEmpty)
        }

        // MARK: - Approved token lookup

        @Test("A revoke of a token the provider didn't know is denominated in the found token")
        func revokeTakesFoundTokenSymbol() async {
            registerUSDC()

            let viewModel = await withStubbedDependencies { map(makeApproveRecord(symbol: nil, allowance: .revoked)) }

            #expect(viewModel.amount.currencyCode == "USDC")
            #expect(viewModel.amount.value == BalanceFormatter().formatDecimal(0))
        }

        @Test("An unscaled allowance is scaled by the found token's decimals, not the coin's")
        func unscaledAllowanceIsScaledByFoundToken() async {
            registerUSDC()

            let viewModel = await withStubbedDependencies { map(makeApproveRecord(symbol: nil, allowance: .unscaled(1_000_000_000))) }
            let formatted = BalanceFormatter().formatDecimal(1000)

            #expect(viewModel.amount.currencyCode == "USDC")
            #expect(viewModel.amount.value == formatted)
            #expect(viewModel.amount.amountWithCurrencyCode == "1,000.00\u{a0}USDC")
        }

        @Test("An unscaled allowance is scaled even when the provider reported the symbol, keeping that symbol")
        func unscaledAllowanceWithProviderSymbolIsScaled() async {
            registerUSDC()

            let viewModel = await withStubbedDependencies { map(makeApproveRecord(symbol: "USDC.e", allowance: .unscaled(1_000_000_000))) }

            #expect(viewModel.amount.currencyCode == "USDC.e")
            #expect(viewModel.amount.value == BalanceFormatter().formatDecimal(1000))
        }

        @Test("Looks the token up by the normalized destination contract on the viewed network")
        func lookupUsesNormalizedContract() async {
            await withStubbedDependencies { _ = map(makeApproveRecord(symbol: nil, allowance: .revoked)) }

            #expect(auxDataRepository.requestedCurrencies == [Self.usdcCurrency])
        }

        @Test("A complete approve from the provider is formatted as is without a lookup")
        func completeApproveSkipsLookup() async {
            registerUSDC()

            let viewModel = await withStubbedDependencies { map(makeApproveRecord(symbol: "USDT", allowance: .limited(28))) }

            #expect(viewModel.amount.currencyCode == "USDT")
            #expect(auxDataRepository.requestedCurrencies.isEmpty)
        }
    }
}

// MARK: - Helpers

private extension TransactionHistoryAuxDataRepositoryDependentTests.TransactionHistoryMapperApproveTests {
    func withStubbedDependencies<T>(_ operation: () throws -> T) async rethrows -> T {
        try await InjectedDependenciesIsolation.shared.run {
            let previousAuxDataRepository = InjectedValues[\.transactionHistoryAuxDataRepository]
            InjectedValues[\.transactionHistoryAuxDataRepository] = auxDataRepository
            defer { InjectedValues[\.transactionHistoryAuxDataRepository] = previousAuxDataRepository }
            return try operation()
        }
    }

    static var usdcCurrency: ExpressCurrency {
        ExpressCurrency(contractAddress: usdcContract.lowercased(), network: blockchain.networkId)
    }

    func registerUSDC() {
        let token = Token(name: "USD Coin", symbol: "USDC", contractAddress: Self.usdcContract, decimalCount: 6)
        auxDataRepository.register(.token(token, BlockchainNetwork(Self.blockchain, derivationPath: nil)), for: Self.usdcCurrency)
    }

    func map(_ record: TransactionRecord) -> TransactionViewModel {
        let mapper = Tangem.TransactionHistoryMapper(
            currencySymbol: "POL",
            blockchain: Self.blockchain,
            addressesProvider: StubApproveAddressesProvider(walletAddresses: [Self.walletAddress]),
            showSign: true,
            isToken: false,
            stakingNetwork: nil
        )

        return mapper.mapTransactionViewModel(record)
    }

    func makeApproveRecord(
        symbol: String?,
        allowance: TransactionRecord.TransactionType.Approve.Allowance
    ) -> TransactionRecord {
        TransactionRecord(
            hash: "0xhash",
            index: 0,
            source: .single(.init(address: Self.walletAddress, amount: 0)),
            destination: .single(.init(address: .contract(Self.usdcContract), amount: 0)),
            fee: Fee(Amount(with: Self.blockchain, value: 0.01)),
            status: .confirmed,
            isOutgoing: true,
            type: .approve(.init(spender: Self.spender, symbol: symbol, allowance: allowance)),
            date: Date(),
            tokenTransfers: [],
            nonce: nil
        )
    }
}

// MARK: - Stubs

private struct StubApproveAddressesProvider: WalletModelTransactionHistoryAddressesProvider {
    let walletAddresses: [String]
}
