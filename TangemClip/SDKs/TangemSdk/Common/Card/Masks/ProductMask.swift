//
//  ProductMask.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

public struct ProductMask: OptionSet, Codable, StringArrayConvertible {
	public let rawValue: Byte
	
	public init(rawValue: Byte) {
		self.rawValue = rawValue
	}
	
	public static let note = ProductMask(rawValue: 0x01)
	public static let tag = ProductMask(rawValue: 0x02)
	public static let idCard = ProductMask(rawValue: 0x04)
	public static let idIssuer = ProductMask(rawValue: 0x08)
	public static let twinCard = ProductMask(rawValue: 0x20)
	
	public func encode(to encoder: Encoder) throws {
		var container = encoder.singleValueContainer()
		try container.encode(toArray())
	}
	
	public init(from decoder: Decoder) throws {
		let values = try decoder.singleValueContainer()
		let stringValues = try values.decode([String].self)
		var mask = ProductMask()
		
		if stringValues.contains("Note") {
			mask.update(with: ProductMask.note)
		}
		
		if stringValues.contains("Tag") {
			mask.update(with: ProductMask.tag)
		}
		
		if stringValues.contains("IdCard") {
			mask.update(with: ProductMask.idCard)
		}
		
		if stringValues.contains("IdIssuer") {
			mask.update(with: ProductMask.idIssuer)
		}
		
		if stringValues.contains("TwinCard") {
			mask.update(with: ProductMask.twinCard)
		}
		
		self = mask
	}
    
    func toArray() -> [String] {
        var values = [String]()
        if contains(ProductMask.note) {
            values.append("Note")
        }
        if contains(ProductMask.tag) {
            values.append("Tag")
        }
        if contains(ProductMask.idCard) {
            values.append("IdCard")
        }
        if contains(ProductMask.idIssuer) {
            values.append("IdIssuer")
        }
        if contains(ProductMask.twinCard) {
            values.append("TwinCard")
        }
        return values
    }
}


extension ProductMask: LogStringConvertible {}
