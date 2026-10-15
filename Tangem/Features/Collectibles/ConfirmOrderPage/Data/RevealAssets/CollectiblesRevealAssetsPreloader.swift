//
//  CollectiblesRevealAssetsPreloader.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

@MainActor
protocol CollectiblesRevealAssetsPreloader {
    func preload(for colorScheme: ColorScheme)
    func assets(prefetchingImages imageURLs: [URL]) async -> CollectiblesRevealAssets
}
