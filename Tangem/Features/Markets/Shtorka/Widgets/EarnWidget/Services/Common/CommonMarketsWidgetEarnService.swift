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

final class CommonMarketsWidgetEarnService {
    // MARK: - Inject Services

    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService

    // MARK: - Private Properties

    private let earnResultValueSubject: CurrentValueSubject<LoadingResult<[EarnTokenModel], Error>, Never> = .init(.loading)

    private var updateTask: AnyCancellable?

    private let mapper = EarnModelMapper()

    deinit {
        updateTask?.cancel()
    }
}

// MARK: - MarketsWidgetEarnProvider

extension CommonMarketsWidgetEarnService: MarketsWidgetEarnProvider {
    var earnResultPublisher: AnyPublisher<LoadingResult<[EarnTokenModel], Error>, Never> {
        earnResultValueSubject.eraseToAnyPublisher()
    }

    var earnResult: LoadingResult<[EarnTokenModel], Error> {
        earnResultValueSubject.value
    }

    func fetch() {
        updateTask?.cancel()

        earnResultValueSubject.value = .loading

        updateTask = runTask(in: self) { service in
            do {
                let requestModel = EarnDTO.List.Request(
                    isForEarn: true,
                    page: nil,
                    limit: Constants.earnLimit,
                    type: nil,
                    networkIds: nil
                )

                let response = try await service.tangemApiService.loadEarnYieldMarkets(requestModel: requestModel)
                let earnTokenModels = response.items.map { service.mapper.mapToEarnTokenModel(from: $0) }
                service.earnResultValueSubject.send(.success(earnTokenModels))
            } catch {
                service.earnResultValueSubject.send(.failure(error))
            }
        }.eraseToAnyCancellable()
    }
}

// MARK: - Constants

private extension CommonMarketsWidgetEarnService {
    enum Constants {
        static let earnLimit = 5
    }
}
