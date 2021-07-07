//
//  PublicKey.swift
//  HDWalletKit
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2018 Essentia. All rights reserved.
//

import Foundation
import TangemSdk

public struct HDPublicKey {
    public let compressedPublicKey: Data
    public let uncompressedPublicKey: Data
    public let coin: Coin
	
//    public init?(privateKey: Data, coin: Coin) {
//        guard
//            let pubkey = Secp256k1Utils.generateUncompressedPublicKey(from: privateKey),
//            let compressed = Secp256k1Utils.convertKeyToCompressed(pubkey)
//        else { return nil }
//
//        self.compressedPublicKey = compressed
//        self.uncompressedPublicKey = pubkey
//        self.coin = coin
//    }
    
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
