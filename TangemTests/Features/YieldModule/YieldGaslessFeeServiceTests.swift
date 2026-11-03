//
//  YieldGaslessFeeServiceTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import Combine
@testable import BlockchainSdk
@testable import Tangem

@Suite("YieldGaslessFeeService")
struct YieldGaslessFeeServiceTests {
    @Test("A gasless fee above the fee token balance is reported as not enough balance")
    func feeAboveBalanceIsNotEnoughBalance() async throws {
        let sut = makeSUT(fee: 5, balance: 3)

        #expect {
            _ = try sut.selectedGaslessFee()
        } throws: { error in
            guard case .notEnoughGaslessFeeBalance(let balance) = error as? TokenFeeProviderError else {
                return false
            }
            return balance == 3
        }

        let publishedFee = try await firstPublishedFee(of: sut)
        guard case .failure(let error) = publishedFee.value else {
            Issue.record("Expected the published fee to fail")
            return
        }
        #expect(error is TokenFeeProviderError)
    }

    @Test("A gasless fee the fee token balance covers is kept")
    func feeWithinBalanceIsKept() async throws {
        let sut = makeSUT(fee: 5, balance: 5)

        let fee = try #require(try sut.selectedGaslessFee())
        #expect(fee.amount.value == 5)

        let publishedFee = try await firstPublishedFee(of: sut)
        #expect(publishedFee.value.value?.amount.value == 5)
    }

    @Test("An excluded fee token leaves the token list and gives the selection back to the coin")
    func excludedFeeTokenIsDropped() async throws {
        let sut = makeSUT(fee: 5, balance: 5)
        let transactionFee = try ExitFee(fees: [BSDKFee(BSDKAmount(with: Self.blockchain, type: .coin, value: 1))])

        await sut.updateFees(for: [transactionFee], excludedFeeTokenItem: Self.feeTokenItem)

        #expect(sut.supportedTokenFeeProviders.map(\.feeTokenItem) == [Self.coinTokenItem])
        #expect(sut.selectedTokenFeeProvider.feeTokenItem == Self.coinTokenItem)
        #expect(try sut.selectedGaslessFee() == nil)
    }
}

private extension YieldGaslessFeeServiceTests {
    static let blockchain = BSDKBlockchain.polygon(testnet: false)
    static let coinTokenItem: TokenItem = .blockchain(.init(blockchain, derivationPath: nil))
    static let feeToken = BSDKToken(
        name: "USDT",
        symbol: "USDT",
        contractAddress: "0x0000000000000000000000000000000000000002",
        decimalCount: 6
    )
    static let feeTokenItem: TokenItem = .token(feeToken, .init(blockchain, derivationPath: nil))

    func makeSUT(fee: Decimal, balance: Decimal) -> YieldGaslessFeeService {
        let gaslessFee = BSDKFee(BSDKAmount(with: Self.blockchain, type: .token(value: Self.feeToken), value: fee))
        let tokenFee = TokenFee(option: .market, tokenItem: Self.feeTokenItem, value: .success(gaslessFee))
        let coinProvider = ControllableTokenFeeProviderStub(
            feeTokenItem: Self.coinTokenItem,
            selectedTokenFee: TokenFee(option: .market, tokenItem: Self.coinTokenItem, value: .loading)
        )
        let tokenProvider = ControllableTokenFeeProviderStub(
            feeTokenItem: Self.feeTokenItem,
            state: .available([.market: gaslessFee]),
            balance: .loaded(balance),
            selectedTokenFee: tokenFee
        )
        let manager = CommonTokenFeeProvidersManager(
            feeProviders: [coinProvider, tokenProvider],
            initialSelectedProvider: tokenProvider,
            ownerAddress: nil
        )

        return YieldGaslessFeeService(
            coinFeeTokenItem: Self.coinTokenItem,
            transactionSender: GaslessBatchTransactionSenderDummy(),
            makeTokenFeeProvidersManager: { manager }
        )
    }

    func firstPublishedFee(of sut: YieldGaslessFeeService) async throws -> TokenFee {
        for await fee in sut.selectedTokenFeePublisher.values {
            return fee
        }

        throw CancellationError()
    }
}

private struct GaslessBatchTransactionSenderDummy: GaslessBatchTransactionSending {
    func send(batch transactions: [BSDKTransaction], fee: BSDKFee) async throws -> TransactionDispatcherResult {
        throw CancellationError()
    }
}
