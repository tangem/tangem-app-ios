//
//  EarnDataProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation
import TangemStaking

protocol EarnDataProvider: AnyObject {
    var eventPublisher: AnyPublisher<EarnDataEvent, Never> { get }
    var mostlyUsedEventPublisher: AnyPublisher<EarnDataMostlyUsedEvent, Never> { get }
    var canFetchMore: Bool { get }

    func applyMostlyUsedTokens(_ tokens: [EarnTokenModel])
    func refreshMostlyUsedTokens()

    func reset()
    func fetch(with filter: EarnDataFilter)
    func fetchMore()
}

final class CommonEarnDataService: EarnDataProvider {
    // MARK: - Dependencies

    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService
    @Injected(\.stakingYieldInfoProvider) private var stakingYieldInfoProvider: StakingYieldInfoProvider

    // MARK: - Subjects

    private let _eventSubject = PassthroughSubject<EarnDataEvent, Never>()
    private let _mostlyUsedEventSubject = PassthroughSubject<EarnDataMostlyUsedEvent, Never>()

    var eventPublisher: AnyPublisher<EarnDataEvent, Never> {
        _eventSubject.eraseToAnyPublisher()
    }

    var mostlyUsedEventPublisher: AnyPublisher<EarnDataMostlyUsedEvent, Never> {
        _mostlyUsedEventSubject.eraseToAnyPublisher()
    }

    // MARK: - Public Properties

    var canFetchMore: Bool {
        !isLoading && hasNext
    }

    // MARK: - Private Properties

    private(set) var isLoading: Bool = false

    private var currentPage: Int = 1
    private var hasNext: Bool = true
    private var hasLoadedItems: Bool = false
    private var lastFilter: EarnDataFilter?

    private let limitPerPage: Int = 20
    private let repeatRequestDelayInSeconds: TimeInterval = 10
    private let mapper = EarnModelMapper()

    private var taskCancellable: AnyCancellable?
    private var scheduledFetchTask: AnyCancellable?
    private var isScheduledFetchPending: Bool = false
    private var mostlyUsedUpdateTask: AnyCancellable?

    // MARK: - Init

    deinit {
        mostlyUsedUpdateTask?.cancel()
    }

    // MARK: - Public Methods

    func applyMostlyUsedTokens(_ tokens: [EarnTokenModel]) {
        _mostlyUsedEventSubject.send(.loaded(items: tokens))
    }

    func refreshMostlyUsedTokens() {
        mostlyUsedUpdateTask?.cancel()
        _mostlyUsedEventSubject.send(.loading)

        mostlyUsedUpdateTask = runTask(in: self) { provider in
            do {
                let requestModel = EarnDTO.List.Request(
                    isForEarn: true,
                    page: nil,
                    limit: Constants.mostlyUsedLimit,
                    type: nil,
                    networkIds: nil
                )

                let response = try await provider.tangemApiService.loadEarnYieldMarkets(requestModel: requestModel)
                let filteredItems = try await provider.filterUnavailableItems(response.items)
                let models = filteredItems.map { provider.mapper.mapToEarnTokenModel(from: $0) }

                await MainActor.run {
                    provider.applyMostlyUsedTokens(models)
                }
            } catch {
                if error.isCancellationError { return }

                AppLogger.tag("Earn").error("Failed to refresh mostly used earn tokens", error: error)
                await MainActor.run {
                    provider._mostlyUsedEventSubject.send(.failed(error: error))
                }
            }
        }.eraseToAnyCancellable()
    }

    func reset() {
        mostlyUsedUpdateTask?.cancel()
        mostlyUsedUpdateTask = nil

        lastFilter = nil
        clearItems()
        _eventSubject.send(.cleared)
        isLoading = false
    }

    func fetch(with filter: EarnDataFilter) {
        _eventSubject.send(.loading)
        isLoading = true

        if lastFilter != filter {
            clearItems()
        }

        if isScheduledFetchPending {
            scheduledFetchTask?.cancel()
            scheduledFetchTask = nil
            isScheduledFetchPending = false
        }

        lastFilter = filter

        taskCancellable?.cancel()
        taskCancellable = Task { [weak self] in
            guard let self else { return }

            do {
                let response = try await loadItems(with: filter)
                await handleFetchResult(.success(response))
            } catch {
                await handleFetchResult(.failure(error))
            }
        }.eraseToAnyCancellable()
    }

    func fetchMore() {
        guard canFetchMore, let lastFilter else { return }
        fetch(with: lastFilter)
    }

    // MARK: - Private Methods

    private func clearItems() {
        currentPage = 1
        hasNext = true
        hasLoadedItems = false

        if scheduledFetchTask != nil {
            scheduledFetchTask?.cancel()
            scheduledFetchTask = nil
            isScheduledFetchPending = false
        }

        _eventSubject.send(.startInitialFetch)
    }

    private func loadItems(with filter: EarnDataFilter) async throws -> EarnDTO.List.Response {
        let requestModel = EarnDTO.List.Request(
            isForEarn: false,
            page: currentPage,
            limit: limitPerPage,
            type: filter.type.apiValue,
            networkIds: filter.networkIds
        )

        let response = try await tangemApiService.loadEarnYieldMarkets(requestModel: requestModel)
        let filteredItems = try await filterUnavailableItems(response.items)
        return EarnDTO.List.Response(items: filteredItems, meta: response.meta)
    }

    private func filterUnavailableItems(_ items: [EarnDTO.List.Item]) async throws -> [EarnDTO.List.Item] {
        guard items.contains(where: isEthereumP2PStakingItem) else { return items }

        let isAvailable: Bool
        do {
            let yield = try await stakingYieldInfoProvider.yieldInfo(for: StakingIntegrationId.ethereumP2P.rawValue)
            isAvailable = yield.isAvailable
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            return items
        }
        guard !isAvailable else { return items }
        return items.filter { !isEthereumP2PStakingItem($0) }
    }

    private func isEthereumP2PStakingItem(_ item: EarnDTO.List.Item) -> Bool {
        item.networkId.lowercased() == Constants.ethereumNetworkId
            && item.token.symbol.uppercased() == Constants.ethSymbol
            && item.type.lowercased() == Constants.stakingType
            && (item.token.address?.isEmpty ?? true)
    }

    @MainActor
    private func handleFetchResult(_ result: Result<EarnDTO.List.Response, Error>) {
        do {
            let response = try result.get()

            hasNext = response.meta.hasNext
            currentPage = response.meta.page + 1

            isLoading = false
            hasLoadedItems = true

            let models = response.items.map { mapper.mapToEarnTokenModel(from: $0) }
            _eventSubject.send(.appendedItems(items: models, lastPage: !hasNext))
        } catch {
            isLoading = false

            if error.isCancellationError { return }

            AppLogger.tag("Earn").error(
                "Fetch failed (page \(currentPage))",
                error: error
            )
            _eventSubject.send(.failedToFetchData(error: error))

            if hasLoadedItems {
                scheduleRetryForFailedFetchRequest()
            }
        }
    }

    private func scheduleRetryForFailedFetchRequest() {
        guard !isScheduledFetchPending else { return }

        isScheduledFetchPending = true
        AppLogger.tag("Earn").debug("Retry scheduled in \(Int(repeatRequestDelayInSeconds))s")
        scheduledFetchTask = Task.delayed(withDelay: repeatRequestDelayInSeconds, operation: { @MainActor [weak self] in
            guard let self else { return }

            isScheduledFetchPending = false
            scheduledFetchTask = nil
            fetchMore()
        }).eraseToAnyCancellable()
    }
}

// MARK: - Constants

private extension CommonEarnDataService {
    enum Constants {
        static let mostlyUsedLimit = 5
        static let ethereumNetworkId = "ethereum"
        static let ethSymbol = "ETH"
        static let stakingType = "staking"
    }
}

// MARK: - Event

enum EarnDataEvent: Equatable {
    case loading
    case idle
    case failedToFetchData(error: Error)
    case appendedItems(items: [EarnTokenModel], lastPage: Bool)
    case startInitialFetch
    case cleared

    static func == (lhs: EarnDataEvent, rhs: EarnDataEvent) -> Bool {
        switch (lhs, rhs) {
        case (.loading, .loading),
             (.idle, .idle),
             (.startInitialFetch, .startInitialFetch),
             (.cleared, .cleared),
             (.failedToFetchData, .failedToFetchData):
            return true
        case (.appendedItems(let items1, let lastPage1), .appendedItems(let items2, let lastPage2)):
            return items1.map(\.id) == items2.map(\.id) && lastPage1 == lastPage2
        default:
            return false
        }
    }
}

enum EarnDataMostlyUsedEvent: Equatable {
    case loading
    case failed(error: Error)
    case loaded(items: [EarnTokenModel])

    static func == (lhs: EarnDataMostlyUsedEvent, rhs: EarnDataMostlyUsedEvent) -> Bool {
        switch (lhs, rhs) {
        case (.loading, .loading),
             (.failed, .failed):
            return true
        case (.loaded(let items1), .loaded(let items2)):
            return items1.map(\.id) == items2.map(\.id)
        default:
            return false
        }
    }
}
