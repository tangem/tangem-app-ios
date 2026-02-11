//
//  MockMarketsWidgetEarnService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

// MARK: - Mock Implementation

final class MockMarketsWidgetEarnService: MarketsWidgetEarnProvider {
    // MARK: - Private Properties

    private lazy var decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()

    private let mapper = EarnModelMapper()

    private let earnResultValueSubject: CurrentValueSubject<LoadingResult<[EarnTokenModel], Error>, Never> = .init(.loading)

    var earnResultPublisher: AnyPublisher<LoadingResult<[EarnTokenModel], Error>, Never> {
        earnResultValueSubject.eraseToAnyPublisher()
    }

    var earnResult: LoadingResult<[EarnTokenModel], Error> {
        earnResultValueSubject.value
    }

    func fetch() {
        earnResultValueSubject.value = .loading

        Task {
            try? await Task.sleep(nanoseconds: 1_500_000_000)

            if Double.random(in: 0 ... 1) < 0.3 {
                let errorMessages = [
                    "Network connection failed",
                    "Server error occurred",
                    "Failed to load earn data",
                    "Request timeout",
                    "Unknown error",
                ]
                let randomMessage = errorMessages.randomElement() ?? "Unknown error"
                earnResultValueSubject.value = .failure(
                    NSError(
                        domain: "MarketsWidgetEarnService",
                        code: Int.random(in: 100 ... 599),
                        userInfo: [NSLocalizedDescriptionKey: randomMessage]
                    )
                )
                return
            }

            do {
                guard let url = Bundle.main.url(forResource: "earnTokens", withExtension: "json") else {
                    earnResultValueSubject.value = .failure(
                        NSError(
                            domain: "MarketsWidgetEarnService",
                            code: -1,
                            userInfo: [NSLocalizedDescriptionKey: "Failed to find earn data file"]
                        )
                    )
                    return
                }

                let data = try Data(contentsOf: url)
                let response = try decoder.decode(EarnDTO.List.Response.self, from: data)
                let models = response.items.map { mapper.mapToEarnTokenModel(from: $0) }

                earnResultValueSubject.value = .success(models)
            } catch {
                earnResultValueSubject.value = .failure(error)
            }
        }
    }
}
