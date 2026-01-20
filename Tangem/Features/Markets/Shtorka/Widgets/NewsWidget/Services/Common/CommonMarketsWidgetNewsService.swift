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

    // MARK: - Private Properties

    private let newsReadStatusDidUpdateSubject: PassthroughSubject<Void, Never> = .init()
    private let newsResultValueSubject: CurrentValueSubject<LoadingResult<[TrendingNewsModel], Error>, Never> = .init(.loading)

    private let mapper = NewsModelMapper()

    private var updateTask: AnyCancellable?

    deinit {
        updateTask?.cancel()
    }
}

// MARK: -

extension CommonMarketsWidgetNewsService {
    var newsReadStatusDidUpdate: AnyPublisher<Void, Never> {
        newsReadStatusDidUpdateSubject.eraseToAnyPublisher()
    }

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

                // [REDACTED_TODO_COMMENT]
                let result = response.items.map { service.mapper.mapToNewsModel(from: $0, isRead: Bool.random()) }

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

// MARK: - Constants

private extension CommonMarketsWidgetNewsService {
    enum Constants {
        static let newsLimit = 10
    }
}
