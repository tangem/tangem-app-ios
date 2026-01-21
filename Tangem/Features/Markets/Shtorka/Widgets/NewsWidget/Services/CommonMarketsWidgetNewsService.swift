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

    private lazy var mapper: NewsModelMapper = .init(readStatusProvider: readStatusProvider)

    private var bag = Set<AnyCancellable>()

    init() {
        bindReadStatusUpdates()
    }

    private var updateTask: AnyCancellable?

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

                let result = service.sortItems(response.items.map { service.mapper.mapToNewsModel(from: $0) })

                service.newsResultValueSubject.send(.success(result))
            } catch {
                if error.isCancellationError {
                    return
                }

                service.newsResultValueSubject.send(.failure(error))
            }
        }.eraseToAnyCancellable()
    }
}

// MARK: - Read status updates

private extension CommonMarketsWidgetNewsService {
    func sortItems(_ items: [TrendingNewsModel]) -> [TrendingNewsModel] {
        items
            .enumerated()
            .sorted { lhs, rhs in
                if lhs.element.isRead != rhs.element.isRead {
                    return !lhs.element.isRead
                }

                return lhs.offset < rhs.offset
            }
            .map(\.element)
    }

    func bindReadStatusUpdates() {
        readStatusProvider
            .readStatusDidChangePublisher
            .withWeakCaptureOf(self)
            .sink { service, readNewsIds in
                service.handleReadStatusDidChange(readNewsIds: readNewsIds)
            }
            .store(in: &bag)
    }

    func handleReadStatusDidChange(readNewsIds: [NewsId]) {
        guard case .success(let currentModels) = newsResultValueSubject.value else { return }

        let readNewsIdsSet = Set(readNewsIds)
        let updatedModels = currentModels.map { model in
            TrendingNewsModel(
                id: model.id,
                createdAt: model.createdAt,
                score: model.score,
                language: model.language,
                isTrending: model.isTrending,
                newsUrl: model.newsUrl,
                categories: model.categories,
                relatedTokens: model.relatedTokens,
                title: model.title,
                isRead: readNewsIdsSet.contains(model.id)
            )
        }

        newsResultValueSubject.value = .success(sortItems(updatedModels))
    }
}

// MARK: - Constants

private extension CommonMarketsWidgetNewsService {
    enum Constants {
        static let newsLimit = 10
    }
}
