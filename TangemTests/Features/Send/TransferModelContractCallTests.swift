//
//  TransferModelContractCallTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import Testing
import TangemFoundation
import TangemTestKit
@testable import BlockchainSdk
@testable import Tangem

@Suite("TransferModel contract call", .timeLimit(.minutes(1)))
final class TransferModelContractCallTests: LeakTrackingTestSuite {
    private static let blockchain = Blockchain.ethereum(testnet: false)
    private static let contract = "0x1111111111111111111111111111111111111111"
    private static let callData = Data([0x09, 0x21, 0xEC, 0xD4])
    private static let fee = Fee(Amount(with: blockchain, type: .coin, value: Decimal(1) / 1000))
    private static let coin = TokenItem.blockchain(.init(blockchain, derivationPath: nil))
    private static let usdt = TokenItem.accountToken(
        symbol: "USDT",
        contract: "0xdAC17F958D2ee523a2206206994597C13D831ec7",
        blockchain: blockchain
    )

    @Test("Without a contract call the fee is estimated for a plain transfer")
    func plainTransferFeeInput() async {
        let (sut, feeManager, _) = makeSUT(contractCall: false, amount: "1")

        sut.updateFees()

        await sut.feeUpdateTask?.value
        await transactionBuilt(sut)
        #expect(feeManager.updateInputCalls == [.common(amount: 1, destination: Self.contract)])
    }

    @Test(
        "A contract call's fee is estimated for the call, valued at no more than half the balance rounded down to whole wei",
        arguments: [("2", "0.5", "0.5"), ("2", "1.8", "1"), ("2.000000000000000001", "1.9", "1")]
    )
    func contractCallFeeInput(balance: String, amount: String, estimatedValue: String) async throws {
        let (sut, feeManager, _) = try makeSUT(amount: amount, balance: #require(Decimal(string: balance)))
        let estimatedAmount = try Amount(with: Self.blockchain, type: .coin, value: #require(Decimal(string: estimatedValue)))

        sut.updateFees()

        await sut.feeUpdateTask?.value
        await transactionBuilt(sut)
        #expect(feeManager.updateInputCalls == [
            .dex(.ethereum(
                amount: estimatedAmount,
                destination: Self.contract,
                txData: Self.callData,
                otherNativeFee: nil,
                gasLimitIncreasePercent: EthereumFeeParametersConstants.yieldModuleGasLimitIncreasePercent
            )),
        ])
    }

    @Test("A contract call is sent to the contract with its calldata and the amount as its value")
    func sendsCall() async throws {
        let (sut, _, recorder) = makeSUT(amount: "0.5")

        _ = try await sut.performAction()

        let sent = try #require(recorder.dispatchedTransactions.last)
        #expect(sent.destinationAddress == Self.contract)
        #expect(sent.amount.value == Decimal(5) / 10)
        #expect((sent.params as? EthereumTransactionParams)?.data == Self.callData)
    }

    @Test("A contract call is never sent from a token, since only the network coin can be the call's value")
    func tokenContractCallIsNotSent() async {
        let (sut, _, recorder) = makeSUT(tokenItem: Self.usdt, amount: "0.5")

        await #expect(throws: (any Error).self) {
            try await sut.performAction()
        }
        #expect(recorder.dispatchedTransactions.isEmpty)
    }

    @Test(
        "A contract call is never sent without at least one wei as its value, so the user can't pay gas for depositing nothing",
        arguments: ["0", "0.0000000000000000001"]
    )
    func contractCallWithoutWholeWeiIsNotSent(amount: String) async {
        let (sut, _, recorder) = makeSUT(amount: amount)

        await #expect(throws: (any Error).self) {
            try await sut.performAction()
        }
        #expect(recorder.dispatchedTransactions.isEmpty)
    }
}

// MARK: - Preparation

extension TransferModelContractCallTests {
    @Test("A call that needs preparing is estimated for both transactions with their simulated gas")
    func preparedCallFeeInput() async {
        let preparation = TransferPreparationSpy(gas: Self.preparationGas)
        let (sut, feeManager, _) = makeSUT(amount: "0.5", preparation: preparation)

        sut.updateFees()
        await sut.feeUpdateTask?.value
        await transactionBuilt(sut)

        #expect(feeManager.updateInputCalls == [.dex(.ethereumEstimate(estimatedGasLimit: 500_000, otherNativeFee: nil))])
        #expect(preparation.gasRequests == [TransferPreparationCall(destination: Self.contract, value: Decimal(5) / 10, data: Self.callData)])
    }

    @Test("A call that needs preparing is simulated with half a balance ending in an odd wei rounded to whole wei")
    func preparedCallHalfOfOddWeiBalance() async throws {
        let balance = try #require(Decimal(string: "0.123456789012345677"))
        let preparation = TransferPreparationSpy(gas: Self.preparationGas)
        let (sut, _, _) = makeSUT(amount: "0.1", balance: balance, preparation: preparation)

        sut.updateFees()
        await sut.feeUpdateTask?.value
        await transactionBuilt(sut)

        let value = try #require(preparation.gasRequests.first?.value)
        #expect(value == (balance / 2).rounded(scale: Self.blockchain.decimalCount))
        #expect(Amount(with: Self.blockchain, type: .coin, value: value).encodedForSend != nil)
    }

    @Test("A preparation whose simulation reverts shows the fee as unavailable, keeps sending off and sends nothing")
    func revertedPreparation() async {
        let preparation = TransferPreparationSpy(gas: nil)
        let (sut, feeManager, recorder) = makeSUT(amount: "0.5", preparation: preparation)

        sut.updateFees()
        await sut.feeUpdateTask?.value

        let isFeeUnavailable = if case .failure = sut.selectedFee?.value { true } else { false }
        let isReadyToSend = await sut.isReadyToSendPublisher.values.first { _ in true }
        #expect(isFeeUnavailable)
        #expect(isReadyToSend == false)
        #expect(feeManager.updateInputCalls.isEmpty)
        await #expect(throws: (any Error).self) {
            try await sut.performAction()
        }
        #expect(preparation.sent.isEmpty)
        #expect(recorder.dispatchedTransactions.isEmpty)
        await sut.transactionBuildTask?.value
    }

    @Test("A preparation that simulates again after a revert brings the fee back")
    func preparationRecoversAfterRevert() async {
        let preparation = TransferPreparationSpy(gases: [nil, Self.preparationGas])
        let (sut, _, _) = makeSUT(amount: "0.5", preparation: preparation)
        sut.updateFees()
        await sut.feeUpdateTask?.value

        sut.updateFees()
        await sut.feeUpdateTask?.value

        let isFeeLoaded = if case .success = sut.selectedFee?.value { true } else { false }
        #expect(isFeeLoaded)
        await sut.transactionBuildTask?.value
    }

    @Test("A prepared call is sent through its preparation, not the plain dispatcher")
    func preparedCallIsSentWithPreparation() async throws {
        let preparation = TransferPreparationSpy(gas: Self.preparationGas)
        let (sut, _, recorder) = makeSUT(amount: "0.5", preparation: preparation)
        sut.updateFees()
        await sut.feeUpdateTask?.value

        _ = try await sut.performAction()

        #expect(recorder.dispatchedTransactions.isEmpty)
        #expect(preparation.sent.map(\.transaction.destinationAddress) == [Self.contract])
        #expect(preparation.sent.map(\.gas) == [Self.preparationGas])
    }

    @Test("A prepared call sent while the gas for a new amount is being estimated waits for the fee of that gas and goes out with both")
    func preparedCallWaitsForNewAmountGas() async throws {
        let newGas = TransferPreparationGas(preparation: 210_000, mainCall: 310_000)
        let newFee = Fee(Amount(with: Self.blockchain, type: .coin, value: Decimal(2) / 1000))
        let entered = TestGate()
        let release = TestGate()
        let preparation = TransferPreparationSpy(gases: [Self.preparationGas, newGas], entered: entered, release: release)
        let (sut, feeManager, _) = makeSUT(amount: "0.5", preparation: preparation)
        let feeProvider = try #require(feeManager.selectedFeeProvider as? ControllableTokenFeeProviderStub)
        sut.updateFees()
        await sut.feeUpdateTask?.value

        let feeUpdate = TestGate()
        feeManager.updateFeesGate = feeUpdate
        sut.sourceAmountDidChanged(amount: SendAmount(type: .typical(crypto: Decimal(8) / 10, fiat: nil)))
        sut.updateFees()
        await entered.wait()
        let sending = Task { try await sut.performAction() }
        release.open()
        feeProvider.set(selectedTokenFee: TokenFee(option: .market, tokenItem: Self.coin, value: .success(newFee)))
        feeUpdate.open()
        _ = try await sending.value
        await sut.feeUpdateTask?.value
        await sut.transactionBuildTask?.value

        #expect(preparation.sent.map(\.gas) == [newGas])
        #expect(preparation.sent.map(\.transaction.fee.amount.value) == [newFee.amount.value])
    }

    @Test("While the gas for a new amount is simulated the fee shows as loading and sending stays off")
    func feeLoadsWhileSimulating() async {
        let entered = TestGate()
        let release = TestGate()
        let preparation = TransferPreparationSpy(gases: [Self.preparationGas], entered: entered, release: release)
        let (sut, _, _) = makeSUT(amount: "0.5", preparation: preparation)
        sut.updateFees()
        await sut.feeUpdateTask?.value
        await sut.transactionBuildTask?.value

        sut.updateFees()
        await entered.wait()
        let isFeeLoading = sut.selectedFee?.value.isLoading == true
        let isReadyToSend = await sut.isReadyToSendPublisher.values.first { _ in true }
        release.open()
        await sut.feeUpdateTask?.value
        await sut.transactionBuildTask?.value

        #expect(isFeeLoading)
        #expect(isReadyToSend == false)
    }

    @Test("A fee re-estimate shows the fee as loading until the fee for the new gas arrives, so a re-check never compares the old fee with itself")
    func feeRecheckSeesNewFee() async throws {
        let preparation = TransferPreparationSpy(gas: Self.preparationGas)
        let (sut, feeManager, _) = makeSUT(amount: "0.5", preparation: preparation)
        let feeProvider = try #require(feeManager.selectedFeeProvider as? ControllableTokenFeeProviderStub)
        sut.updateFees()
        await sut.feeUpdateTask?.value
        await sut.transactionBuildTask?.value

        let feeUpdateStarted = TestGate()
        let feeUpdate = TestGate()
        feeManager.updateFeesStarted = feeUpdateStarted
        feeManager.updateFeesGate = feeUpdate
        let (fees, continuation) = AsyncStream.makeStream(of: TokenFee.self)
        let subscription = sut.selectedFeePublisher.dropFirst().sink { continuation.yield($0) }

        sut.updateFees()
        await feeUpdateStarted.wait()
        let higherFee = Fee(Amount(with: Self.blockchain, type: .coin, value: Decimal(2) / 1000))
        feeProvider.set(selectedTokenFee: TokenFee(option: .market, tokenItem: Self.coin, value: .success(higherFee)))
        feeUpdate.open()

        var iterator = fees.makeAsyncIterator()
        var firstLoadedFee: TokenFee?
        while firstLoadedFee == nil, let fee = await iterator.next() {
            firstLoadedFee = fee.value.isLoading ? nil : fee
        }
        subscription.cancel()
        await sut.feeUpdateTask?.value
        await sut.transactionBuildTask?.value

        #expect(firstLoadedFee?.value.value?.amount.value == higherFee.amount.value)
    }

    @Test("A new estimate cancels the simulation it replaces")
    func supersededSimulationIsCancelled() async {
        let entered = TestGate()
        let release = TestGate()
        let preparation = TransferPreparationSpy(gases: [Self.preparationGas], entered: entered, release: release)
        let (sut, _, _) = makeSUT(amount: "0.5", preparation: preparation)
        sut.updateFees()
        await sut.feeUpdateTask?.value

        sut.updateFees()
        let supersededUpdate = sut.feeUpdateTask
        await entered.wait()
        sut.updateFees()
        release.open()
        await supersededUpdate?.value
        await sut.feeUpdateTask?.value
        await sut.transactionBuildTask?.value

        #expect(preparation.cancelledRequests == 1)
    }

    @Test("A prepared call is never sent alone before its gas is known")
    func preparedCallWithoutGasIsNotSent() async {
        let preparation = TransferPreparationSpy(gas: Self.preparationGas)
        let (sut, _, recorder) = makeSUT(amount: "0.5", preparation: preparation)

        await #expect(throws: (any Error).self) {
            try await sut.performAction()
        }
        await sut.transactionBuildTask?.value

        #expect(recorder.dispatchedTransactions.isEmpty)
        #expect(preparation.sent.isEmpty)
    }
}

// MARK: - Helpers

private extension TransferModelContractCallTests {
    static let preparationGas = TransferPreparationGas(preparation: 200_000, mainCall: 300_000)

    func transactionBuilt(_ sut: TransferModel) async {
        _ = await sut.bsdkTransactionResultPublisher.values.first { $0 != nil }
        await sut.transactionBuildTask?.value
    }

    func makeSUT(
        tokenItem: TokenItem? = nil,
        contractCall: Bool = true,
        amount: String? = nil,
        balance: Decimal = 2,
        preparation: TransferPreparation? = nil
    ) -> (TransferModel, TokenFeeProvidersManagerMock, TransactionRecorder) {
        let feeProvider = ControllableTokenFeeProviderStub(
            feeTokenItem: Self.coin,
            selectedTokenFee: TokenFee(option: .market, tokenItem: Self.coin, value: .success(Self.fee))
        )
        let feeManager = TokenFeeProvidersManagerMock(feeProvider: feeProvider)
        let recorder = TransactionRecorder()

        let sut = TransferModel(
            userWalletId: UserWalletId(value: Data([0x01])),
            userToken: ContractCallTokenStub(
                tokenItem: tokenItem ?? Self.coin,
                balance: balance,
                tokenFeeProvidersManager: feeManager,
                recorder: recorder
            ),
            transactionSigner: TangemSignerStub(),
            feeIncludedCalculator: FeeIncludedCalculatorStub(),
            analyticsLogger: SendManagementModelAnalyticsLoggerStub(),
            sendAlertBuilder: CommonSendAlertBuilder(),
            predefinedValues: TransferModel.PredefinedValues(
                destination: SendDestination(value: .plain(Self.contract), source: .textField),
                amount: amount.flatMap { Decimal(string: $0) }.map { SendAmount(type: .typical(crypto: $0, fiat: nil)) },
                contractCallData: contractCall ? Self.callData : nil,
                preparation: preparation
            )
        )
        sut.informationRelevanceService = InformationRelevanceServiceStub()

        return (trackForMemoryLeaks(sut), feeManager, recorder)
    }
}

// MARK: - Stubs

private final class ContractCallTokenStub: SendSourceTokenStub, SendTransferableToken {
    let transactionValidator: SendTransactionValidator = SendTransactionValidatorStub()
    let transactionCreator: SendTransactionCreator = BuildingTransactionCreatorStub()
    let tokenFeeProvidersManager: TokenFeeProvidersManager

    private let balance: Decimal
    private let recorder: TransactionRecorder

    init(tokenItem: TokenItem, balance: Decimal, tokenFeeProvidersManager: TokenFeeProvidersManager, recorder: TransactionRecorder) {
        self.balance = balance
        self.tokenFeeProvidersManager = tokenFeeProvidersManager
        self.recorder = recorder
        super.init(tokenItem: tokenItem)
    }

    override var availableBalanceProvider: TokenBalanceProvider {
        TokenBalanceProviderStub(balanceType: .loaded(balance))
    }

    override var transactionDispatcherProvider: any TransactionDispatcherProvider {
        RecordingTransactionDispatcherProvider(recorder: recorder)
    }
}

private final class TransferPreparationSpy: TransferPreparation {
    private let state = OSAllocatedUnfairLock(
        initialState: (gasRequests: [TransferPreparationCall](), cancelledRequests: 0, sent: [(transaction: BSDKTransaction, gas: TransferPreparationGas)]())
    )
    private let gases: [TransferPreparationGas?]
    private let entered: TestGate?
    private let release: TestGate?

    var gasRequests: [TransferPreparationCall] {
        state.withLock { $0.gasRequests }
    }

    var sent: [(transaction: BSDKTransaction, gas: TransferPreparationGas)] {
        state.withLock { $0.sent }
    }

    var cancelledRequests: Int {
        state.withLock { $0.cancelledRequests }
    }

    convenience init(gas: TransferPreparationGas?) {
        self.init(gases: [gas])
    }

    init(gases: [TransferPreparationGas?], entered: TestGate? = nil, release: TestGate? = nil) {
        self.gases = gases
        self.entered = entered
        self.release = release
    }

    func gas(mainCall: TransferPreparationCall) async -> TransferPreparationGas? {
        let index = state.withLock { state -> Int in
            state.gasRequests.append(mainCall)
            return state.gasRequests.count - 1
        }

        if index > 0 {
            await withTaskCancellationHandler {
                entered?.open()
                await release?.wait()
            } onCancel: { [state] in
                state.withLock { $0.cancelledRequests += 1 }
            }
        }

        return gases[min(index, gases.count - 1)]
    }

    func send(mainCall: BSDKTransaction, gas: TransferPreparationGas) async throws -> TransactionDispatcherResult {
        state.withLock { $0.sent.append((mainCall, gas)) }
        return TransactionDispatcherResult(hash: "hash", url: nil, signerType: "test", currentHost: "test")
    }
}
