//
//  NewsReadStatusProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol NewsReadStatusProvider {
    var readStatusChangedPublisher: AnyPublisher<NewsId, Never> { get }

    func isRead(for newsId: NewsId) -> Bool
    func markAsRead(newsId: NewsId)
}
