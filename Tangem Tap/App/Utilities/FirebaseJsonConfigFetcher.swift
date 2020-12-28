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
	
	static func fetch<T: Decodable>(from config: RemoteConfig, type: T.Type, withKey key: FirebaseConfigKeys) -> T? {
		fetch(from: config, type: type, withKey: key.rawValue)
	}
	
	static func fetch<T: Decodable>(from config: RemoteConfig, type: T.Type, withKey key: String) -> T? {
		var dataKey = key + "_"
		#if DEBUG
		dataKey.append("dev")
		#elseif FIREBASE
		dataKey.append("firebase")
		#else
		dataKey.append("prod")
		#endif
		let json = config[dataKey].dataValue
        do {
            return try JsonReader.readJsonData(json, type: type)
        } catch {
            print("Failed to fetch json from firebase. Reason:", error)
            return nil
        }
		
	}
	
}
