//
//  Address.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

public protocol Address {
    var value: String { get }
    var localizedName: String { get }
	var type: AddressType { get }
}

public enum AddressType: Equatable {
	case plain
	case bitcoin(type: BitcoinAddressType)
    case cardano(type: CardanoAddressType)
	
	var localizedName: String {
		switch self {
		case .plain: return ""
		case .bitcoin(let type): return type.localizedName
        case .cardano(let type): return type.localizedName
		}
	}
}

public struct PlainAddress: Address {
    public let value: String
	public let type: AddressType = .plain
    public var localizedName: String { "" }
    
    public init(value: String) {
        self.value = value
    }
}
