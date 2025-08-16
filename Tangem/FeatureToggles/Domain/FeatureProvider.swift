//
//  FeatureProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

/// Use this provider to check the availability of your feature
enum FeatureProvider {
    static func isAvailable(_ feature: Feature) -> Bool {
        if case .hotWallet = feature { return true }
        if AppEnvironment.current.isProduction {
            return isAvailableForReleaseVersion(feature)
        }

        let state = FeatureStorage.instance.availableFeatures[feature]
        switch state {
        case .none:
            return isAvailableForReleaseVersion(feature)
        case .default:
            assertionFailure("Default state shouldn't be saved in storage")
            return isAvailableForReleaseVersion(feature)
        case .on:
            return true
        case .off:
            return false
        }
    }

    /// Return `true` if the feature is should be released or has already been released in current app version
    static func isAvailableForReleaseVersion(_ feature: Feature) -> Bool {
        guard let appVersion: String = InfoDictionaryUtils.version.value(),
              let releaseVersion = feature.releaseVersion.version else {
            return false
        }

        let comparisonResult = appVersion.compare(releaseVersion, options: .numeric)
        return comparisonResult == .orderedDescending || comparisonResult == .orderedSame
    }
}
