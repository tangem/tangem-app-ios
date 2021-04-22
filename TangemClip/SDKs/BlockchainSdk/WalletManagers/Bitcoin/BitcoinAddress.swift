//
//  BitcoinAddress.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

public struct BitcoinAddress: Address {
	public let type: AddressType
	public let value: String
	
	public var localizedName: String { type.localizedName }
	
	public init(type: BitcoinAddressType, value: String) {
		self.type = .bitcoin(type: type)
		self.value = value
	}
}

public struct BitcoinScriptAddress: Address {
    public let script: HDWalletScript
	public let value: String
	public let type: AddressType
	
	public var localizedName: String { type.localizedName }
	
    public init(script: HDWalletScript, value: String, type: BitcoinAddressType) {
		self.script = script
		self.value = value
		self.type = .bitcoin(type: type)
	}
	
}
