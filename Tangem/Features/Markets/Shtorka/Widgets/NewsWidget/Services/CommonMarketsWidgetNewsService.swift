//
//  CommonMarketsWidgetNewsService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

// MARK: - Common Implementation

final class CommonMarketsWidgetNewsService: MarketsWidgetNewsProvider {
    // MARK: - Inject Services

    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService
    @Injected(\.newsReadStatusProvider) private var readStatusProvider: NewsReadStatusProvider

    // MARK: - Private Properties

    private let newsResultValueSubject: CurrentValueSubject<LoadingResult<[TrendingNewsModel], Error>, Never> = .init(.loading)

    /// Cached original API response items used to preserve API order when rebuilding models with updated read status
    private var cachedResponseItems: [NewsDTO.List.Item] = []

    private lazy var mapper: NewsModelMapper = .init(readStatusProvider: readStatusProvider)

    private var bag = Set<AnyCancellable>()

    private var updateTask: AnyCancellable?

    init() {
        bindReadStatusUpdates()
    }

    deinit {
        updateTask?.cancel()
    }
}

// MARK: -

extension CommonMarketsWidgetNewsService {
    var newsResultPublisher: AnyPublisher<LoadingResult<[TrendingNewsModel], Error>, Never> {
        newsResultValueSubject.eraseToAnyPublisher()
    }

    var newsResult: LoadingResult<[TrendingNewsModel], Error> {
        newsResultValueSubject.value
    }

    func fetch() {
        updateTask?.cancel()

        newsResultValueSubject.value = .loading

        updateTask = runTask(in: self) { service in
            do {
                let response = try await service.tangemApiService.loadTrendingNews(
                    limit: Constants.newsLimit,
                    lang: Locale.newsLanguageCode
                )

                service.cachedResponseItems = response.items

                let result = response.items.map { service.mapper.mapToNewsModel(from: $0) }

                service.newsResultValueSubject.send(.success(result.sortedByReadStatus()))
            } catch {
                if error.isCancellationError {
                    return
                }

                service.newsResultValueSubject.send(.failure(error))
            }
        }.eraseToAnyCancellable()
    }

    func bindReadStatusUpdates() {
        readStatusProvider
            .readStatusChangedPublisher
            .withWeakCaptureOf(self)
            .sink { service, _ in
                service.handleReadStatusDidChange()
            }
            .store(in: &bag)
    }

    func handleReadStatusDidChange() {
        guard case .success = newsResultValueSubject.value, !cachedResponseItems.isEmpty else { return }

        let updatedModels = cachedResponseItems.map { mapper.mapToNewsModel(from: $0) }

        newsResultValueSubject.value = .success(updatedModels.sortedByReadStatus())
    }
}

// MARK: - Constants

private extension CommonMarketsWidgetNewsService {
    enum Constants {
        static let newsLimit = 10
    }
}
