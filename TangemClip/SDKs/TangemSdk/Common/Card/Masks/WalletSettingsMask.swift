//
//  WalletSettingsMask.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

/// Stores and maps Wallet settings
/// - Note: Available only for cards with COS v.4.0
public struct WalletSettingsMask: Codable, OptionSet, StringArrayConvertible {
	public var rawValue: Int
	
	public init(rawValue: Int) {
		self.rawValue = rawValue
	}
	
	public static let isReusable = WalletSettingsMask(rawValue: 0x0001)
	public static let prohibitPurgeWallet = WalletSettingsMask(rawValue: 0x0004)
	
	public func encode(to encoder: Encoder) throws {
		var container = encoder.singleValueContainer()
		try container.encode(toArray())
	}
	
	public init(from decoder: Decoder) throws {
		let values = try decoder.singleValueContainer()
		let stringValues = try values.decode([String].self)
		var mask = WalletSettingsMask()
		if stringValues.contains("IsReusable") {
			mask.update(with: .isReusable)
		}
		if stringValues.contains("ProhibitPurgeWallet") {
			mask.update(with: .prohibitPurgeWallet)
		}
		self = mask
	}
    
    func toArray() -> [String] {
        var values = [String]()
        if contains(.isReusable) {
            values.append("IsReusable")
        }
        if contains(.prohibitPurgeWallet) {
            values.append("ProhibitPurgeWallet")
        }
        return values
    }
}

extension WalletSettingsMask: LogStringConvertible {}

class WalletSettingsMaskBuilder {
	private var settingsMaskValue = 0
	
	func add(_ settings: WalletSettingsMask) {
		settingsMaskValue |= settings.rawValue
	}
	
	func build() -> WalletSettingsMask {
		WalletSettingsMask(rawValue: settingsMaskValue)
	}
}
