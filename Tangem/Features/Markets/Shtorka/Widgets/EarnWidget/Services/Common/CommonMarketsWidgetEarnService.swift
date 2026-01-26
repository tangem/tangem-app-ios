//
//  CommonMarketsWidgetEarnService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

// MARK: - Common Implementation

final class CommonMarketsWidgetEarnService: MarketsWidgetEarnProvider {
    // MARK: - Inject Services

    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService

    // MARK: - Private Properties

    private let earnResultValueSubject: CurrentValueSubject<LoadingResult<[EarnTokenModel], Error>, Never> = .init(.loading)

    private var updateTask: AnyCancellable?

    deinit {
        updateTask?.cancel()
    }
}

// MARK: -

extension CommonMarketsWidgetEarnService {
    var earnResultPublisher: AnyPublisher<LoadingResult<[EarnTokenModel], Error>, Never> {
        earnResultValueSubject.eraseToAnyPublisher()
    }

    var earnResult: LoadingResult<[EarnTokenModel], Error> {
        earnResultValueSubject.value
    }

    func fetch() {
        updateTask?.cancel()

        earnResultValueSubject.value = .loading

        // [REDACTED_TODO_COMMENT]
        // For now, return empty array as placeholder
        updateTask = runTask(in: self) { service in
            // Placeholder: return empty array
            // Will be replaced with actual API call when TangemApiService method is implemented
            service.earnResultValueSubject.send(.success([]))
        }.eraseToAnyCancellable()
    }
}
