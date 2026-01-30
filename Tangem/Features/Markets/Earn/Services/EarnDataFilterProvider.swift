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

    // [REDACTED_TODO_COMMENT]
    private var tangemApiService: TangemApiService = FakeTangemApiService()

    // MARK: - Private State

    private let _filterTypeValue: CurrentValueSubject<EarnFilterType, Never>
    private let _networkFilterValue: CurrentValueSubject<EarnNetworkFilterType, Never>
    private let _stateSubject = CurrentValueSubject<State, Never>(.idle)
    private var _availableNetworks: [EarnNetworkInfo] = []
    private var _myNetworkIds: [String] = []

    private var fetchNetworksTask: Task<Void, Never>?

    // MARK: - Public Properties

    var filterPublisher: AnyPublisher<EarnDataProvider.Filter, Never> {
        Publishers.CombineLatest(_filterTypeValue, _networkFilterValue)
            .withWeakCaptureOf(self)
            .map { provider, args in
                let (type, networkFilter) = args
                let networkIds = provider.resolveNetworkIds(for: networkFilter, userNetworkIds: provider.myNetworkIds)
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
        let networkIds = resolveNetworkIds(for: _networkFilterValue.value, userNetworkIds: myNetworkIds)
        return EarnDataProvider.Filter(type: _filterTypeValue.value, networkIds: networkIds)
    }

    var supportedFilterTypes: [EarnFilterType] {
        EarnFilterType.allCases
    }

    var myNetworkIds: [String] {
        _myNetworkIds
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
        _myNetworkIds = userWalletRepository.models
            .flatMap { $0.accountModelsManager.cryptoAccountModels }
            .flatMap { $0.userTokensManager.userTokens }
            .map(\.networkId)
            .unique()
    }

    private func loadAvailableNetworks() async {
        do {
            let request = EarnDTO.Networks.Request(type: nil)
            let response = try await tangemApiService.loadEarnNetworks(requestModel: request)

            guard !Task.isCancelled else { return }

            _availableNetworks = response.items.map { EarnNetworkInfo(networkId: $0.networkId) }
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
    private func resolveNetworkIds(for filter: EarnNetworkFilterType, userNetworkIds: [String]) -> [String]? {
        switch filter {
        case .all:
            return nil
        case .userNetworks:
            return userNetworkIds.isEmpty ? nil : userNetworkIds
        case .specific(let networkIds):
            return Array(networkIds)
        }
    }
}
