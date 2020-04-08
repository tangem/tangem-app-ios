//
//  CardanoAddressFactory.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import Sodium
import SwiftCBOR
import CryptoSwift

public class CardanoAddressFactory {
    public func makeAddress(from walletPublicKey: Data) -> String {
        let hexPublicKeyExtended = walletPublicKey + Data(repeating: 0, count: 32)
        let forSha3 = ([0, [0, CBOR.byteString(hexPublicKeyExtended.toBytes)], [:]] as CBOR).encode()
        let sha = forSha3.sha3(.sha256)
        let pkHash = Sodium().genericHash.hash(message: sha, outputLength: 28)!
        let addr = ([CBOR.byteString(pkHash), [:], 0] as CBOR).encode()
        let checksum = UInt64(addr.crc32())
        let addrItem = CBOR.tagged(CBOR.Tag(rawValue: 24), CBOR.byteString(addr))
        let hexAddress = ([addrItem, CBOR.unsignedInt(checksum)] as CBOR).encode()
        let walletAddress = String(base58: Data(hexAddress))
        return walletAddress
    }
}
