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

final class EarnDataFilterProvider {
    // MARK: - Dependencies

    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    // [REDACTED_TODO_COMMENT]
    private var tangemApiService: TangemApiService = FakeTangemApiService()

    // MARK: - Private State

    private let _filterTypeValue: CurrentValueSubject<EarnFilterType, Never>
    private let _networkFilterValue: CurrentValueSubject<EarnNetworkFilterType, Never>
    private let _userNetworkIdsSubject = CurrentValueSubject<[String]?, Never>(nil)
    private let _networkLoadingResultSubject = CurrentValueSubject<LoadingResult<[EarnNetworkInfo], Error>, Never>(.success([]))

    private var bag = Set<AnyCancellable>()
    private var fetchNetworksTask: Task<Void, Never>?

    // MARK: - Public Properties

    var filterPublisher: AnyPublisher<EarnDataProvider.Filter, Never> {
        Publishers
            .CombineLatest3(_filterTypeValue, _networkFilterValue, _userNetworkIdsSubject)
            .withWeakCaptureOf(self)
            .map { provider, args in
                let (type, networkFilter, userIds) = args
                let networkIds = provider.resolveNetworkIds(for: networkFilter, userNetworkIds: userIds) ?? nil
                return EarnDataProvider.Filter(type: type, networkIds: networkIds)
            }
            .eraseToAnyPublisher()
    }

    var availableNetworksPublisher: AnyPublisher<[EarnNetworkInfo], Never> {
        _networkLoadingResultSubject
            .map { result in
                if case .success(let list) = result { return list }
                return []
            }
            .eraseToAnyPublisher()
    }

    var networkLoadingStatePublisher: AnyPublisher<LoadingResult<[EarnNetworkInfo], Error>, Never> {
        _networkLoadingResultSubject.eraseToAnyPublisher()
    }

    var currentFilter: EarnDataProvider.Filter {
        let networkIds = resolveNetworkIds(for: _networkFilterValue.value, userNetworkIds: _userNetworkIdsSubject.value)
        return EarnDataProvider.Filter(type: _filterTypeValue.value, networkIds: networkIds)
    }

    var supportedFilterTypes: [EarnFilterType] {
        EarnFilterType.allCases
    }

    var availableNetworks: [EarnNetworkInfo] {
        if case .success(let list) = _networkLoadingResultSubject.value { return list }
        return []
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

        let userNetworkIds = userWalletRepository.models
            .flatMap { $0.accountModelsManager.cryptoAccountModels }
            .flatMap { $0.userTokensManager.userTokens }
            .map(\.networkId)
            .unique()
        _userNetworkIdsSubject.send(userNetworkIds.isEmpty ? nil : userNetworkIds)

        bind()
    }

    // MARK: - Public Methods

    func didSelectFilterType(_ type: EarnFilterType) {
        _filterTypeValue.send(type)
    }

    func didSelectNetworkFilter(_ filter: EarnNetworkFilterType) {
        _networkFilterValue.send(filter)
    }

    func setUserNetworkIds(_ ids: [String]?) {
        _userNetworkIdsSubject.send(ids)
    }

    /// Converts `EarnNetworkFilterType` to an array of network IDs for the API request.
    /// - Returns: `nil` means "no filter" (API will return tokens from all networks).
    ///            Non-empty array means filter by specific networks.
    func resolveNetworkIds(for filter: EarnNetworkFilterType, userNetworkIds: [String]?) -> [String]? {
        switch filter {
        case .all:
            return nil
        case .userNetworks:
            guard let userNetworkIds, !userNetworkIds.isEmpty else { return nil }
            return userNetworkIds
        case .specific(let networkIds):
            return Array(networkIds)
        }
    }

    func fetchAvailableNetworks() async {
        let currentType = _filterTypeValue.value
        await fetchAvailableNetworks(for: currentType)
    }

    // MARK: - Private Methods

    private func bind() {
        _filterTypeValue
            .dropFirst()
            .removeDuplicates()
            .sink { [weak self] newType in
                guard let self else { return }

                // Reset network filter when type changes (available networks may differ)
                _networkFilterValue.send(.all)

                // Reload networks for the new type
                Task { [weak self] in
                    await self?.fetchAvailableNetworks(for: newType)
                }
            }
            .store(in: &bag)
    }

    private func fetchAvailableNetworks(for filterType: EarnFilterType) async {
        fetchNetworksTask?.cancel()
        _networkLoadingResultSubject.send(.loading)

        fetchNetworksTask = Task { [weak self] in
            guard let self else { return }

            do {
                let apiType = filterType.apiValue
                let request = EarnDTO.Networks.Request(type: apiType)
                let response = try await tangemApiService.loadEarnNetworks(requestModel: request)

                if Task.isCancelled { return }

                let infos = response.items.map { item in
                    EarnNetworkInfo(networkId: item.networkId)
                }

                _networkLoadingResultSubject.send(.success(infos))
                AppLogger.tag("Earn").debug("Fetched \(infos.count) available networks for type: \(filterType)")
            } catch {
                if Task.isCancelled { return }
                AppLogger.tag("Earn").error("Failed to fetch available networks", error: error)
                _networkLoadingResultSubject.send(.failure(error))
            }
        }

        await fetchNetworksTask?.value
    }
}
