//
//  MarketsListPrefetchDataSource.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

protocol MarketsListPrefetchDataSource: AnyObject {
    /// Instructs your prefetch data source object to begin preparing data for the cells at the supplied index paths.
    func prefetchRows(at index: Int)

    /// Cancels a previously triggered data prefetch request.
    func cancelPrefetchingForRows(at index: Int)
}
