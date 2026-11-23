//
//  PolymarketWelcomeVideoProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemPolymarket

struct PolymarketWelcomeVideoProvider: LoopingVideoBackgroundProvider {
    func videoURL() -> URL? {
        Bundle.main.url(forResource: Constants.resourceName, withExtension: Constants.resourceExtension)
    }

    func handleMissingAsset() {
        PolymarketLogger.error(error: "The welcome video \(Constants.resourceName).\(Constants.resourceExtension) is missing from the bundle")
    }
}

// MARK: - Constants

private extension PolymarketWelcomeVideoProvider {
    enum Constants {
        static let resourceName = "PolymarketWelcomeBackground"
        static let resourceExtension = "mp4"
    }
}
