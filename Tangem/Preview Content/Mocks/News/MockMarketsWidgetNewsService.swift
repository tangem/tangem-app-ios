//
//  MockMarketsWidgetNewsService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

// MARK: - Mock Implementation

final class MockMarketsWidgetNewsService: MarketsWidgetNewsProvider {
    // MARK: - Private Properties

    private let newsResultValueSubject: CurrentValueSubject<LoadingResult<[TrendingNewsModel], Error>, Never> = .init(.loading)

    var newsResultPublisher: AnyPublisher<LoadingResult<[TrendingNewsModel], Error>, Never> {
        newsResultValueSubject.eraseToAnyPublisher()
    }

    var newsResult: LoadingResult<[TrendingNewsModel], Error> {
        newsResultValueSubject.value
    }

    var newsReadStatusDidUpdate: AnyPublisher<Void, Never> {
        return .just(output: ())
    }

    lazy var trendingNewsDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601WithFractionalSeconds
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()

    private let mapper = NewsModelMapper()

    func fetch() {
        newsResultValueSubject.value = .loading

        Task {
            try? await Task.sleep(nanoseconds: 1_500_000_000)

            if Double.random(in: 0 ... 1) < 0.3 {
                let errorMessages = [
                    "Network connection failed",
                    "Server error occurred",
                    "Failed to load news data",
                    "Request timeout",
                    "Unknown error",
                ]
                let randomMessage = errorMessages.randomElement() ?? "Unknown error"
                newsResultValueSubject.value = .failure(
                    NSError(
                        domain: "MarketsWidgetNewsService",
                        code: Int.random(in: 100 ... 599),
                        userInfo: [NSLocalizedDescriptionKey: randomMessage]
                    )
                )
                return
            }

            do {
                guard let url = Bundle.main.url(forResource: "trendingNews", withExtension: "json") else {
                    newsResultValueSubject.value = .failure(
                        NSError(
                            domain: "MarketsWidgetNewsService",
                            code: -1,
                            userInfo: [NSLocalizedDescriptionKey: "Failed to find news data file"]
                        )
                    )
                    return
                }

                let data = try Data(contentsOf: url)
                let decoder = trendingNewsDecoder
                let response = try decoder.decode(TrendingNewsResponse.self, from: data)
                let success = response.items.map { mapper.mapToNewsModel(from: $0, isRead: Bool.random()) }

                newsResultValueSubject.value = .success(success)
            } catch {
                newsResultValueSubject.value = .failure(error)
            }
        }
    }
}
