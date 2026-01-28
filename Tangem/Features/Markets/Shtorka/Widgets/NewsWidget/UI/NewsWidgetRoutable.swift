//
//  NewsWidgetRoutable.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

@MainActor
protocol NewsWidgetRoutable: AnyObject {
    func openSeeAllNewsWidget()
    func openNewsDetails(newsIds: [Int], selectedIndex: Int)
}
