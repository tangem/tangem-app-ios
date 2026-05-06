//
//  CommonStakingTargetAmountLimitProvider.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation
import TangemStaking

final actor CommonStakingTargetAmountLimitProvider {
    private let tangemApiService: TangemApiService
    private let userWalletEventProvider: AnyPublisher<UserWalletRepositoryEvent, Never>

    private var limits: [String: Decimal] = [:]
    private var loadingTask: Task<Void, Never>?
    private var bag: Set<AnyCancellable> = []

    init(
        tangemApiService: TangemApiService,
        userWalletEventProvider: AnyPublisher<UserWalletRepositoryEvent, Never>
    ) {
        self.tangemApiService = tangemApiService
        self.userWalletEventProvider = userWalletEventProvider
    }
}

// MARK: - StakingTargetAmountLimitProvider

extension CommonStakingTargetAmountLimitProvider: StakingTargetAmountLimitProvider {
    func limit(forTargetAddress address: String) async -> Decimal? {
        if let loadingTask {
            _ = await loadingTask.value
        }
        return limits[address.lowercased()]
    }
}

// MARK: - Initializable

extension CommonStakingTargetAmountLimitProvider: Initializable {
    nonisolated func initialize() {
        Task { await self.bind() }
    }
}

// MARK: - Private methods

private extension CommonStakingTargetAmountLimitProvider {
    func bind() {
        userWalletEventProvider
            .sink { [weak self] event in
                Task { await self?.handle(event) }
            }
            .store(in: &bag)
    }

    func handle(_ event: UserWalletRepositoryEvent) {
        switch event {
        case .unlocked:
            startFetch()
        case .locked:
            clearCache()
        default:
            break
        }
    }

    func startFetch() {
        loadingTask?.cancel()
        loadingTask = Task<Void, Never> { [weak self] in
            guard let self else { return }
            await runFetch()
        }
    }

    func runFetch() async {
        // [REDACTED_TODO_COMMENT]
        // Remove the early return below once the endpoint is live; until then `limits` stays
        // empty and `P2PMapper` falls back to `capacity - totalAssets`.
        return

//        do {
//            let response = try await tangemApiService.loadStakingVaultsConfig()
//            let dict = response.vaults.reduce(into: [String: Decimal]()) { result, vault in
//                if let limit = vault.limit {
//                    result[vault.vaultAddress.lowercased()] = limit
//                }
//            }
//            guard !Task.isCancelled else { return }
//            limits = dict
//        } catch {
//            AppLogger.error("Failed to load staking target amount limits", error: error)
//        }
    }

    func clearCache() {
        loadingTask?.cancel()
        loadingTask = nil
        limits = [:]
    }
}
