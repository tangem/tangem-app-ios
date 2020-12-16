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
		
		static let `default` = TapFeatures(isWalletPayIdEnabled: true, isSendingToPayIdEnabled: true, isTopUpEnabled: true, isCreatingTwinCardsAllowed: false)
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
		fetchLocalFeaturesConfig()
//		fetch()
	}
	
	private func fetchLocalFeaturesConfig() {
		let suffix: String
		#if DEBUG
		suffix = "dev"
		#else
		suffix = "prod"
		#endif
		let decoder = JSONDecoder()
		guard
			let path = Bundle.main.url(forResource: "features_\(suffix)", withExtension: "json"),
			let features = try? decoder.decode(TapFeatures.self, from: Data(contentsOf: path)) else {
			self.features = .default
			return
		}
		self.features = features
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

