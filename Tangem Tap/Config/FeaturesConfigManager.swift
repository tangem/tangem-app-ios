//
//  FeaturesConfigManager.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import FirebaseRemoteConfig

class FeaturesConfigManager {
    
    struct TapFeatures: Decodable {
        let isWalletPayIdEnabled: Bool
        let isSendingToPayIdEnabled: Bool
        let isTopUpEnabled: Bool
        let isCreatingTwinCardsAllowed: Bool
    }
    
    private let featuresFileName = "features"
    
    private let config: RemoteConfig
    
    private(set) var features: TapFeatures
    private(set) var warnings: [TapWarning] = []
    
    init() throws {
        config = RemoteConfig.remoteConfig()
        
        let settings = RemoteConfigSettings()
        #if DEBUG
        settings.minimumFetchInterval = 0
        #else
        settings.minimumFetchInterval = 3600
        #endif
        config.configSettings = settings
        features = try JsonReader.readBundleFile(with: featuresFileName, type: TapFeatures.self)
        //		fetch()
    }
    
    private func fetch() {
        config.fetchAndActivate { [weak self] (status, error) in
            guard let self = self else { return }
            
            self.setupFeatures()
        }
    }
    
    private func setupFeatures() {
        if let features = FirebaseJsonConfigFetcher.fetch(from: config, type: TapFeatures.self, with: .features) {
            print("Features config from Firebase successflly parsed")
            self.features = features
        }
        print("App features config updated")
    }
    
    private func setupWarnings() {
        guard let warnings = FirebaseJsonConfigFetcher.fetch(from: config, type: [TapWarning].self, with: .warnings) else {
            return
        }
        
        self.warnings = warnings
    }
}

