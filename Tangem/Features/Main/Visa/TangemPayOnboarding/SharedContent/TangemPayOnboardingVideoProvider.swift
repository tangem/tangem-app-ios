//
//  TangemPayOnboardingVideoProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct TangemPayOnboardingVideoProvider: LoopingVideoBackgroundProvider {
    func videoURL() -> URL? {
        Bundle.main.url(forResource: Constants.resourceName, withExtension: Constants.resourceExtension)
    }

    func handleMissingAsset() {}
}

private extension TangemPayOnboardingVideoProvider {
    enum Constants {
        static let resourceName = "TangemPayOnboardingBackground"
        static let resourceExtension = "mp4"
    }
}
