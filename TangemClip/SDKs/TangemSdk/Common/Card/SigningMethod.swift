//
//  SigningMethod.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

/// Determines which type of data is required for signing.
public struct SigningMethod: OptionSet, Codable, StringArrayConvertible {
	public let rawValue: Byte
	
	public init(rawValue: Byte) {
		if rawValue & 0x80 != 0 {
			self.rawValue = rawValue
		} else {
			self.rawValue = 0b10000000|(1 << rawValue)
		}
	}
	
	public static let signHash = SigningMethod(rawValue: 0b10000000|(1 << 0))
	public static let signRaw = SigningMethod(rawValue: 0b10000000|(1 << 1))
	public static let signHashSignedByIssuer = SigningMethod(rawValue: 0b10000000|(1 << 2))
	public static let signRawSignedByIssuer = SigningMethod(rawValue: 0b10000000|(1 << 3))
	public static let signHashSignedByIssuerAndUpdateIssuerData = SigningMethod(rawValue: 0b10000000|(1 << 4))
	public static let signRawSignedByIssuerAndUpdateIssuerData = SigningMethod(rawValue: 0b10000000|(1 << 5))
	public static let signPos = SigningMethod(rawValue: 0b10000000|(1 << 6))
	
	public func encode(to encoder: Encoder) throws {
		var container = encoder.singleValueContainer()
		try container.encode(toArray())
	}
	
	public init(from decoder: Decoder) throws {
		let values = try decoder.singleValueContainer()
		let stringValues = try values.decode([String].self)
		var mask = SigningMethod()
		
		if stringValues.contains("SignHash") {
			mask.update(with: SigningMethod.signHash)
		}
		
		if stringValues.contains("SignRaw") {
			mask.update(with: SigningMethod.signRaw)
		}
		
		if stringValues.contains("SignHashSignedByIssuer") {
			mask.update(with: SigningMethod.signHashSignedByIssuer)
		}
		
		if stringValues.contains("SignRawSignedByIssuer") {
			mask.update(with: SigningMethod.signRawSignedByIssuer)
		}
		
		if stringValues.contains("SignHashSignedByIssuerAndUpdateIssuerData") {
			mask.update(with: SigningMethod.signHashSignedByIssuerAndUpdateIssuerData)
		}
		
		if stringValues.contains("SignRawSignedByIssuerAndUpdateIssuerData") {
			mask.update(with: SigningMethod.signRawSignedByIssuerAndUpdateIssuerData)
		}
		
		if stringValues.contains("SignPos") {
			mask.update(with: SigningMethod.signPos)
		}
		
		self = mask
	}
    
    func toArray() -> [String] {
        var values = [String]()
        if contains(SigningMethod.signHash) {
            values.append("SignHash")
        }
        if contains(SigningMethod.signRaw) {
            values.append("SignRaw")
        }
        if contains(SigningMethod.signHashSignedByIssuer) {
            values.append("SignHashSignedByIssuer")
        }
        if contains(SigningMethod.signRawSignedByIssuer) {
            values.append("SignRawSignedByIssuer")
        }
        if contains(SigningMethod.signHashSignedByIssuerAndUpdateIssuerData) {
            values.append("SignHashSignedByIssuerAndUpdateIssuerData")
        }
        if contains(SigningMethod.signRawSignedByIssuerAndUpdateIssuerData) {
            values.append("SignRawSignedByIssuerAndUpdateIssuerData")
        }
        if contains(SigningMethod.signPos) {
            values.append("SignPos")
        }
        return values
    }
}


extension SigningMethod: LogStringConvertible {}
