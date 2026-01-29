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

@MainActor
final class EarnDataFilterProvider {
    // MARK: - Dependencies

    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService

    // MARK: - Private State

    private let _filterTypeValue: CurrentValueSubject<EarnFilterType, Never>
    private let _networkFilterValue: CurrentValueSubject<EarnNetworkFilterType, Never>
    private let _userNetworkIdsSubject = CurrentValueSubject<[String]?, Never>(nil)
    private let _networkLoadingResultSubject = CurrentValueSubject<LoadingResult<[EarnNetworkInfo], Error>, Never>(.loading)

    // MARK: - Public Properties

    var filterPublisher: AnyPublisher<EarnDataProvider.Filter, Never> {
        Publishers.CombineLatest3(_filterTypeValue, _networkFilterValue, _userNetworkIdsSubject)
            .map { [weak self] type, networkFilter, userIds in
                let networkIds = self?.resolveNetworkIds(for: networkFilter, userNetworkIds: userIds) ?? nil
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

    private let iconBuilder = IconURLBuilder()
    private var fetchNetworksTask: Task<Void, Never>?

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

    func setUserNetworkIds(_ ids: [String]?) {
        _userNetworkIdsSubject.send(ids)
    }

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
        guard !_networkLoadingResultSubject.value.isLoading else { return }

        fetchNetworksTask?.cancel()
        _networkLoadingResultSubject.send(.loading)

        fetchNetworksTask = Task { [weak self] in
            guard let self else { return }

            do {
                let request = EarnDTO.List.Request(
                    isForEarn: true,
                    page: 1,
                    limit: 100,
                    type: nil,
                    network: nil
                )
                let response = try await tangemApiService.loadEarnYieldMarkets(requestModel: request)

                if Task.isCancelled { return }

                let networkIds = Set(response.items.map(\.networkId))
                let infos = networkIds.sorted().map { id in
                    EarnNetworkInfo(id: id, name: id.capitalized)
                }

                _networkLoadingResultSubject.send(.success(infos))
                AppLogger.tag("Earn").debug("Fetched \(infos.count) available networks")
            } catch {
                if Task.isCancelled { return }
                AppLogger.tag("Earn").error("Failed to fetch available networks", error: error)
                _networkLoadingResultSubject.send(.failure(error))
            }
        }

        await fetchNetworksTask?.value
    }

    // MARK: - Private Methods
}
