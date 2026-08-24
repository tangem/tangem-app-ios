//
//  EarnApyResolverTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import Testing
import BlockchainSdk
@testable import Tangem
@testable import TangemStaking

@Suite("EarnApyResolver")
struct EarnApyResolverTests {
    typealias SUT = EarnApyResolver

    enum StakingCache: CaseIterable {
        case loadingStaked
        case loadingAvailable
        case loadingErrorStaked
        case unavailableRegionAvailable
    }

    enum NothingToEarn: CaseIterable {
        case yieldMarketDisabled
        case stakingLoading
        case noManagers
        case notEnabled
        case temporaryUnavailable
        case yieldNoMarketInfoInactive
        case yieldFailedNoCacheMarketDisabled
    }

    // MARK: - Product picking

    @Test("Neither product active: the higher rate wins — yield over staking")
    func inactivePicksHigherRateYieldWins() {
        let yield = makeMarketStateInfo(apy: 0.10, isMarketActive: true)
        let walletModel = makeWalletModel(staking: makeAvailableStaking(apy: 0.05), yield: yield)

        expectResolve(walletModel, product: .yieldSupply, apy: 0.10, isActive: false)
    }

    @Test("Neither product active: the higher rate wins — staking over yield")
    func inactivePicksHigherRateStakingWins() {
        let yield = makeMarketStateInfo(apy: 0.10, isMarketActive: true)
        let walletModel = makeWalletModel(staking: makeAvailableStaking(apy: 0.20), yield: yield)

        expectResolve(walletModel, product: .staking, apy: 0.20, isActive: false)
    }

    @Test("An active product wins even when the other offers a higher rate")
    func activeWinsOverHigherInactive() {
        let yield = makeMarketStateInfo(apy: 0.50, isMarketActive: true)
        let walletModel = makeWalletModel(staking: makeActiveStaking(apy: 0.03), yield: yield)

        expectResolve(walletModel, product: .staking, apy: 0.03, isActive: true)
    }

    // MARK: - Yield supply

    @Test("Yield-only, market enabled and not active: offered at the market rate")
    func yieldMarketAvailable() {
        let yield = makeMarketStateInfo(apy: 0.08, isMarketActive: true)
        let walletModel = makeWalletModel(staking: nil, yield: yield)

        expectResolve(walletModel, product: .yieldSupply, apy: 0.08, isActive: false)
    }

    @Test("Active on-chain yield position is recognized even without a market rate")
    func activeYieldOutlivesDisabledMarket() {
        let yield = YieldModuleManagerStateInfo(marketInfo: nil, state: .active(info: .stub, promoStatus: .active))
        let walletModel = makeWalletModel(staking: nil, yield: yield)

        expectResolve(walletModel, product: .yieldSupply, apy: 0, isActive: true)
    }

    // MARK: - Cached fallback (loading / error / region block)

    @Test(arguments: StakingCache.allCases)
    func stakingServedFromCache(_ scenario: StakingCache) {
        let (state, apy, isActive) = stakingCacheFixture(scenario)
        let walletModel = makeWalletModel(staking: state, yield: nil)

        expectResolve(walletModel, product: .staking, apy: apy, isActive: isActive)
    }

    // MARK: - Yield processing counts as active

    @Test("Yield .processing(.enter) is treated as an active position, outliving a disabled market")
    func yieldProcessingEnterIsTreatedAsActive() {
        let marketInfo = makeMarketInfo(apy: 0.08, isActive: false)
        let yield = YieldModuleManagerStateInfo(marketInfo: marketInfo, state: .processing(action: .enter))
        let walletModel = makeWalletModel(staking: nil, yield: yield)

        expectResolve(walletModel, product: .yieldSupply, apy: 0.08, isActive: true)
    }

    @Test("Yield .processing(.exit) with no market rate is treated as active with apy 0")
    func yieldProcessingExitIsTreatedAsActive() {
        let yield = YieldModuleManagerStateInfo(marketInfo: nil, state: .processing(action: .exit))
        let walletModel = makeWalletModel(staking: nil, yield: yield)

        expectResolve(walletModel, product: .yieldSupply, apy: 0, isActive: true)
    }

    // MARK: - Both products active: tie broken by APY

    @Test("Both products active: the higher APY wins — yield over staking")
    func bothActivePicksHigherApyYieldWins() {
        let yield = makeActiveMarketStateInfo(apy: 0.20)
        let walletModel = makeWalletModel(staking: makeActiveStaking(apy: 0.10), yield: yield)

        expectResolve(walletModel, product: .yieldSupply, apy: 0.20, isActive: true)
    }

    @Test("Both products active: the higher APY wins — staking over yield")
    func bothActivePicksHigherApyStakingWins() {
        let yield = makeActiveMarketStateInfo(apy: 0.10)
        let walletModel = makeWalletModel(staking: makeActiveStaking(apy: 0.20), yield: yield)

        expectResolve(walletModel, product: .staking, apy: 0.20, isActive: true)
    }

    // MARK: - Equal-APY tie-break

    @Test("Both active with equal APY: yield wins the tie (candidate order)")
    func bothActiveEqualApyYieldWinsTie() {
        let yield = makeActiveMarketStateInfo(apy: 0.10)
        let walletModel = makeWalletModel(staking: makeActiveStaking(apy: 0.10), yield: yield)

        expectResolve(walletModel, product: .yieldSupply, apy: 0.10, isActive: true)
    }

    // MARK: - Yield cached / failed fallback

    @Test("Yield .loading over a cached active position stays active (a refresh doesn't drop it)")
    func yieldLoadingWithCachedActiveStaysActive() {
        let marketInfo = makeMarketInfo(apy: 0.08, isActive: false)
        let yield = YieldModuleManagerStateInfo(
            marketInfo: marketInfo,
            state: .loading(cachedState: .active(info: .stub, promoStatus: .active))
        )
        let walletModel = makeWalletModel(staking: nil, yield: yield)

        expectResolve(walletModel, product: .yieldSupply, apy: 0.08, isActive: true)
    }

    @Test("Yield .failedToLoad over a cached active position stays active, apy 0 without a market rate")
    func yieldFailedToLoadWithCachedActiveStaysActive() {
        let yield = YieldModuleManagerStateInfo(
            marketInfo: nil,
            state: .failedToLoad(error: "err", cachedState: .active(info: .stub, promoStatus: .active))
        )
        let walletModel = makeWalletModel(staking: nil, yield: yield)

        expectResolve(walletModel, product: .yieldSupply, apy: 0, isActive: true)
    }

    @Test("Yield .failedToLoad with no cache but an enabled market: offered at the market rate, not active")
    func yieldFailedToLoadNoCacheMarketAvailable() {
        let marketInfo = makeMarketInfo(apy: 0.06, isActive: true)
        let yield = YieldModuleManagerStateInfo(marketInfo: marketInfo, state: .failedToLoad(error: "err", cachedState: nil))
        let walletModel = makeWalletModel(staking: nil, yield: yield)

        expectResolve(walletModel, product: .yieldSupply, apy: 0.06, isActive: false)
    }

    // MARK: - Nothing to earn

    @Test(arguments: NothingToEarn.allCases)
    func returnsNilWhenNothingToEarn(_ scenario: NothingToEarn) {
        #expect(SUT().resolve(for: makeWalletModel(for: scenario)) == nil)
    }
}

// MARK: - Assertions

private extension EarnApyResolverTests {
    func expectResolve(
        _ walletModel: WalletModelTestsMock,
        product: EarnApyInfo.Product,
        apy: Decimal,
        isActive: Bool,
        sourceLocation: SourceLocation = .init(fileID: #fileID, filePath: #filePath, line: #line, column: #column)
    ) {
        let info = SUT().resolve(for: walletModel)
        #expect(info?.product == product, sourceLocation: sourceLocation)
        #expect(info?.apy == apy, sourceLocation: sourceLocation)
        #expect(info?.isActive == isActive, sourceLocation: sourceLocation)
    }
}

// MARK: - Fixtures

private extension EarnApyResolverTests {
    func makeWalletModel(
        staking: StakingManagerState?,
        yield: YieldModuleManagerStateInfo?
    ) -> WalletModelTestsMock {
        let walletModel = WalletModelTestsMock(fiatBalance: 0, priceChange24h: nil)
        walletModel.stakingManagerMock = staking.map(StakingManagerStub.init)
        walletModel.yieldModuleManagerMock = yield.map(YieldModuleManagerStub.init)
        return walletModel
    }

    func makeMarketInfo(apy: Decimal, isActive: Bool) -> YieldModuleMarketInfo {
        YieldModuleMarketInfo(
            tokenContractAddress: "",
            apy: apy,
            isActive: isActive,
            chainId: nil,
            maxFeeNative: nil,
            maxFeeUSD: nil
        )
    }

    func makeMarketStateInfo(apy: Decimal, isMarketActive: Bool) -> YieldModuleManagerStateInfo {
        YieldModuleManagerStateInfo(
            marketInfo: makeMarketInfo(apy: apy, isActive: isMarketActive),
            state: .notActive(promoStatus: .undefined)
        )
    }

    func makeActiveMarketStateInfo(apy: Decimal) -> YieldModuleManagerStateInfo {
        YieldModuleManagerStateInfo(
            marketInfo: makeMarketInfo(apy: apy, isActive: true),
            state: .active(info: .stub, promoStatus: .active)
        )
    }

    func makeAvailableStaking(apy: Decimal) -> StakingManagerState {
        .availableToStake(makeStakingYieldInfo(apy: apy))
    }

    func makeActiveStaking(apy: Decimal) -> StakingManagerState {
        .staked(.init(balances: [], yieldInfo: makeStakingYieldInfo(apy: apy), canStakeMore: false))
    }

    func makeCachedStaking(apy: Decimal, stakeState: CachedStakeState) -> CachedStakingManagerState {
        CachedStakingManagerState(rewardType: .apy, apy: apy, stakeState: stakeState, date: Date())
    }

    func makeStakingYieldInfo(apy: Decimal) -> StakingYieldInfo {
        StakingYieldInfo(
            id: "test",
            isAvailable: true,
            rewardType: .apy,
            rewardRateValues: .single(apy),
            enterMinimumRequirement: 0,
            exitMinimumRequirement: 0,
            targets: [],
            preferredTargets: [],
            item: StakingTokenItem(network: .tron, contractAddress: nil, name: "", decimals: 0, symbol: ""),
            unbondingPeriod: .days(0),
            warmupPeriod: .days(0),
            rewardClaimingType: .manual,
            rewardScheduleType: .daily,
            maximumStakeAmount: nil
        )
    }

    func makeWalletModel(for scenario: NothingToEarn) -> WalletModelTestsMock {
        switch scenario {
        case .yieldMarketDisabled:
            makeWalletModel(staking: nil, yield: makeMarketStateInfo(apy: 0.08, isMarketActive: false))
        case .stakingLoading:
            makeWalletModel(staking: .loading(cached: nil), yield: nil)
        case .noManagers:
            makeWalletModel(staking: nil, yield: nil)
        case .notEnabled:
            makeWalletModel(staking: .notEnabled, yield: nil)
        case .temporaryUnavailable:
            makeWalletModel(staking: .temporaryUnavailable(makeStakingYieldInfo(apy: 0.09)), yield: nil)
        case .yieldNoMarketInfoInactive:
            makeWalletModel(
                staking: nil,
                yield: YieldModuleManagerStateInfo(
                    marketInfo: nil,
                    state: .notActive(promoStatus: .undefined)
                )
            )
        case .yieldFailedNoCacheMarketDisabled:
            makeWalletModel(
                staking: nil,
                yield: YieldModuleManagerStateInfo(
                    marketInfo: makeMarketInfo(apy: 0.06, isActive: false),
                    state: .failedToLoad(error: "err", cachedState: nil)
                )
            )
        }
    }

    func stakingCacheFixture(_ scenario: StakingCache) -> (state: StakingManagerState, apy: Decimal, isActive: Bool) {
        switch scenario {
        case .loadingStaked:
            (.loading(cached: makeCachedStaking(apy: 0.07, stakeState: .staked(balance: 100))), 0.07, true)
        case .loadingAvailable:
            (.loading(cached: makeCachedStaking(apy: 0.04, stakeState: .availableToStake)), 0.04, false)
        case .loadingErrorStaked:
            (.loadingError("err", cached: makeCachedStaking(apy: 0.07, stakeState: .staked(balance: 100))), 0.07, true)
        case .unavailableRegionAvailable:
            (.unavailableInRegion(cached: makeCachedStaking(apy: 0.04, stakeState: .availableToStake)), 0.04, false)
        }
    }
}

// MARK: - Doubles

private final class StakingManagerStub: StakingManager {
    let state: StakingManagerState

    init(state: StakingManagerState) {
        self.state = state
    }

    var balances: [StakingBalance]? { nil }
    var statePublisher: AnyPublisher<StakingManagerState, Never> { Just(state).eraseToAnyPublisher() }
    var updateWalletBalancesPublisher: AnyPublisher<Void, Never> { Empty<Void, Never>().eraseToAnyPublisher() }
    var allowanceAddress: String? { nil }
    var tosURL: URL { URL(string: "https://tangem.com")! }
    var privacyPolicyURL: URL { URL(string: "https://tangem.com")! }

    func updateState(loadActions: Bool, source: StakingUpdateSource) async {}
    func estimateFee(action: StakingAction) async throws -> Decimal { fatalError() }
    func transaction(action: StakingAction) async throws -> StakingTransactionAction { fatalError() }
    func transactionDidSent(action: StakingAction) {}
}

private final class YieldModuleManagerStub: YieldModuleManager {
    let state: YieldModuleManagerStateInfo?

    init(state: YieldModuleManagerStateInfo) {
        self.state = state
    }

    var statePublisher: AnyPublisher<YieldModuleManagerStateInfo?, Never> { Just(state).eraseToAnyPublisher() }
    var blockchain: Blockchain { .ethereum(testnet: false) }
    var tokenId: String { "" }
    var versionChecker: YieldModuleVersionChecker? { nil }
    var swapExecutionRegistryProvider: YieldModuleSwapExecutionRegistryProvider? { nil }

    func enterFee() async throws -> YieldTransactionFee { fatalError() }
    func enter(fee: YieldTransactionFee, transactionDispatcher: TransactionDispatcher) async throws -> [String] { fatalError() }
    func exitFee() async throws -> YieldTransactionFee { fatalError() }
    func exit(fee: YieldTransactionFee, transactionDispatcher: TransactionDispatcher) async throws -> [String] { fatalError() }
    func approveFee() async throws -> YieldTransactionFee { fatalError() }
    func approve(fee: YieldTransactionFee, transactionDispatcher: TransactionDispatcher) async throws -> String { fatalError() }
    func currentNetworkFeeParameters() async throws -> EthereumFeeParameters { fatalError() }
    func fetchYieldTokenInfo() async throws -> YieldModuleTokenInfo { fatalError() }
    func fetchChartData() async throws -> YieldChartData { fatalError() }
    func sendActivationState() {}
    func sendTransactionSendEvent(sourceAddress: String, transactionHash: String) {}
}

private extension YieldSupplyInfo {
    static let stub = YieldSupplyInfo(
        yieldContractAddress: "",
        balance: Amount(type: .coin, currencySymbol: "ETH", value: 0, decimals: 18),
        isAllowancePermissionRequired: false,
        yieldModuleBalanceValue: 0
    )
}
