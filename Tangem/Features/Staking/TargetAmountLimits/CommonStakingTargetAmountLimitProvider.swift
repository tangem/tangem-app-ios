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

    private var infos: [String: StakingTargetAmountLimitInfo] = [:]
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
    func snapshot() async -> [String: StakingTargetAmountLimitInfo] {
        if loadingTask == nil, infos.isEmpty {
            startFetch()
        }
        if let loadingTask {
            _ = await loadingTask.value
        }
        return infos
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
        let task = Task<Void, Never> { [weak self] in
            await self?.runFetch()
        }
        loadingTask = task
        Task { [weak self] in
            _ = await task.value
            await self?.clearLoadingTaskIfCurrent(task)
        }
    }

    func clearLoadingTaskIfCurrent(_ task: Task<Void, Never>) {
        if loadingTask == task {
            loadingTask = nil
        }
    }

    func runFetch() async {
        do {
            let response = try await tangemApiService.loadCoinsSettings()
            let vaults = response.staking?.vaults ?? []
            let dict = vaults.reduce(into: [String: StakingTargetAmountLimitInfo]()) { result, vault in
                guard vault.limit != nil else { return }
                result[vault.vaultAddress.lowercased()] = StakingTargetAmountLimitInfo(
                    limit: vault.limit,
                    coefficient: vault.coefficient
                )
            }
            guard !Task.isCancelled else { return }
            infos = dict
        } catch {
            AppLogger.error("Failed to load staking target amount limits", error: error)
        }
    }

    func clearCache() {
        loadingTask?.cancel()
        loadingTask = nil
        infos = [:]
    }
}
