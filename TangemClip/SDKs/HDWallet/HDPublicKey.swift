//
//  PublicKey.swift
//  HDWalletKit
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 Essentia. All rights reserved.
//

import Foundation
import TangemSdkClips_secp256k1

public struct HDPublicKey {
    public let compressedPublicKey: Data
    public let uncompressedPublicKey: Data
    public let coin: Coin
	
    public init?(privateKey: Data, coin: Coin) {
        guard
            let pubkey = Secp256k1Utils.generatePublicKey(for: privateKey),
            let compressed = Secp256k1Utils.convertKeyToCompressed(pubkey)
        else { return nil }
        
        self.compressedPublicKey = compressed
        self.uncompressedPublicKey = pubkey
        self.coin = coin
    }
    
    public init(base58: Data, coin: Coin) {
        let publickKey = Base58.base58FromBytes(base58.bytes)
        self.compressedPublicKey = Data(hex: publickKey)
        self.uncompressedPublicKey = Data(hex: publickKey)
        self.coin = coin
    }
    
	public init(uncompressedPublicKey: Data, compressedPublicKey: Data, coin: Coin) {
		self.uncompressedPublicKey = uncompressedPublicKey
		self.compressedPublicKey = compressedPublicKey
		self.coin = coin
	}
    
    public func get() -> String {
        return compressedPublicKey.toHexString()
    }
    
    public var data: Data {
        return Data(hex: get())
    }
}

extension Secp256k1Utils {
    public static func generatePublicKey(for privateKey: Data) -> Data? {
        guard let ctx = secp256k1_context_create(UInt32(SECP256K1_CONTEXT_SIGN|SECP256K1_CONTEXT_VERIFY)) else { return nil }
        let privateKey = privateKey.bytes
        guard secp256k1_ec_seckey_verify(ctx, privateKey) == 1 else { return nil }
        
        var publicKeySecp = secp256k1_pubkey()
        guard secp256k1_ec_pubkey_create(ctx, &publicKeySecp, privateKey) == 1 else { return nil }
        
        var publicKeyLength: Int = 65
        var publicKeyUncompressed = Array(repeating: Byte(0), count: publicKeyLength)
        secp256k1_ec_pubkey_serialize(ctx, &publicKeyUncompressed, &publicKeyLength, &publicKeySecp, UInt32(SECP256K1_EC_UNCOMPRESSED))
        return Data(publicKeyUncompressed)
    }
}
