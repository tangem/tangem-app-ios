//
//  YieldIncentivesTestSupport.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BigInt
import BlockchainSdk
import TangemFoundation
@testable import Tangem

enum YieldIncentivesFixtures {
    static let chainId = 143
    static let userAddress = "0xD7ABce6612079A05e431752cb85Bf7010E40FdF5"
    static let moduleAddress = "0xD4212f886c1B209d06A463C02dF2607cfbF80676"
    static let rewardToken = "0x561AD6156d0106E7a59Ee788759Df7b7Ec679bD0"
    static let calldataHex = "0xb4701e3e0001"

    static func calldata(
        chainId: Int = chainId,
        userAddress: String = userAddress,
        moduleAddress: String? = moduleAddress,
        hasClaimable: Bool = true,
        to: String? = moduleAddress,
        data: String? = calldataHex,
        rewardTokens: [String] = [rewardToken],
        cumulativeAmounts: [String] = ["61086786758864400"],
        totalEstimatedServiceFeeUsd: Decimal = Decimal(string: "0.00025")!,
        claimRecommended: Bool = true
    ) -> YieldClaimCalldata {
        YieldClaimCalldata(
            chainId: chainId,
            userAddress: userAddress,
            moduleAddress: moduleAddress,
            hasClaimable: hasClaimable,
            to: to,
            data: data,
            rewardTokens: rewardTokens,
            cumulativeAmounts: cumulativeAmounts,
            totalEstimatedServiceFeeUsd: totalEstimatedServiceFeeUsd,
            claimRecommended: claimRecommended
        )
    }

    static func reward(
        rewardTokenAddress: String = rewardToken,
        symbol: String = "WMON",
        decimals: Int = 18,
        claimableAmount: BigUInt = BigUInt(stringLiteral: "61086786758864400"),
        pendingAmount: BigUInt = BigUInt(stringLiteral: "1361210927042815"),
        usdValue: Decimal = Decimal(string: "0.00167")!,
        serviceFeeRateBps: Int = 1500,
        estimatedServiceFeeUsd: Decimal = Decimal(string: "0.00025")!,
        estimatedNetValueUsd: Decimal = Decimal(string: "0.00142")!,
        destination: YieldIncentiveReward.Destination = .owner
    ) -> YieldIncentiveReward {
        YieldIncentiveReward(
            rewardTokenAddress: rewardTokenAddress,
            symbol: symbol,
            decimals: decimals,
            claimableAmount: claimableAmount,
            pendingAmount: pendingAmount,
            usdValue: usdValue,
            serviceFeeRateBps: serviceFeeRateBps,
            estimatedServiceFeeUsd: estimatedServiceFeeUsd,
            estimatedNetValueUsd: estimatedNetValueUsd,
            destination: destination
        )
    }

    static func summary(
        moduleAddress: String = moduleAddress,
        rewards: [YieldIncentiveReward] = [reward()],
        lastUpdatedAt: Date = Date(timeIntervalSince1970: 1_790_000_000),
        isClaimRecommended: Bool = true
    ) -> YieldIncentivesRewardsSummary {
        YieldIncentivesRewardsSummary(
            moduleAddress: moduleAddress,
            rewards: rewards,
            lastUpdatedAt: lastUpdatedAt,
            isClaimRecommended: isClaimRecommended
        )
    }

    static func claimFee(value: Decimal = Decimal(string: "0.001")!) -> YieldTransactionFee {
        try! ClaimFee(fees: [Fee(amount(value: value))])
    }

    static func amount(value: Decimal) -> Amount {
        Amount(type: .coin, currencySymbol: "MON", value: value, decimals: 18)
    }

    static func transaction(sourceAddress: String = userAddress) -> BSDKTransaction {
        BSDKTransaction(
            amount: amount(value: 0),
            fee: Fee(amount(value: Decimal(string: "0.001")!)),
            sourceAddress: sourceAddress,
            destinationAddress: moduleAddress,
            changeAddress: sourceAddress
        )
    }

    static func preparedClaim(
        calldata: YieldClaimCalldata = calldata(),
        summary: YieldIncentivesRewardsSummary = summary(),
        to: String = moduleAddress,
        data: Data = Data(hexString: calldataHex),
        fee: YieldTransactionFee = claimFee(),
        preparedAt: Date = Date()
    ) -> YieldIncentivesClaimInteractor.PreparedClaim {
        YieldIncentivesClaimInteractor.PreparedClaim(
            calldata: calldata,
            summary: summary,
            to: to,
            data: data,
            fee: fee,
            preparedAt: preparedAt
        )
    }

    static func activeState(yieldContractAddress: String = moduleAddress) -> YieldModuleManagerStateInfo {
        YieldModuleManagerStateInfo(
            marketInfo: nil,
            state: .active(
                info: YieldSupplyInfo(
                    yieldContractAddress: yieldContractAddress,
                    balance: amount(value: 0),
                    isAllowancePermissionRequired: false,
                    yieldModuleBalanceValue: 0
                ),
                promoStatus: .active
            )
        )
    }

    static func refreshingState(yieldContractAddress: String = moduleAddress) -> YieldModuleManagerStateInfo {
        YieldModuleManagerStateInfo(
            marketInfo: nil,
            state: .loading(cachedState: activeState(yieldContractAddress: yieldContractAddress).state)
        )
    }
}

enum YieldIncentivesTestError: Error {
    case network
    case signatureDeclined
}

final class YieldClaimIncentivesManagerStub: YieldIncentivesManager {
    private let state = OSAllocatedUnfairLock(initialState: State())

    private struct State {
        var summary: YieldIncentivesRewardsSummary?
        var error: Error?
        var incentivesCallCount = 0
        var forceRefreshFlags: [Bool] = []
    }

    var incentivesCallCount: Int {
        state.withLock { $0.incentivesCallCount }
    }

    var forceRefreshFlags: [Bool] {
        state.withLock { $0.forceRefreshFlags }
    }

    init(summary: YieldIncentivesRewardsSummary? = YieldIncentivesFixtures.summary(), error: Error? = nil) {
        state.withLock {
            $0.summary = summary
            $0.error = error
        }
    }

    func incentives(forceRefresh: Bool) async throws -> YieldIncentivesRewardsSummary? {
        let snapshot = state.withLock { state -> (YieldIncentivesRewardsSummary?, Error?) in
            state.incentivesCallCount += 1
            state.forceRefreshFlags.append(forceRefresh)
            return (state.summary, state.error)
        }

        if let error = snapshot.1 {
            throw error
        }

        return snapshot.0
    }

    func claimHistory(forceRefresh: Bool) async throws -> [YieldClaimHistoryEntry]? {
        nil
    }
}

final class YieldClaimDispatcherStub: TransactionDispatcher {
    var hasNFCInteraction: Bool { false }

    func send(transaction: TransactionDispatcherTransactionType) async throws -> TransactionDispatcherResult {
        throw YieldIncentivesTestError.network
    }
}

final class YieldClaimManagerStub: YieldModuleManager {
    struct SubmittedCall: Equatable {
        let to: String
        let dataHex: String
    }

    private let lockedState = OSAllocatedUnfairLock(initialState: State())

    private struct State {
        var feeResult: Result<YieldTransactionFee, Error> = .success(YieldIncentivesFixtures.claimFee())
        var transactionResult: Result<BSDKTransaction, Error> = .success(YieldIncentivesFixtures.transaction())
        var submitResult: Result<String, Error> = .success("0xclaimhash")
        var pendingCleared = true
        var feeCalls: [SubmittedCall] = []
        var builtCalls: [SubmittedCall] = []
        var submittedTransactions: [BSDKTransaction] = []
        var pendingWatchedHashes: [String] = []
    }

    let state: YieldModuleManagerStateInfo?
    let blockchain: Blockchain
    let incentivesManager: YieldIncentivesManager?

    init(
        state: YieldModuleManagerStateInfo? = YieldIncentivesFixtures.activeState(),
        blockchain: Blockchain = .monad(testnet: false),
        incentivesManager: YieldIncentivesManager? = YieldClaimIncentivesManagerStub()
    ) {
        self.state = state
        self.blockchain = blockchain
        self.incentivesManager = incentivesManager
    }

    var feeCalls: [SubmittedCall] {
        lockedState.withLock { $0.feeCalls }
    }

    var builtCalls: [SubmittedCall] {
        lockedState.withLock { $0.builtCalls }
    }

    var submittedTransactions: [BSDKTransaction] {
        lockedState.withLock { $0.submittedTransactions }
    }

    var pendingWatchedHashes: [String] {
        lockedState.withLock { $0.pendingWatchedHashes }
    }

    func setFeeResult(_ result: Result<YieldTransactionFee, Error>) {
        lockedState.withLock { $0.feeResult = result }
    }

    func setTransactionResult(_ result: Result<BSDKTransaction, Error>) {
        lockedState.withLock { $0.transactionResult = result }
    }

    func setSubmitResult(_ result: Result<String, Error>) {
        lockedState.withLock { $0.submitResult = result }
    }

    func setPendingCleared(_ cleared: Bool) {
        lockedState.withLock { $0.pendingCleared = cleared }
    }

    var statePublisher: AnyPublisher<YieldModuleManagerStateInfo?, Never> { Just(state).eraseToAnyPublisher() }
    var tokenId: String { "" }
    var versionChecker: YieldModuleVersionChecker? { nil }
    var swapExecutionRegistryProvider: YieldModuleSwapExecutionRegistryProvider? { nil }

    func claimFee(to: String, data: Data) async throws -> YieldTransactionFee {
        let result = lockedState.withLock { state -> Result<YieldTransactionFee, Error> in
            state.feeCalls.append(SubmittedCall(to: to, dataHex: data.hexString))
            return state.feeResult
        }

        return try result.get()
    }

    func makeClaimTransaction(to: String, data: Data, fee: YieldTransactionFee) async throws -> BSDKTransaction {
        let result = lockedState.withLock { state -> Result<BSDKTransaction, Error> in
            state.builtCalls.append(SubmittedCall(to: to, dataHex: data.hexString))
            return state.transactionResult
        }

        return try result.get()
    }

    func submitClaim(transaction: BSDKTransaction, transactionDispatcher: TransactionDispatcher) async throws -> String {
        let result = lockedState.withLock { state -> Result<String, Error> in
            state.submittedTransactions.append(transaction)
            return state.submitResult
        }

        return try result.get()
    }

    func awaitPendingTransactionCleared(transactionHash: String, timeout: TimeInterval) async -> Bool {
        lockedState.withLock { state in
            state.pendingWatchedHashes.append(transactionHash)
            return state.pendingCleared
        }
    }

    func enterFee() async throws -> YieldTransactionFee { fatalError() }
    func enter(fee: YieldTransactionFee, transactionDispatcher: TransactionDispatcher) async throws -> [String] { fatalError() }
    func exitFee() async throws -> YieldTransactionFee { fatalError() }
    func exit(fee: YieldTransactionFee, transactionDispatcher: TransactionDispatcher) async throws -> [String] { fatalError() }
    func approveFee() async throws -> YieldTransactionFee { fatalError() }
    func approve(fee: YieldTransactionFee, transactionDispatcher: TransactionDispatcher) async throws -> String { fatalError() }
    func currentNetworkFeeParameters() async throws -> EthereumFeeParameters { fatalError() }
    func fetchYieldTokenInfo() async throws -> YieldModuleTokenInfo { fatalError() }
    func fetchChartData() async throws -> YieldChartData { fatalError() }
    func fetchAprHistory(days: Int) async throws -> [YieldIncentiveAprPoint] { fatalError() }
    func sendActivationState() {}
    func sendTransactionSendEvent(sourceAddress: String, transactionHash: String) {}
}

final class YieldClaimNetworkManagerStub: YieldModuleNetworkManager {
    private let lockedState = OSAllocatedUnfairLock(initialState: State())

    private struct State {
        var incentivesResults: [Result<YieldIncentivesRewardsSummary?, Error>] = [.success(YieldIncentivesFixtures.summary())]
        var calldataResult: Result<YieldClaimCalldata, Error> = .success(YieldIncentivesFixtures.calldata())
        var incentivesCallCount = 0
        var calldataCallCount = 0
        var gate: YieldAsyncGate?
        var gatedCallIndex: Int?
    }

    var incentivesCallCount: Int {
        lockedState.withLock { $0.incentivesCallCount }
    }

    var calldataCallCount: Int {
        lockedState.withLock { $0.calldataCallCount }
    }

    func setIncentivesResults(_ results: [Result<YieldIncentivesRewardsSummary?, Error>]) {
        lockedState.withLock { $0.incentivesResults = results }
    }

    func setCalldataResult(_ result: Result<YieldClaimCalldata, Error>) {
        lockedState.withLock { $0.calldataResult = result }
    }

    func gateCall(at index: Int, with gate: YieldAsyncGate) {
        lockedState.withLock {
            $0.gate = gate
            $0.gatedCallIndex = index
        }
    }

    func fetchIncentives(chainId: Int, userAddress: String) async throws -> YieldIncentivesRewardsSummary? {
        let (result, gate) = lockedState.withLock { state -> (Result<YieldIncentivesRewardsSummary?, Error>, YieldAsyncGate?) in
            let index = state.incentivesCallCount
            state.incentivesCallCount += 1

            let result = state.incentivesResults[safe: index] ?? state.incentivesResults.last ?? .success(nil)
            let gate = state.gatedCallIndex == index ? state.gate : nil

            return (result, gate)
        }

        await gate?.wait()

        return try result.get()
    }

    func fetchClaimCalldata(chainId: Int, userAddress: String) async throws -> YieldClaimCalldata {
        let result = lockedState.withLock { state -> Result<YieldClaimCalldata, Error> in
            state.calldataCallCount += 1
            return state.calldataResult
        }

        return try result.get()
    }

    var markets: [YieldModuleMarketInfo] { [] }
    var marketsPublisher: AnyPublisher<[YieldModuleMarketInfo], Never> { Just([]).eraseToAnyPublisher() }

    func updateMarkets() {}
    func fetchYieldTokenInfo(tokenContractAddress: String, chainId: Int) async throws -> YieldModuleTokenInfo { fatalError() }
    func fetchChartData(tokenContractAddress: String, chainId: Int) async throws -> YieldChartData { fatalError() }
    func fetchAprHistory(tokenContractAddress: String, chainId: Int, days: Int) async throws -> [YieldIncentiveAprPoint] { fatalError() }
    func fetchClaimHistory(chainId: Int, userAddress: String) async throws -> [YieldClaimHistoryEntry]? { nil }
    func activate(tokenContractAddress: String, walletAddress: String, chainId: Int, userWalletId: String) async throws {}
    func deactivate(tokenContractAddress: String, walletAddress: String, chainId: Int) async throws {}
    func sendTransactionEvent(txHash: String, operation: YieldModuleOperation, userAddress: String?) async {}
}

final class YieldAsyncGate: Sendable {
    private let state = OSAllocatedUnfairLock(initialState: State())

    private struct State {
        var isOpen = false
        var waiters: [CheckedContinuation<Void, Never>] = []
        var arrivals: [CheckedContinuation<Void, Never>] = []
        var hasArrived = false
    }

    func wait() async {
        let arrivals = state.withLock { state -> [CheckedContinuation<Void, Never>] in
            state.hasArrived = true
            let arrivals = state.arrivals
            state.arrivals = []
            return arrivals
        }

        arrivals.forEach { $0.resume() }

        await withCheckedContinuation { continuation in
            let isOpen = state.withLock { state -> Bool in
                if state.isOpen {
                    return true
                }

                state.waiters.append(continuation)
                return false
            }

            if isOpen {
                continuation.resume()
            }
        }
    }

    func waitForArrival() async {
        await withCheckedContinuation { continuation in
            let hasArrived = state.withLock { state -> Bool in
                if state.hasArrived {
                    return true
                }

                state.arrivals.append(continuation)
                return false
            }

            if hasArrived {
                continuation.resume()
            }
        }
    }

    func open() {
        let waiters = state.withLock { state -> [CheckedContinuation<Void, Never>] in
            state.isOpen = true
            let waiters = state.waiters
            state.waiters = []
            return waiters
        }

        waiters.forEach { $0.resume() }
    }
}

final class ClaimEventRecorder: Sendable {
    private let state = OSAllocatedUnfairLock(initialState: State())
    private nonisolated(unsafe) let cancellable: AnyCancellable

    private struct State {
        var events: [YieldIncentivesClaimTracker.Event] = []
        var settlementWaiters: [CheckedContinuation<Void, Never>] = []
    }

    var events: [YieldIncentivesClaimTracker.Event] {
        state.withLock { $0.events }
    }

    init(tracker: YieldIncentivesClaimTracker) {
        let state = state
        cancellable = tracker.eventPublisher.sink { event in
            let waiters = state.withLock { state -> [CheckedContinuation<Void, Never>] in
                state.events.append(event)

                guard event == .settled else {
                    return []
                }

                let waiters = state.settlementWaiters
                state.settlementWaiters = []
                return waiters
            }

            waiters.forEach { $0.resume() }
        }
    }

    func waitForSettlement() async {
        await withCheckedContinuation { continuation in
            let isSettled = state.withLock { state -> Bool in
                if state.events.contains(.settled) {
                    return true
                }

                state.settlementWaiters.append(continuation)
                return false
            }

            if isSettled {
                continuation.resume()
            }
        }
    }
}

func withInjectedYieldNetworkManager<T>(
    _ manager: YieldModuleNetworkManager,
    operation: () async throws -> T
) async rethrows -> T {
    try await InjectedDependenciesIsolation.shared.run {
        let previous = InjectedValues[\.yieldModuleNetworkManager]
        InjectedValues[\.yieldModuleNetworkManager] = manager
        defer { InjectedValues[\.yieldModuleNetworkManager] = previous }
        return try await operation()
    }
}
