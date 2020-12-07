//
//  RemoteConfigManager.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import FirebaseRemoteConfig

class RemoteConfigManager {
	
	struct TapFeatures: Decodable {
		let isWalletPayIdEnabled: Bool
		let isTopUpEnabled: Bool
		let isCreatingTwinCardsAllowed: Bool
		
		static let `default` = TapFeatures(isWalletPayIdEnabled: true, isTopUpEnabled: true, isCreatingTwinCardsAllowed: false)
	}
	
	private let config: RemoteConfig
	
	private(set) var features: TapFeatures
	
	init() {
		config = RemoteConfig.remoteConfig()
		
		let settings = RemoteConfigSettings()
		#if DEBUG
		settings.minimumFetchInterval = 0
		#else
		settings.minimumFetchInterval = 3600
		#endif
		config.configSettings = settings
		features = .default
		fetch()
	}
	
	private func fetch() {
		config.fetchAndActivate { [weak self] (status, error) in
			guard let self = self else { return }
			self.setupFeatures()
		}
	}
	
	private func setupFeatures() {
		var key: String = "features_"
		#if DEBUG
		key.append("dev")
		#elseif FIREBASE
		key.append("firebase")
		#else
		key.append("prod")
		#endif
		let json = config[key].dataValue
		let decoder = JSONDecoder()
		if let features = try? decoder.decode(TapFeatures.self, from: json) {
			print("Features config from Firebase successflly parsed")
			self.features = features
		}
		print("App features config updated")
	}
}

