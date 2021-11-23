//
//  FeaturesConfigManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import FirebaseRemoteConfig

protocol RemoteWarningProvider {
    var warnings: [AppWarning] { get }
}

protocol FeaturesConfigProvider {
    var features: AppFeatures { get }
}

struct AppFeatures: Decodable {
    let isWalletPayIdEnabled: Bool
    let isSendingToPayIdEnabled: Bool
    let isTopUpEnabled: Bool
    let isCreatingTwinCardsAllowed: Bool
}

class FeaturesConfigManager: RemoteWarningProvider, FeaturesConfigProvider {
    
    private let featuresFileName = "features"
    
    private let config: RemoteConfig
    
    private(set) var features: AppFeatures
    private(set) var warnings: [AppWarning] = []
    
    init() throws {
        config = RemoteConfig.remoteConfig()
        
        let settings = RemoteConfigSettings()
        #if DEBUG
        settings.minimumFetchInterval = 0
        #else
        settings.minimumFetchInterval = 1200
        #endif
        config.configSettings = settings
        features = try JsonUtils.readBundleFile(with: featuresFileName, type: AppFeatures.self)
        fetch()
    }
    
    private func fetch() {
        config.fetchAndActivate { [weak self] (status, error) in
            guard let self = self else { return }
            
//            self.setupFeatures()
            self.setupWarnings()
        }
    }

//    private func setupFeatures() {
//        if let features = FirebaseJsonConfigFetcher.fetch(from: config, type: AppFeatures.self, withKey: .features) {
//            print("Features config from Firebase successflly parsed")
//            self.features = features
//        }
//        print("App features config updated")
//    }

    private func setupWarnings() {
        guard let warnings = FirebaseJsonConfigFetcher.fetch(from: config, type: [RemoteAppWarning].self, withKey: .warnings) else {
            return
        }

        self.warnings = AppWarning.fetch(remote: warnings)
    }
}
