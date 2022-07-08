//
//  FeaturesConfigManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

class FeaturesConfigManager: RemoteConfigurationProviding {
    private let featuresFileName = "features"

    private(set) var features: AppFeatures

    init() {
        features = try! JsonUtils.readBundleFile(with: featuresFileName, type: AppFeatures.self)
    }
}
