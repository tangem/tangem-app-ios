//
//  FeatureProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

/// Use this provider to check the availability of your feature
enum FeatureProvider {
    static func isAvailable(_ toggle: FeatureToggle) -> Bool {
        if AppEnvironment.current.isProduction {
            return isAvailableForReleaseVersion(toggle)
        }

        guard let state = FeaturesStorage().availableFeatures[toggle] else {
            return isAvailableForReleaseVersion(toggle)
        }

        switch state {
        case .default:
            assertionFailure("Default state shouldn't be saved in storage")
            return isAvailableForReleaseVersion(toggle)
        case .on:
            return true
        case .off:
            return false
        }
    }

    /// Return `true` if the feature is should be released or has already been released in current app version
    static func isAvailableForReleaseVersion(_ toggle: FeatureToggle) -> Bool {
        guard let appVersion: String = InfoDictionaryUtils.version.value(),
              let releaseVersion = toggle.releaseVersion.version,
              appVersion >= releaseVersion else {
            return false
        }

        return true
    }
}
