//
//  StakingFlowProviderTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BlockchainSdk
import Foundation
import TangemStaking
import Testing
@testable import Tangem

@Suite("StakingFlowProvider")
struct StakingFlowProviderTests {
    // MARK: - Solana (common path)

    @Test("Solana stake: editable amount, validator selection, resolves to ready")
    func solanaStake() async throws {
        let action = StakingAction(amount: 0, targetType: .empty, type: .stake)
        let provider = SolanaStakingFlowProvider(
            action: action,
            stages: makeStages(stakingManager: StakingManagerMock(estimateFeeResult: .success(2))),
            preflightValidator: nil
        )

        #expect(provider.stepPlan.amount == .editable(preset: nil))
        #expect(provider.stepPlan.hasValidatorSelection)

        guard case .ready(let ready) = try await provider.updateState(amount: 10, target: nil) else {
            Issue.record("Expected ready")
            return
        }
        #expect(ready.amount == 10)
        #expect(ready.fee == 2)
    }

    @Test("Solana unstake: amount only, no validators, includes stakes count")
    func solanaUnstake() async throws {
        let action = StakingAction(amount: 7, targetType: .empty, type: .unstake)
        let provider = SolanaStakingFlowProvider(action: action, stages: makeStages(), preflightValidator: nil)

        #expect(provider.stepPlan.hasValidatorSelection == false)
        #expect(provider.stepPlan.includesStakesCount)

        guard case .ready = try await provider.updateState(amount: 5, target: nil) else {
            Issue.record("Expected ready")
            return
        }
    }

    @Test("Solana exit surfaces the rent-exemption preflight failure instead of resolving")
    func solanaExitRentExemption() async throws {
        let preflight = StakingPreflightValidatorMock(failure: rentExemptionFailure())
        let provider = SolanaStakingFlowProvider(
            action: StakingAction(amount: 7, targetType: .empty, type: .unstake),
            stages: makeStages(),
            preflightValidator: preflight
        )

        guard case .failure(.transaction(let error, let fee)) = try await provider.updateState(amount: 7, target: nil) else {
            Issue.record("Expected a transaction failure")
            return
        }
        guard case .remainingAmountIsLessThanRentExemption = error else {
            Issue.record("Expected a rent-exemption error")
            return
        }
        #expect(fee == 2)
    }

    @Test("Solana skips the rent-exemption preflight when entering a position")
    func solanaEnterSkipsPreflight() async throws {
        let preflight = StakingPreflightValidatorMock(failure: rentExemptionFailure())
        let provider = SolanaStakingFlowProvider(
            action: StakingAction(amount: 0, targetType: .empty, type: .stake),
            stages: makeStages(stakingManager: StakingManagerMock(estimateFeeResult: .success(2))),
            preflightValidator: preflight
        )

        guard case .ready = try await provider.updateState(amount: 10, target: nil) else {
            Issue.record("Expected ready")
            return
        }
        #expect(preflight.validateCallsCount == 0)
    }

    // MARK: - Cardano (network quirks)

    @Test("Cardano stake: amount is fixed to the full balance, not editable")
    func cardanoStakeStepPlan() {
        let action = StakingAction(amount: 100, targetType: .empty, type: .stake)
        let provider = CardanoStakingFlowProvider(action: action, stages: makeStages(), minAmountValidator: SendAmountValidatorMock())

        #expect(provider.stepPlan.amount == .fixed(100))
        #expect(provider.stepPlan.hasValidatorSelection)
    }

    @Test("Cardano stake is gated by the minimum-amount rule")
    func cardanoStakeMinAmount() async throws {
        let validator = SendAmountValidatorMock()
        validator.error = StakingValidationError.minAmountRequirementError(5, action: .stake)
        let action = StakingAction(amount: 1, targetType: .empty, type: .stake)
        let provider = CardanoStakingFlowProvider(action: action, stages: makeStages(), minAmountValidator: validator)

        guard case .failure(.staking) = try await provider.updateState(amount: nil, target: nil) else {
            Issue.record("Expected staking failure")
            return
        }
    }

    @Test("Cardano gates on the minimum before estimating a fee")
    func cardanoStakeMinAmountShortCircuits() async throws {
        let validator = SendAmountValidatorMock()
        validator.error = StakingValidationError.minAmountRequirementError(5, action: .stake)
        // Fee estimation is stubbed to fail; reaching it would throw, proving the min gate runs first.
        let provider = CardanoStakingFlowProvider(
            action: StakingAction(amount: 1, targetType: .empty, type: .stake),
            stages: makeStages(stakingManager: StakingManagerMock(estimateFeeResult: .failure(StakingManagerMockError.notStubbed))),
            minAmountValidator: validator
        )

        guard case .failure(.staking) = try await provider.updateState(amount: nil, target: nil) else {
            Issue.record("Expected staking failure")
            return
        }
    }

    @Test("Cardano stake resolves to ready once the minimum is satisfied")
    func cardanoStakeReady() async throws {
        let action = StakingAction(amount: 100, targetType: .empty, type: .stake)
        let provider = CardanoStakingFlowProvider(
            action: action,
            stages: makeStages(stakingManager: StakingManagerMock(estimateFeeResult: .success(2))),
            minAmountValidator: SendAmountValidatorMock()
        )

        guard case .ready = try await provider.updateState(amount: nil, target: nil) else {
            Issue.record("Expected ready")
            return
        }
    }

    @Test("Cardano stakes the full balance without tripping a balance check")
    func cardanoStakeFullBalanceIsNotSpent() async throws {
        let balance: Decimal = 100
        let provider = CardanoStakingFlowProvider(
            action: StakingAction(amount: balance, targetType: .empty, type: .stake),
            stages: makeStages(
                stakingManager: StakingManagerMock(estimateFeeResult: .success(2)),
                transactionValidator: SendTransactionValidatorMock(balance: balance)
            ),
            minAmountValidator: SendAmountValidatorMock()
        )

        #expect(provider.enterSpendsAmount == false)

        guard case .ready(let ready) = try await provider.updateState(amount: nil, target: nil) else {
            Issue.record("Expected ready")
            return
        }
        #expect(ready.amount == balance)
    }

    @Test("Cardano stake-more keeps the staked amount out of the balance check too")
    func cardanoStakeMoreIsNotSpent() async throws {
        let balance: Decimal = 100
        let provider = CardanoStakingFlowProvider(
            action: StakingAction(
                amount: balance,
                targetType: .empty,
                type: .pending(.stake(passthrough: "p")),
                displayType: .pending(.restake(passthrough: "p"))
            ),
            stages: makeStages(
                stakingManager: StakingManagerMock(estimateFeeResult: .success(2)),
                transactionValidator: SendTransactionValidatorMock(balance: balance)
            ),
            minAmountValidator: SendAmountValidatorMock()
        )

        guard case .ready = try await provider.updateState(amount: nil, target: .stub()) else {
            Issue.record("Expected ready")
            return
        }
    }

    @Test("A chain whose stake leaves the wallet still validates the amount against the balance")
    func solanaStakeSpendsAmount() async throws {
        let balance: Decimal = 100
        let provider = SolanaStakingFlowProvider(
            action: StakingAction(amount: 0, targetType: .empty, type: .stake),
            stages: makeStages(
                stakingManager: StakingManagerMock(estimateFeeResult: .success(2)),
                transactionValidator: SendTransactionValidatorMock(balance: balance)
            ),
            preflightValidator: nil
        )

        #expect(provider.enterSpendsAmount)

        guard case .failure(.transaction(.totalExceedsBalance, _)) = try await provider.updateState(amount: balance, target: nil) else {
            Issue.record("Expected total-exceeds-balance failure")
            return
        }
    }

    // MARK: - makeAction

    @Test("makeAction respects the step plan amount mode")
    func makeActionAmountMode() {
        let editable = SolanaStakingFlowProvider(
            action: StakingAction(amount: 0, targetType: .empty, type: .stake),
            stages: makeStages(),
            preflightValidator: nil
        )
        #expect(editable.makeAction(amount: 5, target: nil).amount == 5)

        let fixed = CardanoStakingFlowProvider(
            action: StakingAction(amount: 100, targetType: .empty, type: .stake),
            stages: makeStages(),
            minAmountValidator: SendAmountValidatorMock()
        )
        #expect(fixed.makeAction(amount: 5, target: nil).amount == 100)
    }

    @Test("makeAction keeps the display type, which differs from the sent type on Cardano stake-more")
    func makeActionKeepsDisplayType() {
        let provider = CardanoStakingFlowProvider(
            action: StakingAction(
                amount: 100,
                targetType: .empty,
                type: .pending(.stake(passthrough: "p")),
                displayType: .pending(.restake(passthrough: "p"))
            ),
            stages: makeStages(),
            minAmountValidator: SendAmountValidatorMock()
        )

        let action = provider.makeAction(amount: nil, target: .stub())
        #expect(action.type == .pending(.stake(passthrough: "p")))
        #expect(action.displayType == .pending(.restake(passthrough: "p")))
    }

    // MARK: - Network specifics

    @Test("TON disallows partial unstake")
    func tonUnstakeNotPartial() {
        let action = StakingAction(amount: 7, targetType: .empty, type: .unstake)
        let provider = TONStakingFlowProvider(action: action, stages: makeStages())
        #expect(provider.stepPlan.amount == .fixed(7))
    }

    // MARK: - Ethereum (ERC-20 approval prerequisite)

    @Test("Ethereum stake requires approval before entering")
    func ethereumStakeApprove() async throws {
        let allowance = AllowanceServiceMock()
        allowance.allowanceStateResult = .success(.permissionRequired(approveData()))
        let provider = makeEthereumProvider(allowanceService: allowance)

        guard case .prerequisite(.approve(.required(_, let fee))) = try await provider.updateState(amount: 10, target: nil) else {
            Issue.record("Expected approve required")
            return
        }
        #expect(fee == 3)
    }

    @Test("Ethereum stake with enough allowance falls through to ready")
    func ethereumEnoughAllowance() async throws {
        let provider = makeEthereumProvider(allowanceService: AllowanceServiceMock())

        guard case .ready = try await provider.updateState(amount: 10, target: nil) else {
            Issue.record("Expected ready")
            return
        }
    }

    @Test("Ethereum surfaces an in-progress approval with the staking fee")
    func ethereumApproveInProgress() async throws {
        let allowance = AllowanceServiceMock()
        allowance.allowanceStateResult = .success(.approveTransactionInProgress)
        let provider = makeEthereumProvider(allowanceService: allowance)

        guard case .prerequisite(.approve(.inProgress(let fee))) = try await provider.updateState(amount: 10, target: nil) else {
            Issue.record("Expected approve in-progress")
            return
        }
        #expect(fee == 3)
    }

    @Test("Ethereum rejects revoke-and-approve")
    func ethereumRevokeThrows() async throws {
        let allowance = AllowanceServiceMock()
        allowance.allowanceStateResult = .success(.revokeAndPermissionRequired(revoke: approveData(), approve: approveData()))
        let provider = makeEthereumProvider(allowanceService: allowance)

        await #expect(throws: StakeModelError.self) {
            _ = try await provider.updateState(amount: 10, target: nil)
        }
    }

    @Test("Ethereum without an allowance service falls through to ready")
    func ethereumNoAllowanceService() async throws {
        let provider = makeEthereumProvider(allowanceService: nil)

        guard case .ready = try await provider.updateState(amount: 10, target: nil) else {
            Issue.record("Expected ready")
            return
        }
    }

    // MARK: - Ethereum P2P (native ETH, vault as target)

    @Test("P2P stake selects a validator (the vault) and carries it into the action")
    func p2pStakeCarriesTarget() {
        let provider = EthereumP2PStakingFlowProvider(
            action: StakingAction(amount: 0, targetType: .empty, type: .stake),
            stages: makeStages()
        )

        #expect(provider.stepPlan.amount == .editable(preset: nil))
        #expect(provider.stepPlan.hasValidatorSelection)

        let vault = StakingTargetInfo.stub()
        #expect(provider.makeAction(amount: 10, target: vault).targetInfo?.address == vault.address)
    }

    @Test("P2P stake runs no approval stage and resolves to ready")
    func p2pStakeNoApproval() async throws {
        let provider = EthereumP2PStakingFlowProvider(
            action: StakingAction(amount: 0, targetType: .empty, type: .stake),
            stages: makeStages(stakingManager: StakingManagerMock(estimateFeeResult: .success(2)))
        )

        guard case .ready(let ready) = try await provider.updateState(amount: 10, target: .stub()) else {
            Issue.record("Expected ready")
            return
        }
        #expect(ready.amount == 10)
        #expect(ready.fee == 2)
    }

    // MARK: - reconcileBuiltFee

    @Test("A built fee above a fee-included estimate re-states the flow to re-confirm")
    func reconcileBuiltFeeIncreased() {
        let provider = SolanaStakingFlowProvider(action: withdraw(), stages: makeStages(), preflightValidator: nil)

        let restated = provider.reconcileBuiltFee(
            enteredAmount: 10,
            confirmed: StakeFlowState.Ready(amount: 10, fee: 1, isFeeIncluded: true, stakesCount: nil),
            builtTransaction: transaction(fee: 5),
            target: nil
        )

        guard case .ready(let ready)? = restated else {
            Issue.record("Expected a re-stated flow")
            return
        }
        #expect(ready.fee == 5)
    }

    @Test("A built fee at or below the estimate dispatches as-is")
    func reconcileBuiltFeeUnchanged() {
        let provider = SolanaStakingFlowProvider(action: withdraw(), stages: makeStages(), preflightValidator: nil)

        let restated = provider.reconcileBuiltFee(
            enteredAmount: 10,
            confirmed: StakeFlowState.Ready(amount: 10, fee: 5, isFeeIncluded: true, stakesCount: nil),
            builtTransaction: transaction(fee: 5),
            target: nil
        )
        #expect(restated == nil)
    }

    @Test("A fee increase is ignored when the fee is not included in the amount")
    func reconcileBuiltFeeNotIncluded() {
        let provider = SolanaStakingFlowProvider(action: withdraw(), stages: makeStages(), preflightValidator: nil)

        let restated = provider.reconcileBuiltFee(
            enteredAmount: 10,
            confirmed: StakeFlowState.Ready(amount: 10, fee: 1, isFeeIncluded: false, stakesCount: nil),
            builtTransaction: transaction(fee: 5),
            target: nil
        )
        #expect(restated == nil)
    }

    // MARK: - Factory

    @Test("Factory maps each network to its entity")
    func factoryMapping() {
        let action = StakingAction(amount: 0, targetType: .empty, type: .stake)
        let validator = SendAmountValidatorMock()

        func make(_ network: StakingNetworkType, contract: String? = nil) -> StakingFlowProvider {
            StakingFlowProviderFactory.make(
                network: network,
                contractAddress: contract,
                action: action,
                stages: makeStages(),
                minAmountValidator: validator,
                preflightValidator: nil,
                allowanceService: nil,
                tokenFeeProvidersManager: makeFeeProvidersManager()
            )
        }

        #expect(make(.solana) is SolanaStakingFlowProvider)
        #expect(make(.cosmos) is CosmosStakingFlowProvider)
        #expect(make(.cardano) is CardanoStakingFlowProvider)
        #expect(make(.ton) is TONStakingFlowProvider)
        #expect(make(.ethereum, contract: "0xcontract") is EthereumStakingFlowProvider)
        #expect(make(.ethereum, contract: nil) is EthereumP2PStakingFlowProvider)
        #expect(make(.kava) is UnsupportedStakingFlowProvider)
        #expect(make(.near) is UnsupportedStakingFlowProvider)
        #expect(make(.polkadot) is UnsupportedStakingFlowProvider)
    }

    @Test("An unsupported network resolves to a failure instead of running another flow")
    func unsupportedNetworkFails() async throws {
        let provider = UnsupportedStakingFlowProvider(action: StakingAction(amount: 5, targetType: .empty, type: .stake))

        guard case .failure(.network) = try await provider.updateState(amount: nil, target: nil) else {
            Issue.record("Expected a network failure")
            return
        }
    }

    // MARK: - Helpers

    private func approveData() -> ApproveTransactionData {
        ApproveTransactionData(txData: Data(), spender: "0xspender", toContractAddress: "0xcontract")
    }

    private func withdraw() -> StakingAction {
        StakingAction(amount: 10, targetType: .empty, type: .pending(.withdraw(passthroughs: ["p"])))
    }

    private func transaction(fee: Decimal) -> StakingTransactionAction {
        StakingTransactionAction(
            amount: 0,
            transactions: [StakingTransactionInfo(network: "solana", unsignedTransactionData: .raw(""), fee: fee)]
        )
    }

    private func tokenItem() -> TokenItem {
        .blockchain(.init(.solana(curve: .ed25519, testnet: false), derivationPath: nil))
    }

    private func makeStages(
        stakingManager: StakingManager = StakingManagerMock(estimateFeeResult: .success(1)),
        accountInitializationService: BlockchainAccountInitializationService? = nil,
        transactionValidator: SendTransactionValidator = SendTransactionValidatorMock()
    ) -> StakeStagesResolver {
        let item = tokenItem()
        return StakeStagesResolver(
            stakingManager: stakingManager,
            transactionValidator: transactionValidator,
            feeIncludedCalculator: FeeIncludedCalculatorStub(),
            accountInitializationService: accountInitializationService,
            tokenItem: item,
            feeTokenItem: item
        )
    }

    private func rentExemptionFailure() -> StakingPreflightFailure {
        let item = tokenItem()
        return StakingPreflightFailure(
            validationError: .remainingAmountIsLessThanRentExemption(
                amount: Amount(with: item.blockchain, type: item.amountType, value: 1)
            ),
            estimatedFee: 2
        )
    }

    private func makeFeeProvidersManager(approveFee: Decimal = 1) -> TokenFeeProvidersManagerMock {
        let item = tokenItem()
        let fee = Fee(Amount(with: item.blockchain, type: item.amountType, value: approveFee))
        let tokenFee = TokenFee(option: .market, tokenItem: item, value: .success(fee))
        return TokenFeeProvidersManagerMock(feeProvider: TokenFeeProviderStub(feeTokenItem: item, initialFee: tokenFee))
    }

    private func makeEthereumProvider(
        action: StakingAction = StakingAction(amount: 0, targetType: .empty, type: .stake),
        allowanceService: AllowanceService?,
        tokenFeeProvidersManager: TokenFeeProvidersManager? = nil
    ) -> EthereumStakingFlowProvider {
        EthereumStakingFlowProvider(
            action: action,
            stages: makeStages(stakingManager: StakingManagerMock(allowanceAddress: "0xspender", estimateFeeResult: .success(3))),
            allowanceService: allowanceService,
            tokenFeeProvidersManager: tokenFeeProvidersManager ?? makeFeeProvidersManager()
        )
    }
}
