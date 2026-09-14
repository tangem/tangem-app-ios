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
import TangemLocalization
import TangemTestKit
@testable import TangemStaking
@testable import Tangem

@Suite("CommonStakingNotificationManager")
final class StakingNotificationManagerTests: LeakTrackingTestSuite {
    private let blockchain = Blockchain.solana(curve: .ed25519_slip0010, testnet: false)
    private let tonBlockchain = Blockchain.ton(curve: .ed25519_slip0010, testnet: false)

    private var rentExemptionError: ValidationError {
        .remainingAmountIsLessThanRentExemption(amount: .init(with: blockchain, value: Decimal(string: "0.00089088")!))
    }

    @Test("Withdraw info banner is shown while the fee is loading")
    func withdrawInfoIsShownOnLoading() {
        let (manager, stateSubject) = makeSUT()

        stateSubject.send(.loading)

        let events = stakingEvents(manager)
        #expect(events.count == 1)
        #expect(events.contains { $0.isWithdraw })
    }

    @Test("Rent exemption error replaces the withdraw info banner")
    func rentExemptionErrorHidesWithdrawInfo() {
        let (manager, stateSubject) = makeSUT()

        stateSubject.send(.loading)
        stateSubject.send(.validationError(rentExemptionError, fee: 0.000205))

        let events = stakingEvents(manager)
        #expect(events.count == 1)
        #expect(!events.contains { $0.isWithdraw })
        #expect(containsRentExemptionError(events))
    }

    @Test("Withdraw info banner is restored when the state becomes ready")
    func withdrawInfoIsRestoredOnReady() {
        let (manager, stateSubject) = makeSUT()

        stateSubject.send(.loading)
        stateSubject.send(.validationError(rentExemptionError, fee: 0.000205))
        stateSubject.send(.ready(fee: 0.000205, stakesCount: nil))

        let events = stakingEvents(manager)
        #expect(events.contains { $0.isWithdraw })
        #expect(!containsRentExemptionError(events))
    }

    @Test("Other validation errors keep the withdraw info banner")
    func otherValidationErrorKeepsWithdrawInfo() {
        let (manager, stateSubject) = makeSUT()

        stateSubject.send(.loading)
        stateSubject.send(.validationError(.totalExceedsBalance, fee: 0.000205))

        let events = stakingEvents(manager)
        #expect(events.contains { $0.isWithdraw })
        #expect(events.count == 2)
    }

    @Test("TON unstake notifications are ordered: extra reserve, positions status, unbonding period")
    func tonUnstakeNotificationsOrder() throws {
        let (manager, stateSubject) = makeSUT(
            blockchain: tonBlockchain,
            action: StakingAction(amount: 0.02, targetType: .empty, type: .unstake)
        )

        stateSubject.send(.ready(fee: 0.05, stakesCount: 2))

        let events = stakingEvents(manager)
        try #require(events.count == 3)

        #expect(events[0].isTonExtraReserveInfo)
        #expect(events[1].isTonUnstaking)
        #expect(events[2].isUnstake)
    }

    @Test("Low staked balance warning stays below the TON unstake notifications")
    func tonPartialUnstakeKeepsLowStakedBalanceLast() throws {
        let (manager, stateSubject) = makeSUT(
            blockchain: tonBlockchain,
            action: StakingAction(amount: 0.02, targetType: .empty, type: .unstake),
            stakedBalance: 0.03,
            exitMinimumRequirement: 0.05
        )

        stateSubject.send(.ready(fee: 0.05, stakesCount: 2))

        let events = stakingEvents(manager)
        try #require(events.count == 4)

        #expect(events[0].isTonExtraReserveInfo)
        #expect(events[1].isTonUnstaking)
        #expect(events[2].isUnstake)
        #expect(events[3].isLowStakedBalance)
    }

    @Test("Non-TON unstake shows only the unbonding period notification")
    func solanaUnstakeNotifications() throws {
        let (manager, stateSubject) = makeSUT(
            action: StakingAction(amount: 0.02, targetType: .empty, type: .unstake)
        )

        stateSubject.send(.ready(fee: 0.000205, stakesCount: 2))

        let events = stakingEvents(manager)
        try #require(events.count == 1)

        #expect(events[0].isUnstake)
    }

    @Test("TON withdraw shows the positions status notification above the withdraw info")
    func tonWithdrawNotificationsOrder() throws {
        let (manager, stateSubject) = makeSUT(blockchain: tonBlockchain)

        stateSubject.send(.ready(fee: 0.05, stakesCount: 2))

        let events = stakingEvents(manager)
        try #require(events.count == 2)

        #expect(events[0].isTonUnstaking)
        #expect(events[1].isWithdraw)
    }

    @Test("Coin exit fee-coverage failure shows the fee top-up banner with the Go-to-coin button")
    func coinExitFeeCoverageFailureShowsTopUpBanner() throws {
        let analyticsLogger = StakingSendAnalyticsLoggerMock()
        let (manager, stateSubject) = makeSUT(analyticsLogger: analyticsLogger)

        stateSubject.send(.validationError(feeExceedsBalanceError(isFeeCurrency: true), fee: 0.000205))

        let events = stakingEvents(manager)
        let topUpEvent = try #require(events.first { $0.isInsufficientFundsForFee })
        #expect(hasOpenFeeCurrencyButton(topUpEvent))
        #expect(title(of: topUpEvent) == Localization.warningBlockedFundsForFeeTitle)
        #expect(!containsInsufficientBalance(events))
        #expect(analyticsLogger.noticeNotEnoughFeeCalls == 1)
        // The balance the validator compared the fee against, not a guess.
        #expect(analyticsLogger.noticeNotEnoughFeeBalances == [0.0001])
    }

    @Test("V2 exit fee-coverage failure shows the fee top-up banner with the Go-to-coin button")
    func v2ExitFeeCoverageFailureShowsTopUpBanner() throws {
        let analyticsLogger = StakingSendAnalyticsLoggerMock()
        let (manager, stateSubject) = makeV2SUT(
            action: StakingAction(amount: 0.02, targetType: .empty, type: .unstake),
            analyticsLogger: analyticsLogger
        )

        stateSubject.send(.failure(.transaction(feeExceedsBalanceError(isFeeCurrency: true), fee: 0.000205, spendsAmount: false)))

        let events = stakingEvents(manager)
        let topUpEvent = try #require(events.first { $0.isInsufficientFundsForFee })
        #expect(hasOpenFeeCurrencyButton(topUpEvent))
        #expect(title(of: topUpEvent) == Localization.warningBlockedFundsForFeeTitle)
        #expect(!containsInsufficientBalance(events))
        #expect(analyticsLogger.noticeNotEnoughFeeCalls == 1)
        #expect(analyticsLogger.noticeNotEnoughFeeBalances == [0.0001])
    }

    @Test("Token-staked fee-coverage failure keeps the mapped insufficient-fee banner")
    func tokenFeeCoverageFailureKeepsMappedEvent() {
        let (manager, stateSubject) = makeSUT()

        stateSubject.send(.validationError(feeExceedsBalanceError(isFeeCurrency: false), fee: 0.000205))

        let events = stakingEvents(manager)
        #expect(containsInsufficientBalanceForFee(events))
        #expect(!events.contains { $0.isInsufficientFundsForFee })
    }

    @Test("V2 enter fee-coverage failure keeps the generic insufficient-balance banner")
    func v2EnterFeeCoverageFailureKeepsGenericEvent() {
        let (manager, stateSubject) = makeV2SUT(
            action: StakingAction(amount: 0.02, targetType: .empty, type: .stake)
        )

        stateSubject.send(.failure(.transaction(feeExceedsBalanceError(isFeeCurrency: true), fee: 0.000205, spendsAmount: true)))

        let events = stakingEvents(manager)
        #expect(containsInsufficientBalance(events))
        #expect(!events.contains { $0.isInsufficientFundsForFee })
    }

    @Test("V2 fee-only enter validation shows the fee top-up banner on fee-coverage failure")
    func v2FeeOnlyEnterFeeCoverageFailureShowsTopUpBanner() throws {
        let (manager, stateSubject) = makeV2SUT(
            action: StakingAction(amount: 0.02, targetType: .empty, type: .stake)
        )

        stateSubject.send(.failure(.transaction(feeExceedsBalanceError(isFeeCurrency: true), fee: 0.000205, spendsAmount: false)))

        let events = stakingEvents(manager)
        let topUpEvent = try #require(events.first { $0.isInsufficientFundsForFee })
        #expect(hasOpenFeeCurrencyButton(topUpEvent))
        #expect(!containsInsufficientBalance(events))
    }

    @Test("V2 enter that delegates in place shows the top-up banner for a StakeKit gas-reserve failure")
    func v2FeeOnlyEnterGasReserveFailureShowsTopUpBanner() throws {
        let (manager, stateSubject) = makeV2SUT(
            action: StakingAction(amount: 0.02, targetType: .empty, type: .stake),
            enterSpendsAmount: false
        )

        stateSubject.send(.failure(.network(try makeGasReserveFailure())))

        let events = stakingEvents(manager)
        let topUpEvent = try #require(events.first { $0.isInsufficientFundsForFee })
        #expect(hasOpenFeeCurrencyButton(topUpEvent))
        #expect(!events.contains { $0.isInsufficientFundsForFeeReduceAmount })
    }

    @Test("V2 enter that spends the amount keeps the reduce-amount banner for a StakeKit gas-reserve failure")
    func v2EnterGasReserveFailureKeepsReduceAmountBanner() throws {
        let (manager, stateSubject) = makeV2SUT(
            action: StakingAction(amount: 0.02, targetType: .empty, type: .stake)
        )

        stateSubject.send(.failure(.network(try makeGasReserveFailure())))

        let events = stakingEvents(manager)
        #expect(events.contains { $0.isInsufficientFundsForFeeReduceAmount })
        #expect(!events.contains { $0.isInsufficientFundsForFee })
    }

    @Test("Token-staked preflight fee failure shows the top-up banner with the send-style copy")
    func tokenPreflightFeeFailureShowsTopUpBanner() throws {
        let coinItem = TokenItem.blockchain(.init(blockchain, derivationPath: nil))
        let tokenItem = TokenItem.token(
            Token(name: "Tether", symbol: "USDT", contractAddress: "0x1", decimalCount: 6),
            .init(blockchain, derivationPath: nil)
        )
        let (manager, stateSubject) = makeSUT(tokenItem: tokenItem, feeTokenItem: coinItem)

        stateSubject.send(.networkError(StakingPreflightError.insufficientFundsForFee(feeCurrencyBalance: .zero)))

        let events = stakingEvents(manager)
        let topUpEvent = try #require(events.first { $0.isInsufficientFundsForFee })
        #expect(hasOpenFeeCurrencyButton(topUpEvent))
        #expect(hasFeeTokenIcon(topUpEvent))
        #expect(title(of: topUpEvent) == Localization.warningSendBlockedFundsForFeeTitle(coinItem.name))
    }
}

// MARK: - Helpers

private extension StakingNotificationManagerTests {
    /// `StakeKitAPIError` only ever comes off the wire, so an empty body stands in for one here.
    func makeGasReserveFailure(shortfall: Decimal = 0.01, gasTokenSymbol: String = "SOL") throws -> StakeKitHTTPError {
        let apiError = try JSONDecoder().decode(StakeKitAPIError.self, from: Data("{}".utf8))

        return .insufficientGasReserve(shortfallAmount: shortfall, gasTokenSymbol: gasTokenSymbol, apiError: apiError)
    }

    func makeSUT(
        blockchain: Blockchain? = nil,
        tokenItem: TokenItem? = nil,
        feeTokenItem: TokenItem? = nil,
        action: StakingAction = StakingAction(amount: 0.02, targetType: .empty, type: .pending(.withdraw(passthroughs: []))),
        stakedBalance: Decimal? = nil,
        exitMinimumRequirement: Decimal = .zero,
        analyticsLogger: StakingSendAnalyticsLoggerMock = StakingSendAnalyticsLoggerMock()
    ) -> (manager: CommonStakingNotificationManager, stateSubject: CurrentValueSubject<UnstakingModel.State, Never>) {
        let coinItem = TokenItem.blockchain(.init(blockchain ?? self.blockchain, derivationPath: nil))
        let manager = CommonStakingNotificationManager(
            tokenItem: tokenItem ?? coinItem,
            feeTokenItem: feeTokenItem ?? coinItem,
            analyticsLogger: analyticsLogger
        )

        let stateSubject = CurrentValueSubject<UnstakingModel.State, Never>(.loading)
        let provider = UnstakingModelStateProviderStub(
            stateSubject: stateSubject,
            stakingAction: action,
            stakedBalance: stakedBalance ?? action.amount
        )
        let input = StakingNotificationManagerInputStub(
            stakingManagerStatePublisher: Just(makeStakedState(exitMinimumRequirement: exitMinimumRequirement)).eraseToAnyPublisher()
        )

        manager.setup(provider: provider, input: input)

        return (trackForMemoryLeaks(manager), stateSubject)
    }

    func makeV2SUT(
        action: StakingAction,
        enterSpendsAmount: Bool = true,
        analyticsLogger: StakingSendAnalyticsLoggerMock = StakingSendAnalyticsLoggerMock()
    ) -> (manager: CommonStakingNotificationManager, stateSubject: CurrentValueSubject<StakeFlowState, Never>) {
        let tokenItem = TokenItem.blockchain(.init(blockchain, derivationPath: nil))
        let manager = CommonStakingNotificationManager(
            tokenItem: tokenItem,
            feeTokenItem: tokenItem,
            analyticsLogger: analyticsLogger
        )

        let stateSubject = CurrentValueSubject<StakeFlowState, Never>(.loading)
        let provider = StakeModelStateProviderStub(
            stateSubject: stateSubject,
            stakingAction: action,
            stakedBalance: action.amount,
            enterSpendsAmount: enterSpendsAmount
        )
        let input = StakingNotificationManagerInputStub(
            stakingManagerStatePublisher: Just(makeStakedState()).eraseToAnyPublisher()
        )

        manager.setup(provider: provider, input: input)

        return (trackForMemoryLeaks(manager), stateSubject)
    }

    func makeStakedState(exitMinimumRequirement: Decimal = .zero) -> StakingManagerState {
        .staked(
            .init(
                balances: [],
                yieldInfo: makeYieldInfo(exitMinimumRequirement: exitMinimumRequirement),
                canStakeMore: true
            )
        )
    }

    func makeYieldInfo(exitMinimumRequirement: Decimal = .zero) -> StakingYieldInfo {
        StakingYieldInfo(
            id: "solana-sol-native-multivalidator-staking",
            isAvailable: true,
            rewardType: .apy,
            rewardRateValues: RewardRateValues(aprs: [0.05], rewardRate: .zero),
            enterMinimumRequirement: .zero,
            exitMinimumRequirement: exitMinimumRequirement,
            targets: [],
            preferredTargets: [],
            item: StakingTokenItem(network: .solana, name: "Solana", decimals: 9, symbol: "SOL"),
            unbondingPeriod: .days(3),
            warmupPeriod: .days(0),
            rewardClaimingType: .auto,
            rewardScheduleType: .daily,
            maximumStakeAmount: nil
        )
    }

    func stakingEvents(_ manager: CommonStakingNotificationManager) -> [StakingNotificationEvent] {
        manager.notificationInputs.compactMap { $0.settings.event as? StakingNotificationEvent }
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

    func feeExceedsBalanceError(isFeeCurrency: Bool) -> ValidationError {
        .feeExceedsBalance(
            Fee(.init(with: blockchain, value: 0.000205)),
            blockchain: blockchain,
            isFeeCurrency: isFeeCurrency,
            feeCurrencyBalance: 0.0001
        )
    }

    func hasOpenFeeCurrencyButton(_ event: StakingNotificationEvent) -> Bool {
        if case .openFeeCurrency = event.buttonAction?.type {
            return true
        }
        return false
    }

    func hasFeeTokenIcon(_ event: StakingNotificationEvent) -> Bool {
        if case .icon = event.icon.iconType {
            return true
        }
        return false
    }

    func title(of event: StakingNotificationEvent) -> String? {
        if case .string(let title) = event.title {
            return title
        }
        return nil
    }

    func containsInsufficientBalance(_ events: [StakingNotificationEvent]) -> Bool {
        events.contains { event in
            guard case .validationErrorEvent(let validationErrorEvent) = event else {
                return false
            }

            if case .insufficientBalance = validationErrorEvent {
                return true
            }
            return false
        }
    }

    func containsInsufficientBalanceForFee(_ events: [StakingNotificationEvent]) -> Bool {
        events.contains { event in
            guard case .validationErrorEvent(let validationErrorEvent) = event else {
                return false
            }

            if case .insufficientBalanceForFee = validationErrorEvent {
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

private struct StakeModelStateProviderStub: StakeModelStateProvider {
    let stateSubject: CurrentValueSubject<StakeFlowState, Never>
    let stakingAction: StakingAction
    let stakedBalance: Decimal
    let enterSpendsAmount: Bool

    var state: StakeFlowState { stateSubject.value }

    var statePublisher: AnyPublisher<StakeFlowState, Never> {
        stateSubject.eraseToAnyPublisher()
    }
}

private struct StakingNotificationManagerInputStub: StakingNotificationManagerInput {
    let stakingManagerStatePublisher: AnyPublisher<StakingManagerState, Never>
}
