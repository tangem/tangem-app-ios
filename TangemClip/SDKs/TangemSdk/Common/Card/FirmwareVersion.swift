//
//  FirmwareVersion.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

public enum FirmwareType: String, Codable, CaseIterable {
	case sdk = "d SDK"
	case release = "r"
	case special
	
	static func type(for str: String) -> FirmwareType {
		FirmwareType(rawValue: str) ?? .special
	}
}

@available(*, unavailable, renamed: "FirmwareType")
typealias CardType = FirmwareType

/// Holds information about card firmware version included version saved on card `version`,
/// splitted to `major`, `minor` and `hotFix` and `FirmwareType`
public struct FirmwareVersion: Codable {
	
	public static let zero = FirmwareVersion(major: 0, minor: 0)
	public static let max = FirmwareVersion(major: Int.max, minor: 0)
	
	/// Version that saved on card
	public let version: String
	
	private(set) public var major: Int = 0
	private(set) public var minor: Int = 0
	private(set) public var hotFix: Int = 0
	private(set) public var type: FirmwareType? = nil
	
	public var versionDouble: Double {
		Double("\(major).\(minor)")!
	}
	
	public init(version: String) {
		self.version = version
		
		let versionCleaned = version.remove("\0")
		
		let cardTypeStr = versionCleaned.trimmingCharacters(in: CharacterSet(charactersIn: "0123456789."))
		let result = versionCleaned.remove(cardTypeStr)
		
		var splitted = result.split(separator: ".")
		if let majorStr = splitted.first, let major = Int(majorStr) {
			self.major = major
			splitted.removeFirst()
		}
		
		if let minorStr = splitted.first, let minor = Int(minorStr) {
			self.minor = minor
			splitted.removeFirst()
		}
		
		if let hotFixStr = splitted.first, let hotFix = Int(hotFixStr) {
			self.hotFix = hotFix
		}
		
		type = .type(for: cardTypeStr)
	}
	
	public init(major: Int, minor: Int, hotFix: Int = 0, type: FirmwareType = .sdk) {
		self.major = major
		self.minor = minor
		self.hotFix = hotFix
		self.type = type
		
		let hotFixSuffix = ".\(hotFix)"
		var version = "\(major).\(minor)"
		version += hotFix != 0 ? hotFixSuffix : ""
		version += type.rawValue
		
		self.version = version
	}
}

extension FirmwareVersion: Comparable {
	public static func < (lhs: FirmwareVersion, rhs: FirmwareVersion) -> Bool {
		if lhs.major != rhs.major {
			return lhs.major < rhs.major
		} else if lhs.minor != rhs.minor {
			return lhs.minor < rhs.minor
		} else {
			return lhs.hotFix < rhs.hotFix
		}
	}
	
	public static func == (lhs: FirmwareVersion, rhs: FirmwareVersion) -> Bool {
		lhs.major == rhs.major && lhs.minor == rhs.minor && lhs.hotFix == rhs.hotFix
	}
	
	public static func >= (lhs: FirmwareVersion, rhs: FirmwareVersion) -> Bool {
		if lhs.major != rhs.major {
			return lhs.major > rhs.major
		} else if lhs.minor != rhs.minor {
			return lhs.minor > rhs.minor
		} else {
			return lhs.hotFix >= rhs.hotFix
		}
	}
	
	public static func < (lhs: FirmwareVersion?, rhs: FirmwareVersion) -> Bool {
		guard let lhs = lhs else { return false }
		
		return lhs < rhs
	}
	
	public static func >= (lhs: FirmwareVersion?, rhs: FirmwareVersion) -> Bool {
		guard let lhs = lhs else { return false }
		
		return lhs >= rhs
	}
	
}
