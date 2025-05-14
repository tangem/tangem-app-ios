//
//  MarketsNotificationsManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine

enum MarketsStakingNotificationState: Equatable {
    case hidden
    case visible(apy: String)
}

final class MarketsNotificationsManager {
    @Injected(\.ukGeoDefiner) private var ukGeoDefiner: UKGeoDefiner

    private let dataProvider: MarketsListDataProvider

    init(dataProvider: MarketsListDataProvider) {
        self.dataProvider = dataProvider
    }

    func stakingNotificationState(
        from filterPublisher: some Publisher<MarketsListDataProvider.Filter, Never>
    ) -> some Publisher<MarketsStakingNotificationState, Never> {
        guard !ukGeoDefiner.isUK else { return Just(.hidden).eraseToAnyPublisher() }

        let dateMatch = AppSettings.shared.$startWalletUsageDate
            .map { date -> Bool in
                guard let date else { return false }

                let dateComponents = Calendar.current.dateComponents([.day], from: date, to: Date())

                if let days = dateComponents.day, days >= Constants.showStakingNotificationDelayInDays {
                    return true
                } else {
                    return false
                }
            }
            .removeDuplicates()

        let filterMatch = filterPublisher
            .map { filter in
                filter.order != .staking
            }
            .removeDuplicates()

        let apy = dataProvider.$stakingApy
            .compactMap { apy -> String? in
                apy.flatMap {
                    PercentFormatter().format($0, option: .staking)
                }
            }
            .removeDuplicates()

        return Publishers.CombineLatest3(filterMatch, dateMatch, apy)
            .map { filterMatch, dateMatch, apy -> MarketsStakingNotificationState in
                guard filterMatch, dateMatch else { return .hidden }
                return .visible(apy: apy)
            }
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}

extension MarketsNotificationsManager {
    enum Constants {
        static let showStakingNotificationDelayInDays = 14
    }
}
