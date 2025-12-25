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

    private let dataProvider: MarketsListDataProvider

    init(dataProvider: MarketsListDataProvider) {
        self.dataProvider = dataProvider
    }

    func yieldNotificationVisible(
        from filterPublisher: some Publisher<MarketsListDataProvider.Filter, Never>
    ) -> some Publisher<Bool, Never> {
        let isUKPublisher: AnyPublisher<Bool, Never> = Deferred { [ukGeoDefiner] in
            Future { [ukGeoDefiner] completion in
                completion(.success(ukGeoDefiner.isUK))
            }
        }.eraseToAnyPublisher()

        let showMarketsYieldModeNotification = AppSettings.shared.$showMarketsYieldModeNotification
            .removeDuplicates()

        return Publishers.CombineLatest3(filterPublisher, showMarketsYieldModeNotification, isUKPublisher)
            .map { filter, show, isUK in
                !isUK && show && filter.order != .yield
            }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
}
