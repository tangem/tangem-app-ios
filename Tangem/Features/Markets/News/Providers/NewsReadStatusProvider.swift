//
//  NewsReadStatusProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

protocol NewsReadStatusProvider {
    func isRead(for newsId: NewsId) -> Bool
    func markAsRead(newsId: NewsId)
}
