//
//  MarketsWidgetNewsProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

protocol MarketsWidgetNewsProvider {
    var newsResultPublisher: AnyPublisher<LoadingResult<[TrendingNewsModel], Error>, Never> { get }
    var newsResult: LoadingResult<[TrendingNewsModel], Error> { get }

    func fetch()
}
