//
//  StubUserAssetsSearchProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

/// In-memory stub for ``UserAssetsSearchProviding``.
/// Replace with a real implementation that uses AccountWalletModelsAggregator.
final class StubUserAssetsSearchProvider: UserAssetsSearchProviding {
    func search(query: String) -> [UserAssetSearchResult] {
        return []
    }
}
