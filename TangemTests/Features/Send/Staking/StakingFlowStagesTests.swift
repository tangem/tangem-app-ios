//
//  StakingFlowStagesTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BlockchainSdk
import Foundation
import TangemStaking
import Testing
@testable import Tangem

@Suite("StakingFlowStages")
struct StakingFlowStagesTests {
    // MARK: - finalize

    @Test("Finalize returns ready without reducing the amount when the fee is not included")
    func finalizeReady() {
        guard case .ready(let ready) = makeStages().finalize(amount: 10, fee: 1, target: nil, isAmountEditable: true, includesStakesCount: false) else {
            Issue.record("Expected ready")
            return
        }
        #expect(ready.amount == 10)
        #expect(ready.fee == 1)
        #expect(ready.isFeeIncluded == false)
    }

    @Test("Finalize subtracts the fee from an editable amount when the fee must be included")
    func finalizeFeeIncluded() {
        let stages = makeStages(feeIncludedCalculator: FeeIncludedCalculatorStub(shouldInclude: true))

        guard case .ready(let ready) = stages.finalize(amount: 10, fee: 1, target: nil, isAmountEditable: true, includesStakesCount: false) else {
            Issue.record("Expected ready")
            return
        }
        #expect(ready.amount == 9)
        #expect(ready.isFeeIncluded == true)
    }

    @Test("Finalize never includes the fee for a non-editable amount")
    func finalizeFixedIgnoresFeeInclusion() {
        let stages = makeStages(feeIncludedCalculator: FeeIncludedCalculatorStub(shouldInclude: true))

        guard case .ready(let ready) = stages.finalize(amount: 10, fee: 1, target: nil, isAmountEditable: false, includesStakesCount: false) else {
            Issue.record("Expected ready")
            return
        }
        #expect(ready.amount == 10)
        #expect(ready.isFeeIncluded == false)
    }

    @Test("Finalize surfaces a validation error from the transaction validator")
    func finalizeValidationError() {
        let validator = SendTransactionValidatorMock()
        validator.amountFeeError = ValidationError.totalExceedsBalance
        let stages = makeStages(transactionValidator: validator)

        guard case .failure(.transaction) = stages.finalize(amount: 10, fee: 1, target: nil, isAmountEditable: true, includesStakesCount: false) else {
            Issue.record("Expected transaction failure")
            return
        }
    }

    @Test("Finalize omits the stakes count when it is not included")
    func finalizeNoStakesCount() {
        guard case .ready(let ready) = makeStages().finalize(amount: 10, fee: 1, target: nil, isAmountEditable: true, includesStakesCount: false) else {
            Issue.record("Expected ready")
            return
        }
        #expect(ready.stakesCount == nil)
    }

    // MARK: - validate

    @Test("Validate passes through when the transaction validator accepts")
    func validatePasses() {
        #expect(makeStages().validate(amount: 10, fee: 1) == nil)
    }

    @Test("Validate surfaces a transaction failure")
    func validateFails() {
        let validator = SendTransactionValidatorMock()
        validator.amountFeeError = ValidationError.totalExceedsBalance
        guard case .failure(.transaction) = makeStages(transactionValidator: validator).validate(amount: 10, fee: 1) else {
            Issue.record("Expected transaction failure")
            return
        }
    }

    // MARK: - accountInit

    @Test("Account-init is skipped without a service")
    func accountInitSkippedNoService() async throws {
        #expect(try await makeStages().accountInit(transactionFee: 1) == nil)
    }

    @Test("Account-init passes through when the account is already initialized")
    func accountInitAlreadyInitialized() async throws {
        let service = BlockchainAccountInitializationServiceMock(isInitialized: true, initializationFee: fee(0.5))
        #expect(try await makeStages(accountInitializationService: service).accountInit(transactionFee: 1) == nil)
    }

    @Test("Account-init requires initialization when the account is missing")
    func accountInitRequired() async throws {
        let service = BlockchainAccountInitializationServiceMock(isInitialized: false, initializationFee: fee(0.5))

        guard case .prerequisite(.accountInitialization(.required(let initFee, let txFee))) = try await makeStages(accountInitializationService: service).accountInit(transactionFee: 1) else {
            Issue.record("Expected account initialization required")
            return
        }
        #expect(initFee.amount.value == 0.5)
        #expect(txFee.amount.value == 1)
    }

    // MARK: - resolveCommon

    @Test("resolveCommon reaches ready when nothing is pending")
    func resolveCommonReady() async throws {
        let stages = makeStages(stakingManager: StakingManagerMock(estimateFeeResult: .success(1)))

        guard case .ready = try await stages.resolveCommon(action: stakeAction(amount: 10), stepPlan: editableStepPlan()) else {
            Issue.record("Expected ready")
            return
        }
    }

    @Test("resolveCommon surfaces account initialization before finalizing")
    func resolveCommonAccountInit() async throws {
        let service = BlockchainAccountInitializationServiceMock(isInitialized: false, initializationFee: fee(0.5))
        let stages = makeStages(
            stakingManager: StakingManagerMock(estimateFeeResult: .success(1)),
            accountInitializationService: service
        )

        guard case .prerequisite(.accountInitialization(.required)) = try await stages.resolveCommon(action: stakeAction(amount: 10), stepPlan: editableStepPlan()) else {
            Issue.record("Expected account initialization")
            return
        }
    }

    @Test("resolveCommon propagates a fee-estimation failure")
    func resolveCommonPropagatesEstimateError() async throws {
        let stages = makeStages(stakingManager: StakingManagerMock(estimateFeeResult: .failure(StakingManagerMockError.notStubbed)))

        await #expect(throws: StakingManagerMockError.self) {
            _ = try await stages.resolveCommon(action: stakeAction(amount: 10), stepPlan: editableStepPlan())
        }
    }

    // MARK: - Enter extras (stake)

    @Test("Entering a position surfaces amount-to-reduce when the fee is included")
    func enterExtrasAmountToReduce() async throws {
        let stages = makeStages(
            stakingManager: StakingManagerMock(estimateFeeResult: .success(2)),
            feeIncludedCalculator: FeeIncludedCalculatorStub(shouldInclude: true),
            minimalBalanceProvider: MinimalBalanceProviderStub(value: 1)
        )

        guard case .ready(let ready) = try await stages.resolveCommon(action: stakeAction(amount: 10), stepPlan: editableStepPlan()) else {
            Issue.record("Expected ready")
            return
        }
        #expect(ready.isFeeIncluded)
        #expect(ready.amountToReduce == 7) // fee 2 * 3 + minimal balance 1
        #expect(ready.stakeOnDifferentValidator == false)
    }

    @Test("A non-enter action carries no enter extras")
    func nonEnterReadyHasNoExtras() async throws {
        let stages = makeStages(
            stakingManager: StakingManagerMock(estimateFeeResult: .success(1)),
            feeIncludedCalculator: FeeIncludedCalculatorStub(shouldInclude: true),
            minimalBalanceProvider: MinimalBalanceProviderStub(value: 1)
        )
        let unstake = StakingAction(amount: 5, targetType: .empty, type: .unstake)

        guard case .ready(let ready) = try await stages.resolveCommon(action: unstake, stepPlan: editableStepPlan()) else {
            Issue.record("Expected ready")
            return
        }
        #expect(ready.amountToReduce == nil)
        #expect(ready.stakeOnDifferentValidator == false)
    }

    // MARK: - Helpers

    private func stakeAction(amount: Decimal = 1) -> StakingAction {
        StakingAction(amount: amount, targetType: .empty, type: .stake)
    }

    private func editableStepPlan() -> StakeStepPlan {
        StakeStepPlan(
            amount: .editable(preset: nil),
            hasValidatorSelection: true,
            includesStakesCount: false,
            summarySettings: .init(destinationEditableType: .editable, amountEditableType: .editable)
        )
    }

    private func tokenItem() -> TokenItem {
        .blockchain(.init(.solana(curve: .ed25519, testnet: false), derivationPath: nil))
    }

    private func makeStages(
        stakingManager: StakingManager = StakingManagerMock(estimateFeeResult: .success(1)),
        transactionValidator: SendTransactionValidator = SendTransactionValidatorMock(),
        feeIncludedCalculator: FeeIncludedCalculator = FeeIncludedCalculatorStub(),
        accountInitializationService: BlockchainAccountInitializationService? = nil,
        minimalBalanceProvider: MinimalBalanceProvider? = nil
    ) -> StakingFlowStages {
        let item = tokenItem()
        return StakingFlowStages(
            stakingManager: stakingManager,
            transactionValidator: transactionValidator,
            feeIncludedCalculator: feeIncludedCalculator,
            accountInitializationService: accountInitializationService,
            minimalBalanceProvider: minimalBalanceProvider,
            tokenItem: item,
            feeTokenItem: item
        )
    }

    private struct MinimalBalanceProviderStub: MinimalBalanceProvider {
        let value: Decimal
        func minimalBalance() -> Decimal { value }
    }

    private func fee(_ value: Decimal) -> Fee {
        let item = tokenItem()
        return Fee(Amount(with: item.blockchain, type: item.amountType, value: value))
    }
}
