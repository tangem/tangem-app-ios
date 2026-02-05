//
//  MarketsNotificationsManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine

final class MarketsNotificationsManager {
    @Injected(\.ukGeoDefiner) private var ukGeoDefiner: UKGeoDefiner

    private let tokenLoadingStateProvider: AnyPublisher<MarketsView.ListLoadingState, Never>

    init(tokenLoadingStateProvider: AnyPublisher<MarketsView.ListLoadingState, Never>) {
        self.tokenLoadingStateProvider = tokenLoadingStateProvider
    }

    func yieldNotificationVisible(
        from filterPublisher: some Publisher<MarketsListDataProvider.Filter, Never>
    ) -> some Publisher<Bool, Never> {
        let isUKPublisher: AnyPublisher<Bool, Never> = Deferred { [ukGeoDefiner] in
            Future { [ukGeoDefiner] completion in
                completion(.success(ukGeoDefiner.isUK))
            }
        }.eraseToAnyPublisher()

        let isNotificationNotDismissedPublisher = AppSettings.shared.$showMarketsYieldModeNotification
            .removeDuplicates()

        return Publishers.CombineLatest4(
            filterPublisher,
            isNotificationNotDismissedPublisher,
            isUKPublisher,
            tokenLoadingStateProvider
        )
        .map { filter, isNotificationNotDismissed, isUK, tokenLoadingState in
            let areTokensLoaded = tokenLoadingState.isAllDataLoaded || tokenLoadingState.isIdle
            let isYieldFilterInactive = !filter.order.isYield
            return !isUK && isNotificationNotDismissed && isYieldFilterInactive && areTokensLoaded
        }
        .removeDuplicates()
        .eraseToAnyPublisher()
    }
}
