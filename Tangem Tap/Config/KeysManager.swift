//
//  KeysManager.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

class KeysManager {
	
	struct Keys: Decodable {
		let coinMarketCapKey: String
		let moonPayApiKey: String
		let moonPayApiSecretKey: String
		
		static let defaultKeys = Keys(coinMarketCapKey: "f6622117-c043-47a0-8975-9d673ce484de",
									  moonPayApiKey: "pk_test_kc90oYTANy7UQdBavDKGfL4K9l6VEPE",
									  moonPayApiSecretKey: "sk_test_V8w4M19LbDjjYOt170s0tGuvXAgyEb1C")
	}
	
	private(set) var keys: Keys = .defaultKeys
	
	init() throws {
		try parseKeys()
	}
	
	private func parseKeys() throws {
		let suffix: String
		#if DEBUG
		suffix = "dev"
		#else
		suffix = "prod"
		#endif
		guard let path = Bundle.main.url(forResource: "config_\(suffix)", withExtension: "json") else {
			throw NSError(domain: "Failed to found keys config file", code: -9999, userInfo: nil)
		}
		let decoder = JSONDecoder()
		keys = try decoder.decode(Keys.self, from: Data(contentsOf: path))
	}
}
