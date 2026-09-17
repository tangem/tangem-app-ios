//
//  SwapModelDexSwapValidationTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BlockchainSdk
import Foundation
import TangemFoundation
import Testing
@testable import TangemExpress
@testable import Tangem

@Suite("SwapModel DEX swap validation", .timeLimit(.minutes(1)))
struct SwapModelDexSwapValidationTests {
    @Test("A destination that requires a memo blocks the swap")
    func memoRequiredDestinationBlocksTheSwap() async throws {
        let sut = makeSUT(receiveToken: makeReceiveToken(destination: .memoRequiredWithoutTag))

        let state = try await sut.map(provider: makeProvider(), dexPreview: makeDexPreview())

        guard case .restriction(.validationError(error: .destinationMemoRequired), _) = state else {
            Issue.record("Expected the memo restriction, got \(state)")
            return
        }
    }

    @Test("A receive amount below the destination minimum blocks the swap")
    func receiveAmountBelowTheMinimumBlocksTheSwap() async throws {
        let sut = makeSUT(
            receiveToken: makeReceiveToken(restriction: .notEnoughReceivedAmount(minAmount: 5, reason: .receivingMinimum))
        )

        let state = try await sut.map(provider: makeProvider(), dexPreview: makeDexPreview())

        guard case .restriction(.notEnoughReceivedAmount(let minAmount, _, let reason), _) = state else {
            Issue.record("Expected the minimum received amount restriction, got \(state)")
            return
        }

        #expect(minAmount == 5)
        #expect(reason == .receivingMinimum)
    }

    @Test("A destination without a trustline blocks the swap")
    func missingTrustlineBlocksTheSwap() async throws {
        let sut = makeSUT(receiveToken: makeReceiveToken(restriction: .requiresTrustline))

        let state = try await sut.map(provider: makeProvider(), dexPreview: makeDexPreview())

        guard case .restriction(.trustlineRequired, _) = state else {
            Issue.record("Expected the trustline restriction, got \(state)")
            return
        }
    }

    @Test("The DEX preview is validated as a transaction the provider has built")
    func dexPreviewIsValidatedAsAProviderTransaction() async throws {
        let validator = BuilderSpyTransactionValidator()
        let sut = makeSUT(transactionValidator: validator)

        let state = try await sut.map(provider: makeProvider(), dexPreview: makeDexPreview())

        #expect(validator.builders == [.provider])

        guard case .readyToSwap = state else {
            Issue.record("Expected the swap to stay available, got \(state)")
            return
        }
    }

    @Test("Every other swap is validated as our own transaction")
    func everyOtherSwapIsValidatedAsOurOwnTransaction() async throws {
        let validator = BuilderSpyTransactionValidator()
        let sut = makeSUT(transactionValidator: validator)

        _ = try await sut.validate(amount: makeAmount(), fee: makeFee(), quote: makeQuote())

        #expect(validator.builders == [.wallet])
    }

    @Test("A restriction raised by the validator blocks the swap")
    func restrictionFromTheValidatorBlocksTheSwap() async throws {
        let validator = BuilderSpyTransactionValidator(error: ValidationError.totalExceedsBalance)
        let sut = makeSUT(transactionValidator: validator)

        let state = try await sut.map(provider: makeProvider(), dexPreview: makeDexPreview())

        guard case .restriction(.notEnoughBalanceForSwapping, _) = state else {
            Issue.record("Expected the balance restriction, got \(state)")
            return
        }
    }
}

// MARK: - SUT

private extension SwapModelDexSwapValidationTests {
    func makeSUT(
        receiveToken: SendReceiveToken? = nil,
        transactionValidator: SendTransactionValidator = BuilderSpyTransactionValidator()
    ) -> SwapModel {
        SwapModel(
            sourceToken: SwapableTokenStub(
                blockchain: .bitcoin(testnet: false),
                transactionValidator: transactionValidator
            ),
            receiveToken: receiveToken ?? makeReceiveToken(),
            expressManager: ExpressManagerDummy(),
            swapRepository: SwapRepositoryStub(),
            expressPendingTransactionRepository: ExpressPendingTransactionRepositoryStub(),
            expressAPIProvider: ExpressAPIProviderStub(),
            expressUserWalletId: UserWalletId(value: Data()),
            analyticsLogger: SendAnalyticsLoggerStub(),
            autoupdatingTimer: AutoupdatingTimer(),
            pairUpdateHandler: PairUpdateHandlerDummy(),
            balanceRestrictionFeatureChecker: BalanceRestrictionCheckerDummy(),
            shouldStartInitialLoading: false
        )
    }

    func makeReceiveToken(
        restriction: ReceivedRestriction? = nil,
        destination: SendReceiveTokenDestination? = nil
    ) -> SendReceiveToken {
        let tokenItem = TokenItem.accountToken(symbol: "USDT", contract: "0xUSDT")

        // A receive token without a `currencyId` keeps the price impact calculator, which runs before the
        // validation under test, from reaching the quotes repository over the network.
        #expect(tokenItem.currencyId == nil)

        return SwapableTokenStub(
            tokenItem: tokenItem,
            receivingRestriction: restriction,
            destination: destination
        )
    }

    func makeProvider() -> ExpressAvailableProvider {
        ExpressAvailableProviderFixture.make(state: .idle)
    }

    func makeDexPreview() -> ExpressProviderManagerState.DEXPreview {
        ExpressProviderManagerState.DEXPreview(
            provider: makeProvider().provider,
            data: makeTransactionData(),
            fee: makeFee(),
            quote: makeExpressQuote()
        )
    }

    func makeAmount() -> Amount {
        Amount(with: .bitcoin(testnet: false), type: .coin, value: Constants.fromAmount)
    }

    func makeFee() -> Fee {
        Fee(Amount(with: .bitcoin(testnet: false), type: .coin, value: Constants.fee))
    }

    func makeQuote() -> SwapModel.Quote {
        SwapModel.Quote(
            fromAmount: Constants.fromAmount,
            expectAmount: Constants.expectAmount,
            highPriceImpact: nil
        )
    }

    func makeExpressQuote() -> ExpressQuote {
        ExpressQuote(
            fromAmount: Constants.fromAmount,
            expectAmount: Constants.expectAmount,
            allowanceContract: nil,
            quoteId: nil,
            txType: nil,
            isRestricted: false
        )
    }

    func makeTransactionData() -> ExpressTransactionData {
        ExpressTransactionData(
            requestId: "",
            fromAmount: Constants.fromAmount,
            toAmount: Constants.expectAmount,
            expressTransactionId: "",
            transactionType: .swap,
            sourceAddress: nil,
            destinationAddress: "",
            extraDestinationId: nil,
            txValue: Constants.fromAmount,
            txData: "cHNidP8=",
            otherNativeFee: nil,
            estimatedGasLimit: nil,
            externalTxId: nil,
            externalTxURL: nil,
            payInAddress: ""
        )
    }

    enum Constants {
        static let fromAmount: Decimal = 1
        static let expectAmount: Decimal = 2
        static let fee = Decimal(stringValue: "0.0001")!
    }
}

// MARK: - Fixtures

private extension SendReceiveTokenDestination {
    static var memoRequiredWithoutTag: SendReceiveTokenDestination {
        SendReceiveTokenDestination(
            destination: .resolved(address: "address", resolved: "resolved", memoRequired: true),
            destinationTag: nil
        )
    }
}

// MARK: - Stubs

private final class BuilderSpyTransactionValidator: SendTransactionValidator {
    private let error: Error?
    private let state = OSAllocatedUnfairLock(initialState: [SendTransactionBuilder]())

    var builders: [SendTransactionBuilder] { state.withLock { $0 } }

    init(error: Error? = nil) {
        self.error = error
    }

    func validate(amount: Amount) throws {}

    func validate(amount: Amount, fee: Fee) throws {
        try throwIfNeeded()
    }

    func validate(amount: Amount, fee: Fee, builtBy: SendTransactionBuilder) throws {
        state.withLock { $0.append(builtBy) }
        try throwIfNeeded()
    }

    func validate(amount: Amount, fee: Fee, destination: DestinationType) async throws {
        try throwIfNeeded()
    }

    private func throwIfNeeded() throws {
        if let error {
            throw error
        }
    }
}

private actor ExpressManagerDummy: ExpressManager {
    func getCurrentPair() -> ExpressManagerSwappingPair? { nil }
    func getAmountType() -> ExpressAmountType? { nil }
    func update(pair: ExpressManagerSwappingPair?) async throws -> ExpressManagerState { .idle }
    func update(amountType: ExpressAmountType?) async throws -> ExpressManagerState { .idle }
    func update(approvePolicy: ApprovePolicy) async throws -> ExpressManagerState { .idle }
    func updateSelectedProvider(provider: ExpressAvailableProvider) async -> ExpressManagerState { .idle }
    func update(type: ExpressManagerUpdatingType) async -> ExpressManagerState { .idle }

    func requestData() async throws -> ExpressTransactionData {
        fatalError("Unused in tests")
    }
}

private final class PairUpdateHandlerDummy: SwapPairUpdateHandler {
    func updatePairLoadingType(source: SendSwapableToken?, destination: SendReceiveToken?) async -> SwapModel.LoadingType? {
        .providers
    }

    func updatePair(source: SendSwapableToken, destination: SendReceiveToken) async throws -> ExpressManagerState {
        .idle
    }
}

private final class BalanceRestrictionCheckerDummy: SwapBalanceRestrictionFeatureChecker {
    func swapTotalBalanceRestriction(for token: SendSourceToken) async throws -> SwapBalanceRestriction { .none }
}
