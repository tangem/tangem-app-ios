//
//  EllipticCurve.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

/// Elliptic curve used for wallet key operations.
public enum EllipticCurve: String, Codable {
	case secp256k1
	case ed25519
    case secp256r1
	
	public init(from decoder: Decoder) throws {
		let values = try decoder.singleValueContainer()
		let stringValue = try values.decode(String.self).lowercased()
		if let curve = EllipticCurve(rawValue: stringValue) {
			self = curve
		} else {
			throw TangemSdkError.decodingFailed("Failed to decode elliptic curve value")
		}
	}
}
