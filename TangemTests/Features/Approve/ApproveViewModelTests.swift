//
//  ApproveViewModelTests.swift
//  TangemTests
//
//  Created for Approve flow unit tests.
//

import Foundation
import Testing
import BlockchainSdk
@testable import Tangem

@Suite("ApproveViewModel")
struct ApproveViewModelTests {
    private let testSpender = "0xSpenderAddress"
    private let testContractAddress = "0xContractAddress"
    private let testTxData = Data([0xAA, 0xBB, 0xCC, 0xDD])
    private let unlimitedTxData = Data([0xFF, 0xFF])

    // MARK: - Policy change

    @Test("Policy change disables the approve button until the calldata and fee are recalculated")
    func policyChange_disablesButtonWhileUpdating() async throws {
        let env = makeEnv()
        env.allowanceService.setMakeApproveDataResult(.success(makeUnlimitedData()), for: ApprovePolicy.unlimited)
        let approveDataGate = TestGate()
        env.allowanceService.makeApproveDataGate = approveDataGate
        let sut = makeSUT(env: env)

        await MainActor.run { sut.selectedPolicy = ApprovePolicy.unlimited }

        #expect(sut.state == .updatingPolicy, "The button locks before the rebuild even starts")
        try await waitUntil { env.allowanceService.makeApproveDataCalls.count == 1 }

        approveDataGate.open()

        try await waitUntil { sut.state == .idle }
        #expect(sut.selectedPolicy == ApprovePolicy.unlimited)
        #expect(env.interactor.approveInteractorState.policy == ApprovePolicy.unlimited)
        #expect(env.interactor.approveInteractorState.approveData.txData == unlimitedTxData)
    }

    @Test("Failed recalculation reverts the selection to the active policy and shows the error")
    func policyChange_failure_revertsSelectionAndShowsAlert() async throws {
        let env = makeEnv()
        env.allowanceService.makeApproveDataResult = .failure(NSError(domain: "test", code: -1))
        let sut = makeSUT(env: env)

        await MainActor.run { sut.selectedPolicy = ApprovePolicy.unlimited }

        try await waitUntil { sut.errorAlert != nil && sut.state == .idle }
        #expect(sut.selectedPolicy == ApprovePolicy.specified)
        #expect(env.interactor.approveInteractorState.policy == ApprovePolicy.specified)
        #expect(env.allowanceService.makeApproveDataCalls.count == 1, "Reverting the selection must not trigger another recalculation")
    }

    @Test("Switching back to the active policy cancels the in-flight rebuild and unlocks the button")
    func policyChange_backToActivePolicy_cancelsInFlightRebuild() async throws {
        let env = makeEnv()
        env.allowanceService.setMakeApproveDataResult(.success(makeUnlimitedData()), for: ApprovePolicy.unlimited)
        let approveDataGate = TestGate()
        env.allowanceService.makeApproveDataGate = approveDataGate
        let sut = makeSUT(env: env)
        let feesCallsBefore = env.feeManager.updateFeesCalls

        await MainActor.run { sut.selectedPolicy = ApprovePolicy.unlimited }
        try await waitUntil { env.allowanceService.makeApproveDataCalls.count == 1 }
        #expect(sut.state == .updatingPolicy)

        await MainActor.run { sut.selectedPolicy = ApprovePolicy.specified }
        #expect(sut.state == .idle, "Returning to the active policy needs no rebuild")

        approveDataGate.open()
        try await Task.sleep(for: .milliseconds(100))

        #expect(env.allowanceService.makeApproveDataCalls.count == 1, "Returning to the active policy must not rebuild the calldata")
        #expect(env.interactor.approveInteractorState.policy == ApprovePolicy.specified)
        #expect(env.interactor.approveInteractorState.approveData.txData == testTxData, "The cancelled rebuild must not replace the calldata")
        #expect(env.feeManager.updateFeesCalls == feesCallsBefore, "The cancelled rebuild must not trigger a fee update")
        #expect(sut.state == .idle)
    }

    @Test("Policy change during the fee phase rebuilds again and the latest selection wins")
    func policyChange_duringFeePhase_latestSelectionWins() async throws {
        let specifiedData = ApproveTransactionData(txData: Data([0x02]), spender: testSpender, toContractAddress: "0xSpecified")

        let env = makeEnv()
        env.allowanceService.setMakeApproveDataResult(.success(makeUnlimitedData()), for: ApprovePolicy.unlimited)
        env.allowanceService.setMakeApproveDataResult(.success(specifiedData), for: ApprovePolicy.specified)
        let sut = makeSUT(env: env)
        let feeGate = TestGate()
        env.feeManager.updateFeesGate = feeGate

        await MainActor.run { sut.selectedPolicy = ApprovePolicy.unlimited }
        try await waitUntil { env.interactor.approveInteractorState.policy == ApprovePolicy.unlimited }
        #expect(sut.state == .updatingPolicy, "The button stays locked until the fee for the new calldata arrives")

        await MainActor.run { sut.selectedPolicy = ApprovePolicy.specified }
        feeGate.open()

        try await waitUntil { sut.state == .idle }

        #expect(env.allowanceService.makeApproveDataCalls.count == 2, "The calldata was already rebuilt for .unlimited, so .specified needs its own rebuild")
        #expect(env.interactor.approveInteractorState.policy == ApprovePolicy.specified)
        #expect(env.interactor.approveInteractorState.approveData.txData == specifiedData.txData)
        #expect(sut.selectedPolicy == ApprovePolicy.specified)
    }

    // MARK: - Approve during recalculation

    @Test("Approving while the policy is being recalculated is dropped silently and does not dispatch")
    func didTapApprove_whileUpdating_isDroppedWithoutAlert() async throws {
        let env = makeEnv()
        env.allowanceService.setMakeApproveDataResult(.success(makeUnlimitedData()), for: ApprovePolicy.unlimited)
        let approveDataGate = TestGate()
        env.allowanceService.makeApproveDataGate = approveDataGate
        let sut = makeSUT(env: env)

        await MainActor.run { sut.selectedPolicy = ApprovePolicy.unlimited }
        try await waitUntil { sut.state == .updatingPolicy }

        await MainActor.run { sut.didTapApprove() }

        try await Task.sleep(for: .milliseconds(100))
        #expect(sut.errorAlert == nil, "A tap that slipped in during the recalculation must not surface as an error")
        #expect(env.dispatcher.sendCalls.isEmpty, "Stale calldata must never reach the dispatcher")
        #expect(sut.state == .updatingPolicy, "The sheet must stay in the policy update state after the dropped tap")

        approveDataGate.open()
        try await waitUntil { sut.state == .idle }
    }

    @Test("Approving during the fee phase of a policy change is dropped until the new fee arrives")
    func didTapApprove_duringFeePhase_isDroppedUntilFeeArrives() async throws {
        let env = makeEnv()
        env.allowanceService.setMakeApproveDataResult(.success(makeUnlimitedData()), for: ApprovePolicy.unlimited)
        let sut = makeSUT(env: env)
        let feeGate = TestGate()
        env.feeManager.updateFeesGate = feeGate

        await MainActor.run { sut.selectedPolicy = ApprovePolicy.unlimited }
        try await waitUntil { env.interactor.approveInteractorState.policy == ApprovePolicy.unlimited }

        await MainActor.run { sut.didTapApprove() }
        try await Task.sleep(for: .milliseconds(100))

        #expect(sut.state == .updatingPolicy)
        #expect(sut.errorAlert == nil)
        #expect(env.dispatcher.sendCalls.isEmpty, "The approve must wait for the fee of the new calldata")

        feeGate.open()
        try await waitUntil { sut.state == .idle }

        await MainActor.run { sut.didTapApprove() }
        try await waitUntil { env.dispatcher.sendCalls.count == 1 }

        guard case .approve(let sentData, _) = env.dispatcher.sendCalls.first else {
            Issue.record("Expected .approve transaction")
            return
        }

        #expect(sentData.txData == unlimitedTxData)
    }

    // MARK: - Sending

    @Test("The selected policy is seeded from the interactor state")
    func init_seedsSelectedPolicyFromInteractorState() {
        let env = makeEnv()
        let sut = makeSUT(env: env, policy: .unlimited)

        #expect(sut.selectedPolicy == ApprovePolicy.unlimited)
    }

    @Test("Approve keeps the button and the policy picker locked for the whole send and ignores a second tap")
    func didTapApprove_locksSheetUntilSendFinishes() async throws {
        let env = makeEnv()
        let sendGate = TestGate()
        env.dispatcher.sendGate = sendGate
        let sut = makeSUT(env: env)

        await MainActor.run { sut.didTapApprove() }
        try await waitUntil { env.dispatcher.sendCalls.count == 1 }

        #expect(sut.state == .sending)
        #expect(sut.state.isContentLocked)
        #expect(sut.state.isMainButtonDisabled)

        await MainActor.run { sut.didTapApprove() }
        try await Task.sleep(for: .milliseconds(100))
        #expect(env.dispatcher.sendCalls.count == 1, "A second tap during a send must not dispatch again")

        sendGate.open()
        try await waitUntil { env.output.approveDidSendTransactionCallCount == 1 }

        #expect(env.dispatcher.sendCalls.count == 1)
    }

    @Test("A failed send unlocks the sheet and shows the error")
    func didTapApprove_failure_unlocksSheetAndShowsAlert() async throws {
        let env = makeEnv()
        env.dispatcher.sendResult = .failure(TransactionDispatcherResult.Error.transactionNotFound)
        let sut = makeSUT(env: env)

        await MainActor.run { sut.didTapApprove() }

        try await waitUntil { sut.errorAlert != nil && sut.state == .idle }
    }

    // MARK: - Async Helpers

    private func waitUntil(
        timeout: Duration = .seconds(2),
        condition: @Sendable () -> Bool
    ) async throws {
        let deadline = ContinuousClock.now + timeout
        while !condition() {
            if ContinuousClock.now >= deadline {
                throw WaitUntilTimeoutError()
            }
            await Task.yield()
        }
    }

    private struct WaitUntilTimeoutError: Error {}

    // MARK: - Helpers

    private final class Env {
        let allowanceService = AllowanceServiceMock()
        let dispatcher = TransactionDispatcherMock()
        let analyticsLogger = SendApproveAnalyticsLoggerMock()
        let output = ApproveOutputMock()
        var feeManager: TokenFeeProvidersManagerMock!
        var interactor: ApproveInteractor!
    }

    private func makeEnv() -> Env {
        let env = Env()
        let tokenItem = makeTestTokenItem()
        let fee = Fee(Amount(with: .ethereum(testnet: false), value: 0.001))
        let tokenFee = TokenFee(option: .market, tokenItem: tokenItem, value: .success(fee))
        let feeProvider = TokenFeeProviderStub(feeTokenItem: tokenItem, initialFee: tokenFee)
        env.feeManager = TokenFeeProvidersManagerMock(feeProvider: feeProvider)
        return env
    }

    private func makeSUT(env: Env, policy: ApprovePolicy = .specified) -> ApproveViewModel {
        let approveData = ApproveTransactionData(txData: testTxData, spender: testSpender, toContractAddress: testContractAddress)

        let interactor = ApproveInteractor(
            approveInteractorState: .approve(data: approveData, policy: policy),
            approveAmount: 100,
            allowanceService: env.allowanceService,
            approveTransactionDispatcher: env.dispatcher,
            tokenFeeProvidersManager: env.feeManager,
            analyticsLogger: env.analyticsLogger,
            output: env.output
        )
        env.interactor = interactor

        let settings = ApproveViewModel.Settings(
            title: "Test title",
            subtitle: "Test subtitle",
            feeFooterText: "Test footer",
            tokenItem: makeTestTokenItem(),
            tangemIconProvider: ApproveTangemIconProviderStub()
        )

        let input = ApproveViewModel.Input(
            settings: settings,
            feeFormatter: ApproveFeeFormatterStub(),
            interactor: interactor
        )

        return ApproveViewModel(input: input)
    }

    private func makeUnlimitedData() -> ApproveTransactionData {
        ApproveTransactionData(txData: unlimitedTxData, spender: testSpender, toContractAddress: testContractAddress)
    }

    private func makeTestTokenItem() -> TokenItem {
        .blockchain(.init(.ethereum(testnet: false), derivationPath: nil))
    }
}
