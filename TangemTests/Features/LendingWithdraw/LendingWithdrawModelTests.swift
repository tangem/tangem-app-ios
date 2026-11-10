//
//  LendingWithdrawModelTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemFoundation
import TangemTestKit
@testable import BlockchainSdk
@testable import Tangem

@Suite("Lending withdrawal model", .timeLimit(.minutes(1)))
@MainActor
final class LendingWithdrawModelTests: LeakTrackingTestSuite {
    private static let blockchain = Blockchain.ethereum(testnet: false)
    private static let tokenItem = TokenItem.blockchain(.init(blockchain, derivationPath: nil))
    private static let module = "0x1111111111111111111111111111111111111111"
    private static let position = Decimal(2)

    @Test("Available to withdraw is what the liquidity read reports for the position")
    func availableIsCappedByLiquidity() async {
        let (model, _, _) = makeModel(liquidity: .success(Decimal(15) / 10))

        await model.loadAvailableToWithdraw()

        #expect(model.availableToWithdraw == Decimal(string: "1.5"))
    }

    @Test("A failed liquidity read falls back to the position")
    func availableFallsBackToPosition() async {
        let (model, _, _) = makeModel(liquidity: .failure(LendingLiquidityErrorStub()))

        await model.loadAvailableToWithdraw()

        #expect(model.availableToWithdraw == Self.position)
    }

    @Test("A failed liquidity read after one that reported less falls back to the position, not to the older lower amount")
    func failedRereadFallsBackToPosition() async {
        let (model, _, _) = makeModel(liquidity: .success(Decimal(15) / 10), .failure(LendingLiquidityErrorStub()))
        await model.loadAvailableToWithdraw()

        await model.loadAvailableToWithdraw()

        #expect(model.availableToWithdraw == Self.position)
    }

    @Test("The fee is estimated for the exact withdrawal call, with no ETH attached and the yield module gas limit margin")
    func feeInputIsTheWithdrawalCall() throws {
        let (model, manager, _) = makeModel()
        model.sourceAmountDidChanged(amount: amount("0.5"))

        model.updateFees()

        let expectedData = try YieldLendingTransactionProvider.withdrawCallData(.partial(Decimal(5) / 10), blockchain: Self.blockchain, upgradeImplementation: nil)
        let zero = Amount(with: Self.blockchain, type: .coin, value: 0)
        #expect(manager.updateInputCalls.last == .dex(.ethereum(
            amount: zero,
            destination: Self.module,
            txData: expectedData,
            otherNativeFee: nil,
            gasLimitIncreasePercent: EthereumFeeParametersConstants.yieldModuleGasLimitIncreasePercent
        )))
    }

    @Test("Withdraw needs enough ETH to cover the network fee", arguments: [
        (Decimal(2), true),
        (Decimal(1) / 10000, false),
    ])
    func feeCoverage(balance: Decimal, isCovered: Bool) async {
        let (model, _, _) = makeModel(walletBalance: balance)

        let value = await model.isFeeCoveredPublisher.values.first { _ in true }

        #expect(value == isCovered)
    }

    @Test("Withdrawing the whole position deactivates it, a smaller amount withdraws just that, both with no ETH attached", arguments: [
        ("2", YieldLendingTransactionProvider.WithdrawalAmount.all),
        ("0.5", YieldLendingTransactionProvider.WithdrawalAmount.partial(Decimal(5) / 10)),
    ])
    func withdrawCall(entered: String, expected: YieldLendingTransactionProvider.WithdrawalAmount) async throws {
        let (model, _, recorder) = makeModel()
        model.sourceAmountDidChanged(amount: amount(entered))
        model.updateFees()

        _ = try await model.withdraw()

        let transaction = try #require(recorder.dispatchedTransactions.first)
        let expectedData = try YieldLendingTransactionProvider.withdrawCallData(expected, blockchain: Self.blockchain, upgradeImplementation: nil)
        #expect(recorder.dispatchedTransactions.count == 1)
        #expect(transaction.amount.value == 0)
        #expect(transaction.destinationAddress == Self.module)
        #expect((transaction.params as? EthereumTransactionParams)?.data == expectedData)
    }

    @Test("Withdrawing everything available while the Aave liquidity is below the position withdraws just that amount and keeps the position open")
    func maxBelowPositionIsPartial() async throws {
        let (model, _, recorder) = makeModel(liquidity: .success(Decimal(15) / 10))
        await model.loadAvailableToWithdraw()
        model.sourceAmountDidChanged(amount: amount("1.5"))
        model.updateFees()

        _ = try await model.withdraw()

        let transaction = try #require(recorder.dispatchedTransactions.first)
        let expectedData = try YieldLendingTransactionProvider.withdrawCallData(.partial(Decimal(15) / 10), blockchain: Self.blockchain, upgradeImplementation: nil)
        #expect((transaction.params as? EthereumTransactionParams)?.data == expectedData)
    }

    @Test("An amount above what can be withdrawn now is refused before signing, so a withdrawal the module would revert never burns gas")
    func amountAboveAvailableIsRefused() async {
        let (model, _, recorder) = makeModel(liquidity: .success(Decimal(15) / 10))
        await model.loadAvailableToWithdraw()
        model.sourceAmountDidChanged(amount: amount("2"))
        model.updateFees()

        await #expect(throws: TransactionDispatcherResult.Error.self) {
            try await model.withdraw()
        }
        #expect(recorder.dispatchedTransactions.isEmpty)
    }

    @Test("Aave liquidity is read again right before signing, so an amount that fitted on the amount screen but no longer fits is refused")
    func liquidityDropBeforeSigningIsRefused() async {
        let (model, _, recorder) = makeModel(liquidity: .success(2), .success(Decimal(15) / 10))
        await model.loadAvailableToWithdraw()
        model.sourceAmountDidChanged(amount: amount("1.8"))
        model.updateFees()

        await #expect(throws: TransactionDispatcherResult.Error.self) {
            try await model.withdraw()
        }
        #expect(recorder.dispatchedTransactions.isEmpty)
        #expect(model.availableToWithdraw == Decimal(15) / 10)
    }

    @Test("An amount changed after its fee was requested is not signed: the fee has to be estimated for the new call first")
    func amountChangedAfterFee() async {
        let (model, _, recorder) = makeModel()
        model.sourceAmountDidChanged(amount: amount("0.5"))
        model.updateFees()
        model.sourceAmountDidChanged(amount: amount("1"))

        let error = await #expect(throws: TransactionDispatcherResult.Error.self) {
            try await model.withdraw()
        }

        let isFeeRetry = if case .informationRelevanceServiceError = error { true } else { false }
        #expect(isFeeRetry)
        #expect(recorder.dispatchedTransactions.isEmpty)
    }

    @Test("The liquidity read is asked for the position being withdrawn")
    func liquidityIsReadForThePosition() async {
        let liquidity = LendingLiquidityProviderStub(result: .success(Decimal(15) / 10))
        let (model, _, _) = makeModel(liquidityProvider: liquidity)

        await model.loadAvailableToWithdraw()

        #expect(liquidity.positionsRead == [Self.position])
    }

    @Test("The amount screen starts from what the position screen already read, not from the whole position")
    func startsFromKnownAvailable() {
        let (model, _, _) = makeModel(liquidityProvider: nil, availableToWithdraw: Decimal(15) / 10)

        #expect(model.availableToWithdraw == Decimal(15) / 10)
    }

    @Test("A liquidity read that fails right before signing stops the withdrawal instead of capping it at the whole position")
    func failedReadBeforeSigningIsRefused() async {
        let (model, _, recorder) = makeModel(liquidity: .success(2), .failure(LendingLiquidityErrorStub()))
        await model.loadAvailableToWithdraw()
        model.sourceAmountDidChanged(amount: amount("1.8"))
        model.updateFees()

        await #expect(throws: TransactionDispatcherResult.Error.self) {
            try await model.withdraw()
        }
        #expect(recorder.dispatchedTransactions.isEmpty)
    }

    @Test("A fee that went up since it was shown is not signed")
    func increasedFeeIsNotSigned() async {
        let (model, _, recorder) = makeModel(
            liquidityProvider: nil,
            relevance: InformationRelevanceServiceStub(isActual: false, updateResult: .feeWasIncreased)
        )
        model.sourceAmountDidChanged(amount: amount("0.5"))
        model.updateFees()

        let error = await #expect(throws: TransactionDispatcherResult.Error.self) {
            try await model.withdraw()
        }

        let isFeeIncreased = if case .informationRelevanceServiceFeeWasIncreased = error { true } else { false }
        #expect(isFeeIncreased)
        #expect(recorder.dispatchedTransactions.isEmpty)
    }

    @Test("A transaction to the yield module that is still pending stops the next withdrawal before signing")
    func pendingModuleTransactionBlocksWithdrawal() async {
        let (model, _, recorder) = makeModel(liquidityProvider: nil, pending: [pendingTransaction(to: Self.module.uppercased())])
        model.sourceAmountDidChanged(amount: amount("0.5"))
        model.updateFees()

        await #expect(throws: TransactionDispatcherResult.Error.self) {
            try await model.withdraw()
        }
        #expect(recorder.dispatchedTransactions.isEmpty)
    }

    @Test("Pending transactions elsewhere or incoming ones don't stop the withdrawal")
    func unrelatedPendingTransactionsDontBlock() async throws {
        let pending = [
            pendingTransaction(to: "0x3333333333333333333333333333333333333333"),
            pendingTransaction(to: Self.module, isIncoming: true),
        ]
        let (model, _, recorder) = makeModel(liquidityProvider: nil, pending: pending)
        model.sourceAmountDidChanged(amount: amount("0.5"))
        model.updateFees()

        _ = try await model.withdraw()

        #expect(recorder.dispatchedTransactions.count == 1)
    }

    @Test("A fee still loading after the 60-second recheck is not taken as actual, so Withdraw waits for the new fee")
    func loadingFeeIsNotActual() throws {
        let (model, manager, _) = makeModel()
        let feeProvider = try #require(manager.selectedFeeProvider as? ControllableTokenFeeProviderStub)
        #expect(model.isSelectedFeeActual)

        feeProvider.set(selectedTokenFee: TokenFee(option: .market, tokenItem: Self.tokenItem, value: .loading))

        #expect(!model.isSelectedFeeActual)
    }
}

// MARK: - Helpers

private extension LendingWithdrawModelTests {
    func amount(_ value: String) -> SendAmount {
        SendAmount(type: .typical(crypto: Decimal(string: value), fiat: nil))
    }

    func makeToken(
        walletBalance: Decimal = 2,
        manager: TokenFeeProvidersManagerMock? = nil,
        recorder: TransactionRecorder = TransactionRecorder()
    ) -> SendTransferableTokenStub {
        SendTransferableTokenStub(
            blockchain: Self.blockchain,
            transactionCreator: BuildingTransactionCreatorStub(),
            tokenFeeProvidersManager: manager ?? makeFeeManager(),
            balance: walletBalance,
            transactionDispatcherProvider: RecordingTransactionDispatcherProvider(recorder: recorder, error: nil)
        )
    }

    func makeFeeManager() -> TokenFeeProvidersManagerMock {
        let fee = TokenFee(
            option: .market,
            tokenItem: Self.tokenItem,
            value: .success(Fee(Amount(with: Self.blockchain, type: .coin, value: Decimal(1) / 1000)))
        )

        return TokenFeeProvidersManagerMock(feeProvider: ControllableTokenFeeProviderStub(feeTokenItem: Self.tokenItem, selectedTokenFee: fee))
    }

    func makeModel(
        liquidity: Result<Decimal, Error>...,
        walletBalance: Decimal = 2
    ) -> (LendingWithdrawModel, TokenFeeProvidersManagerMock, TransactionRecorder) {
        makeModel(liquidityProvider: liquidity.isEmpty ? nil : LendingLiquidityProviderStub(results: liquidity), walletBalance: walletBalance)
    }

    func makeModel(
        liquidityProvider: LendingLiquidityProviderStub?,
        walletBalance: Decimal = 2,
        availableToWithdraw: Decimal? = nil,
        pending: [PendingTransactionRecord] = [],
        relevance: InformationRelevanceService? = nil
    ) -> (LendingWithdrawModel, TokenFeeProvidersManagerMock, TransactionRecorder) {
        let manager = makeFeeManager()
        let recorder = TransactionRecorder()
        let model = LendingWithdrawModel(
            sourceToken: makeToken(walletBalance: walletBalance, manager: manager, recorder: recorder),
            yieldModule: Self.module,
            upgradeImplementation: nil,
            positionBalance: Self.position,
            availableToWithdraw: availableToWithdraw,
            liquidityProvider: liquidityProvider,
            pendingTransactions: .just(output: pending),
            informationRelevanceService: relevance
        )

        return (trackForMemoryLeaks(model), manager, recorder)
    }

    func pendingTransaction(to destination: String, isIncoming: Bool = false) -> PendingTransactionRecord {
        PendingTransactionRecord(
            hash: "0xPending",
            source: "0x2222222222222222222222222222222222222222",
            destination: destination,
            amount: Amount(with: Self.blockchain, type: .coin, value: 0),
            fee: Fee(Amount(with: Self.blockchain, type: .coin, value: Decimal(1) / 1000)),
            date: Date(),
            isIncoming: isIncoming,
            transactionType: .transfer,
            transactionParams: nil
        )
    }
}
