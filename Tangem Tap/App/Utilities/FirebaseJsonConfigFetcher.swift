//
//  FirebaseJsonConfigFetcher.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import FirebaseRemoteConfig

struct FirebaseJsonConfigFetcher {
	
	static func fetch<T: Decodable>(from config: RemoteConfig, type: T.Type, with key: RemoteConfigKeys) -> T? {
		fetch(from: config, type: type, with: key.rawValue)
	}
	
	static func fetch<T: Decodable>(from config: RemoteConfig, type: T.Type, with key: String) -> T? {
		var dataKey = key
		#if DEBUG
		dataKey.append("dev")
		#elseif FIREBASE
		dataKey.append("firebase")
		#else
		dataKey.append("prod")
		#endif
		let json = config[dataKey].dataValue
		let decoder = JSONDecoder()
		if let fetchedData = try? decoder.decode(type, from: json) {
			print("Data ", type, " fetched from remote config successfully")
			return fetchedData
		}
		return nil
	}
	
}
