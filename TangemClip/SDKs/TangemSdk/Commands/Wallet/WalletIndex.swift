//
//  WalletPointable.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

/// Index to specific wallet for interaction
/// - Note: Available for cards with COS v.4.0 and higher
public enum WalletIndex: Codable, Equatable {
    case index(Int), publicKey(Data)
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        do {
            let index = try container.decode(Int.self)
            self = .index(index)
        } catch {
            let pubkey = try container.decode(Data.self)
            self = .publicKey(pubkey)
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .index(let index):
            try container.encode(index)
        case .publicKey(let pubkey):
            try container.encode(pubkey)
        }
    }
	
	@discardableResult
	public func addTlvData(to tlvBuilder: TlvBuilder) throws -> TlvBuilder {
		switch self {
		case .index(let index):
			return try tlvBuilder.append(.walletIndex, value: index)
		case .publicKey(let key):
			return try tlvBuilder.append(.walletPublicKey, value: key)
		}
	}
    
}

extension WalletIndex: CustomStringConvertible {
    public var description: String {
        switch self {
        case .index(let index):
            return "Int wallet index \(index)"
        case .publicKey(let pubkey):
            return "Public key wallet index: \(pubkey.asHexString())"
        }
    }
}
