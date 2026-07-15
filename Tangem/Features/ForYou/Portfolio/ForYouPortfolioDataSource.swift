//
//  ForYouPortfolioDataSource.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine

/// Supplies the Portfolio Review screen with its view state and notifications.
///
/// Keeps `ForYouViewModel` free of the data pipeline: the UI can run on a mock source while the
/// live implementation (selected wallet → mapper → state) is wired independently.
protocol ForYouPortfolioDataSource {
    var statePublisher: AnyPublisher<PortfolioReviewState, Never> { get }
    var notificationsPublisher: AnyPublisher<[NotificationViewInput], Never> { get }
}
