//
//  EarnYieldPickerVideoProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

struct EarnYieldPickerVideoProvider: LoopingVideoBackgroundProvider {
    func videoURL() -> URL? {
        Bundle.main.url(forResource: Constants.resourceName, withExtension: Constants.resourceExtension)
    }

    func handleMissingAsset() {}
}

private extension EarnYieldPickerVideoProvider {
    enum Constants {
        static let resourceName = "EarnYieldPickerBackground"
        static let resourceExtension = "mp4"
    }
}
