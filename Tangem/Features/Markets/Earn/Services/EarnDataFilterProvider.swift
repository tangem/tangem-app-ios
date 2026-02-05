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

// MARK: - State

extension EarnDataFilterProvider {
    enum State {
        case idle
        case loading
        case loaded
        case emptyAvailableNetworks
    }
}

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

    var filterPublisher: AnyPublisher<EarnDataProvider.Filter, Never> {
        Publishers.CombineLatest(_filterTypeValue, _networkFilterValue)
            .withWeakCaptureOf(self)
            .map { provider, args in
                let (type, networkFilter) = args
                let networkIds = provider.resolveNetworkIds(for: networkFilter)
                return EarnDataProvider.Filter(type: type, networkIds: networkIds)
            }
            .eraseToAnyPublisher()
    }

    var statePublisher: AnyPublisher<State, Never> {
        _stateSubject.eraseToAnyPublisher()
    }

    var state: State {
        _stateSubject.value
    }

    var currentFilter: EarnDataProvider.Filter {
        let networkIds = resolveNetworkIds(for: _networkFilterValue.value)
        return EarnDataProvider.Filter(type: _filterTypeValue.value, networkIds: networkIds)
    }

    var supportedFilterTypes: [EarnFilterType] {
        EarnFilterType.allCases
    }

    var myNetworks: [EarnNetworkInfo] {
        _myNetworks
    }

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

    var supportedBlockchainsByNetworkId: [String: Blockchain] = Dictionary(
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
        _stateSubject.send(.loading)

        fetchNetworksTask = Task { [weak self] in
            guard let self else { return }

            updateMyNetworkIds()
            await loadAvailableNetworks()
        }

        await fetchNetworksTask?.value
    }

    // MARK: - Private Methods

    private func updateMyNetworkIds() {
        _myNetworks = userWalletRepository.models
            .flatMap { $0.accountModelsManager.cryptoAccountModels }
            .flatMap { $0.userTokensManager.userTokens }
            .map { EarnNetworkInfo(networkId: $0.networkId, networkName: $0.name) }
            .unique()
    }

    private func loadAvailableNetworks() async {
        do {
            let request = EarnDTO.Networks.Request(type: nil)
            let response = try await tangemApiService.loadEarnNetworks(requestModel: request)

            guard !Task.isCancelled else { return }

            _availableNetworks = response.items.compactMap { item in
                guard let blockchain = supportedBlockchainsByNetworkId[item.networkId] else {
                    return nil
                }

                return EarnNetworkInfo(networkId: blockchain.networkId, networkName: blockchain.displayName)
            }

            _stateSubject.send(_availableNetworks.isEmpty ? .emptyAvailableNetworks : .loaded)
            AppLogger.tag("Earn").debug("Fetched \(_availableNetworks.count) available networks")
        } catch {
            guard !Task.isCancelled else { return }

            AppLogger.tag("Earn").error("Failed to fetch available networks", error: error)
            _stateSubject.send(.emptyAvailableNetworks)
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
            return networkIds.isEmpty ? nil : networkIds
        case .specific(let networkInfo):
            return [networkInfo.networkId]
        }
    }
}
