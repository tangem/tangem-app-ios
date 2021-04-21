//
//  CardStatus.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

protocol StatusType {
    var rawValue: Int { get }
}

/// Status of the card and its wallet.
public enum CardStatus: Int, Codable, StatusType {
	case notPersonalized = 0
	case empty = 1
	case loaded = 2
	case purged = 3
	
	public func encode(to encoder: Encoder) throws {
		var container = encoder.singleValueContainer()
		try container.encode("\(self)".capitalized)
	}
	
	public init(from decoder: Decoder) throws {
		let values = try decoder.singleValueContainer()
		let stringValue = try values.decode(String.self).lowercasingFirst()
		switch stringValue {
		case "notPersonalized":
			self = .notPersonalized
		case "empty":
			self = .empty
		case "loaded":
			self = .loaded
		case "purged":
			self = .purged
		default:
			throw TangemSdkError.decodingFailed("Failed to decode CardStatus")
		}
	}
}
