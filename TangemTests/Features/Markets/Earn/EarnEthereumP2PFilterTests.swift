//
//  EarnEthereumP2PFilterTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//

import Foundation
import Testing
import TangemStaking
@testable import Tangem

@Suite("EarnEthereumP2PFilter Tests")
struct EarnEthereumP2PFilterTests {
    @Test("Non-ETH-P2P items only — returns input unchanged, no yield fetch")
    func nonEthItemsReturnUnchanged() async throws {
        let provider = StubStakingYieldInfoProvider(.failure(StubError.shouldNotBeCalled))
        let filter = CommonEarnEthereumP2PFilter(stakingYieldInfoProvider: provider)

        let items: [EarnDTO.List.Item] = [
            .make(networkId: "solana", symbol: "SOL", type: "staking", address: nil),
            .make(networkId: "polygon", symbol: "POL", type: "staking", address: "0xabc"),
            // ETH symbol but not native (has contract address) — must not trigger filter
            .make(networkId: "ethereum", symbol: "ETH", type: "staking", address: "0xdeadbeef"),
        ]

        let result = try await filter.filter(items)

        #expect(result.count == items.count)
        #expect(provider.callCount == 0)
    }

    @Test("All vaults full (no active target) — drop ETH")
    func noActiveVaultsDropsEth() async throws {
        let yield = StakingYieldInfo.makeEthereumP2P(targetLimits: [nil, nil])
        let provider = StubStakingYieldInfoProvider(.success(yield))
        let filter = CommonEarnEthereumP2PFilter(stakingYieldInfoProvider: provider)

        let result = try await filter.filter([.makeEthereumP2P()])

        #expect(result.isEmpty)
    }

    @Test("At least one active vault — keep ETH")
    func anyActiveVaultKeepsEth() async throws {
        let yield = StakingYieldInfo.makeEthereumP2P(targetLimits: [nil, 0.5])
        let provider = StubStakingYieldInfoProvider(.success(yield))
        let filter = CommonEarnEthereumP2PFilter(stakingYieldInfoProvider: provider)

        let result = try await filter.filter([.makeEthereumP2P()])

        #expect(result.count == 1)
    }

    @Test("Provider throws non-cancellation — drop ETH")
    func providerErrorDropsEth() async throws {
        let provider = StubStakingYieldInfoProvider(.failure(StubError.boom))
        let filter = CommonEarnEthereumP2PFilter(stakingYieldInfoProvider: provider)

        let result = try await filter.filter([
            .makeEthereumP2P(),
            .make(networkId: "solana", symbol: "SOL", type: "staking"),
        ])

        #expect(result.count == 1)
        #expect(result.first?.networkId == "solana")
    }

    @Test("Provider throws CancellationError — rethrown")
    func cancellationErrorRethrown() async {
        let provider = StubStakingYieldInfoProvider(.failure(CancellationError()))
        let filter = CommonEarnEthereumP2PFilter(stakingYieldInfoProvider: provider)

        await #expect(throws: CancellationError.self) {
            _ = try await filter.filter([.makeEthereumP2P()])
        }
    }
}

// MARK: - Test fixtures

private enum StubError: Error {
    case boom
    case shouldNotBeCalled
}

private final class StubStakingYieldInfoProvider: StakingYieldInfoProvider, @unchecked Sendable {
    private let result: Result<StakingYieldInfo, Error>
    private(set) var callCount: Int = 0

    init(_ result: Result<StakingYieldInfo, Error>) {
        self.result = result
    }

    func yieldInfo(for integrationId: String) async throws -> StakingYieldInfo {
        callCount += 1
        return try result.get()
    }
}

private extension EarnDTO.List.Item {
    static func make(
        networkId: String,
        symbol: String,
        type: String,
        address: String? = nil
    ) -> EarnDTO.List.Item {
        EarnDTO.List.Item(
            apy: "5.0",
            networkId: networkId,
            rewardType: "apy",
            type: type,
            token: EarnDTO.List.Token(
                id: "\(networkId)-\(symbol)",
                symbol: symbol,
                name: symbol,
                address: address,
                decimalCount: 18
            )
        )
    }

    static func makeEthereumP2P() -> EarnDTO.List.Item {
        make(networkId: "ethereum", symbol: "ETH", type: "staking", address: nil)
    }
}

private extension StakingYieldInfo {
    static func makeEthereumP2P(targetLimits: [Decimal?]) -> StakingYieldInfo {
        let targets = targetLimits.enumerated().map { index, limit in
            StakingTargetInfo(
                address: "0xvault\(index)",
                name: "Vault \(index)",
                preferred: false,
                partner: false,
                image: nil,
                rewardType: .apy,
                rewardRate: 0.05,
                status: limit != nil ? .active : .full,
                maximumStakeAmount: limit
            )
        }
        return StakingYieldInfo(
            id: StakingIntegrationId.ethereumP2P.rawValue,
            isAvailable: targets.contains { $0.status != .full },
            rewardType: .apy,
            rewardRateValues: RewardRateValues(aprs: [0.05], rewardRate: .zero),
            enterMinimumRequirement: .zero,
            exitMinimumRequirement: .zero,
            targets: targets,
            preferredTargets: [],
            item: .ethereum,
            unbondingPeriod: .constant(days: 0),
            warmupPeriod: .constant(days: 0),
            rewardClaimingType: .auto,
            rewardScheduleType: .daily,
            maximumStakeAmount: targets.compactMap(\.maximumStakeAmount).min()
        )
    }
}
