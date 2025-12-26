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
    // MARK: - Private Properties

    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService

    private let newsResultValueSubject: CurrentValueSubject<LoadingResult<[TrendingNewsModel], Error>, Never> = .init(.loading)

    private let newsReadStatusDidUpdateSubject: PassthroughSubject<Void, Never> = .init()

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
        // [REDACTED_TODO_COMMENT]
    }
}

// MARK: - Constants

private extension CommonMarketsWidgetNewsService {
    enum Constants {
        static let newsLimit = 5
        static let language = Locale.appLanguageCode
    }
}
