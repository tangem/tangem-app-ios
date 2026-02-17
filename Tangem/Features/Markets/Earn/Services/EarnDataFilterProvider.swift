//
//  EarnDataFilterProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation
import BlockchainSdk

final class EarnDataFilterProvider {
    // MARK: - Dependencies

    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository
    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService

    // MARK: - Private State

    private let _filterTypeValue: CurrentValueSubject<EarnFilterType, Never>
    private let _networkFilterValue: CurrentValueSubject<EarnNetworkFilterType, Never>
    private let _stateSubject = CurrentValueSubject<State, Never>(.idle)
    private var _availableNetworks: [EarnNetworkInfo] = []
    private var _myNetworks: [EarnNetworkInfo] = []

    private var fetchNetworksTask: Task<Void, Never>?

    // MARK: - Public Properties

    var filterPublisher: AnyPublisher<EarnDataFilter, Never> {
        Publishers.CombineLatest(_filterTypeValue, _networkFilterValue)
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .map { provider, args in
                let (type, networkFilter) = args
                let networkIds = provider.resolveNetworkIds(for: networkFilter)
                return EarnDataFilter(type: type, networkIds: networkIds)
            }
            .eraseToAnyPublisher()
    }

    var statePublisher: AnyPublisher<State, Never> {
        _stateSubject.eraseToAnyPublisher()
    }

    var state: State {
        _stateSubject.value
    }

    var currentFilter: EarnDataFilter {
        let networkIds = resolveNetworkIds(for: _networkFilterValue.value)
        return EarnDataFilter(type: _filterTypeValue.value, networkIds: networkIds)
    }

    var supportedFilterTypes: [EarnFilterType] {
        EarnFilterType.allCases
    }

    @MainActor
    var myNetworks: [EarnNetworkInfo] {
        _myNetworks
    }

    @MainActor
    var availableNetworks: [EarnNetworkInfo] {
        _availableNetworks
    }

    var selectedFilterType: EarnFilterType {
        _filterTypeValue.value
    }

    var selectedNetworkFilter: EarnNetworkFilterType {
        _networkFilterValue.value
    }

    var hasActiveFilters: Bool {
        switch (_filterTypeValue.value, _networkFilterValue.value) {
        case (.all, .all):
            return false
        default:
            return true
        }
    }

    let supportedBlockchainsByNetworkId: [String: Blockchain] = Dictionary(
        uniqueKeysWithValues: SupportedBlockchains.all.map { ($0.networkId, $0) }
    )

    // MARK: - Init

    init(initialFilterType: EarnFilterType = .all, initialNetworkFilter: EarnNetworkFilterType = .all) {
        _filterTypeValue = .init(initialFilterType)
        _networkFilterValue = .init(initialNetworkFilter)
    }

    // MARK: - Public Methods

    func didSelectFilterType(_ type: EarnFilterType) {
        _filterTypeValue.send(type)

        if _stateSubject.value == .emptyAvailableNetworks {
            Task { await fetchAvailableNetworks() }
        }
    }

    func didSelectNetworkFilter(_ filter: EarnNetworkFilterType) {
        _networkFilterValue.send(filter)
    }

    func clear() {
        _filterTypeValue.send(.all)
        _networkFilterValue.send(.all)
    }

    func fetchAvailableNetworks() async {
        fetchNetworksTask?.cancel()

        await applyFilterState(state: .loading, networks: [])

        fetchNetworksTask = Task { [weak self] in
            guard let self else { return }

            if let (state, networks) = await loadAvailableNetworks() {
                await applyFilterState(state: state, networks: networks)
            }
        }
    }

    // MARK: - Private Methods

    @MainActor
    private func applyFilterState(state: State, networks: [EarnNetworkInfo]) {
        _availableNetworks = networks
        _stateSubject.send(state)
        updateMyNetworks()
    }

    /// Fills `_myNetworks` with the intersection of backend available networks and user's networks.
    /// Only networks that are both returned by the API and present in the user's wallets are included.
    @MainActor
    private func updateMyNetworks() {
        let userNetworkIds = Set(
            userWalletRepository.models
                .flatMap { $0.accountModelsManager.cryptoAccountModels }
                .flatMap { $0.userTokensManager.userTokens }
                .map(\.networkId)
        )
        _myNetworks = _availableNetworks.filter { userNetworkIds.contains($0.networkId) }
    }

    /// Loads available earn networks from API. Does not mutate instance state; returns result for application on main actor.
    /// Returns `nil` when the task was cancelled (caller should not apply state).
    private func loadAvailableNetworks() async -> (State, [EarnNetworkInfo])? {
        do {
            let request = EarnDTO.Networks.Request(type: nil)
            let response = try await tangemApiService.loadEarnNetworks(requestModel: request)

            guard !Task.isCancelled else { return nil }

            let networks: [EarnNetworkInfo] = response.items.compactMap { item in
                guard let blockchain = supportedBlockchainsByNetworkId[item.networkId] else {
                    return nil
                }
                return EarnNetworkInfo(networkId: blockchain.networkId, networkName: blockchain.displayName)
            }

            AppLogger.tag("Earn").debug("Fetched \(networks.count) available networks")
            let state: State = networks.isEmpty ? .emptyAvailableNetworks : .loaded
            return (state, networks)
        } catch {
            guard !Task.isCancelled else { return nil }

            AppLogger.tag("Earn").error("Failed to fetch available networks", error: error)
            return (.emptyAvailableNetworks, [])
        }
    }

    /// Converts `EarnNetworkFilterType` to an array of network IDs for the API request.
    /// - Returns: `nil` means "no filter" (API will return tokens from all networks).
    ///            Non-empty array means filter by specific networks.
    private func resolveNetworkIds(for filter: EarnNetworkFilterType) -> [String]? {
        switch filter {
        case .all:
            return nil
        case .userNetworks(let networkInfos):
            let networkIds = networkInfos.map { $0.networkId }
            // -1 This is fallback for correct stage receive list of Earns. Confirmed by the system analyst
            return networkIds.isEmpty ? [Constants.dummyNetworkId] : networkIds
        case .specific(let networkInfo):
            return [networkInfo.networkId]
        }
    }
}

// MARK: - State

extension EarnDataFilterProvider {
    enum State {
        case idle
        case loading
        case loaded
        case emptyAvailableNetworks
    }
}

// MARK: - Constants

extension EarnDataFilterProvider {
    enum Constants {
        static let dummyNetworkId = "-1"
    }
}

// MARK: - InjectedValues + earnDataFilterProvider

/// Injected Earn filter provider. Per task requirements, filter state (network, type) must be preserved for the app session — a single instance per key ensures this.
extension InjectedValues {
    var earnDataFilterProvider: EarnDataFilterProvider {
        get { Self[EarnDataFilterProviderKey.self] }
        set { Self[EarnDataFilterProviderKey.self] = newValue }
    }
}

// MARK: - EarnDataFilterProviderKey

private struct EarnDataFilterProviderKey: InjectionKey {
    static var currentValue: EarnDataFilterProvider = .init()
}
