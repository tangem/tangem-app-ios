//
//  FirebaseJsonConfigFetcher.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import FirebaseRemoteConfig

enum FirebaseConfigKeys: String {
    case features = "features"
    case warnings = "warnings"
}

struct FirebaseJsonConfigFetcher {
	
	static func fetch<T: Decodable>(from config: RemoteConfig, type: T.Type, with key: FirebaseConfigKeys) -> T? {
		fetch(from: config, type: type, with: key.rawValue)
	}
	
	static func fetch<T: Decodable>(from config: RemoteConfig, type: T.Type, with key: String) -> T? {
		var dataKey = key + "_"
		#if DEBUG
		dataKey.append("dev")
		#elseif FIREBASE
		dataKey.append("firebase")
		#else
		dataKey.append("prod")
		#endif
		let json = config[dataKey].dataValue
        if let fetchedData = try? JsonReader.readJsonData(json, type: type) {
			print("Data ", type, " fetched from remote config successfully")
			return fetchedData
		}
		return nil
	}
	
}
