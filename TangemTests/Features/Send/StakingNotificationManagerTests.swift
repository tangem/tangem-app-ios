//
//  StakingNotificationManagerTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import Testing
import BlockchainSdk
import TangemTestKit
@testable import TangemStaking
@testable import Tangem

@Suite("CommonStakingNotificationManager")
final class StakingNotificationManagerTests: LeakTrackingTestSuite {
    private let blockchain = Blockchain.solana(curve: .ed25519_slip0010, testnet: false)

    private var tokenItem: TokenItem { .blockchain(.init(blockchain, derivationPath: nil)) }

    private var rentExemptionError: ValidationError {
        .remainingAmountIsLessThanRentExemption(amount: .init(with: blockchain, value: Decimal(string: "0.00089088")!))
    }

    @Test("Withdraw info banner is shown while the fee is loading")
    func withdrawInfoIsShownOnLoading() {
        let (manager, stateSubject) = makeSUT()

        stateSubject.send(.loading)

        let events = stakingEvents(manager)
        #expect(events.count == 1)
        #expect(containsWithdrawInfo(events))
    }

    @Test("Rent exemption error replaces the withdraw info banner")
    func rentExemptionErrorHidesWithdrawInfo() {
        let (manager, stateSubject) = makeSUT()

        stateSubject.send(.loading)
        stateSubject.send(.validationError(rentExemptionError, fee: 0.000205))

        let events = stakingEvents(manager)
        #expect(events.count == 1)
        #expect(!containsWithdrawInfo(events))
        #expect(containsRentExemptionError(events))
    }

    @Test("Withdraw info banner is restored when the state becomes ready")
    func withdrawInfoIsRestoredOnReady() {
        let (manager, stateSubject) = makeSUT()

        stateSubject.send(.loading)
        stateSubject.send(.validationError(rentExemptionError, fee: 0.000205))
        stateSubject.send(.ready(fee: 0.000205, stakesCount: nil))

        let events = stakingEvents(manager)
        #expect(containsWithdrawInfo(events))
        #expect(!containsRentExemptionError(events))
    }

    @Test("Other validation errors keep the withdraw info banner")
    func otherValidationErrorKeepsWithdrawInfo() {
        let (manager, stateSubject) = makeSUT()

        stateSubject.send(.loading)
        stateSubject.send(.validationError(.totalExceedsBalance, fee: 0.000205))

        let events = stakingEvents(manager)
        #expect(containsWithdrawInfo(events))
        #expect(events.count == 2)
    }
}

// MARK: - Helpers

private extension StakingNotificationManagerTests {
    func makeSUT() -> (manager: CommonStakingNotificationManager, stateSubject: CurrentValueSubject<UnstakingModel.State, Never>) {
        let manager = CommonStakingNotificationManager(
            tokenItem: tokenItem,
            feeTokenItem: tokenItem,
            analyticsLogger: StakingSendAnalyticsLoggerMock()
        )

        let stateSubject = CurrentValueSubject<UnstakingModel.State, Never>(.loading)
        let provider = UnstakingModelStateProviderStub(
            stateSubject: stateSubject,
            stakingAction: StakingAction(amount: 0.02, targetType: .empty, type: .pending(.withdraw(passthroughs: []))),
            stakedBalance: 0.02
        )
        let input = StakingNotificationManagerInputStub(
            stakingManagerStatePublisher: Just(makeStakedState()).eraseToAnyPublisher()
        )

        manager.setup(provider: provider, input: input)

        return (trackForMemoryLeaks(manager), stateSubject)
    }

    func makeStakedState() -> StakingManagerState {
        .staked(.init(balances: [], yieldInfo: makeYieldInfo(), canStakeMore: true))
    }

    func makeYieldInfo() -> StakingYieldInfo {
        StakingYieldInfo(
            id: "solana-sol-native-multivalidator-staking",
            isAvailable: true,
            rewardType: .apy,
            rewardRateValues: RewardRateValues(aprs: [0.05], rewardRate: .zero),
            enterMinimumRequirement: .zero,
            exitMinimumRequirement: .zero,
            targets: [],
            preferredTargets: [],
            item: StakingTokenItem(network: .solana, name: "Solana", decimals: 9, symbol: "SOL"),
            unbondingPeriod: .constant(days: 3),
            warmupPeriod: .constant(days: 0),
            rewardClaimingType: .auto,
            rewardScheduleType: .daily,
            maximumStakeAmount: nil
        )
    }

    func stakingEvents(_ manager: CommonStakingNotificationManager) -> [StakingNotificationEvent] {
        manager.notificationInputs.compactMap { $0.settings.event as? StakingNotificationEvent }
    }

    func containsWithdrawInfo(_ events: [StakingNotificationEvent]) -> Bool {
        events.contains { event in
            if case .withdraw = event {
                return true
            }
            return false
        }
    }

    func containsRentExemptionError(_ events: [StakingNotificationEvent]) -> Bool {
        events.contains { event in
            guard case .validationErrorEvent(let validationErrorEvent) = event else {
                return false
            }

            if case .remainingAmountIsLessThanRentExemption = validationErrorEvent {
                return true
            }
            return false
        }
    }
}

// MARK: - Stubs

private struct UnstakingModelStateProviderStub: UnstakingModelStateProvider {
    let stateSubject: CurrentValueSubject<UnstakingModel.State, Never>
    let stakingAction: UnstakingModel.Action
    let stakedBalance: Decimal

    var state: UnstakingModel.State { stateSubject.value }

    var statePublisher: AnyPublisher<UnstakingModel.State, Never> {
        stateSubject.eraseToAnyPublisher()
    }
}

private struct StakingNotificationManagerInputStub: StakingNotificationManagerInput {
    let stakingManagerStatePublisher: AnyPublisher<StakingManagerState, Never>
}
