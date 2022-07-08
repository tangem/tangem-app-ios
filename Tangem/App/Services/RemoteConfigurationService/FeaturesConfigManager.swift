//
//  FeaturesConfigManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import FirebaseRemoteConfig

class FeaturesConfigManager: RemoteConfigurationProviding {
    private let featuresFileName = "features"

    private let config: RemoteConfig

    private(set) var features: AppFeatures

    init() {
        config = RemoteConfig.remoteConfig()

        let settings = RemoteConfigSettings()
        #if DEBUG
        settings.minimumFetchInterval = 0
        #else
        settings.minimumFetchInterval = 1200
        #endif
        config.configSettings = settings
        features = try! JsonUtils.readBundleFile(with: featuresFileName, type: AppFeatures.self)
        fetch()
    }

    private func fetch() {
//        config.fetchAndActivate { [weak self] (status, error) in
//            guard let self = self else { return }
//
//            self.setupFeatures()
//        }
    }

//    private func setupFeatures() {
//        if let features = FirebaseJsonConfigFetcher.fetch(from: config, type: AppFeatures.self, withKey: .features) {
//            print("Features config from Firebase successflly parsed")
//            self.features = features
//        }
//        print("App features config updated")
//    }
}
