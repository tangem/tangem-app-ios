//
//  CardanoAddressService.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import Sodium
import SwiftCBOR
import CryptoSwift

public class CardanoAddressService {
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
    
    public func validate(_ address: String) -> Bool {
        guard !address.isEmpty else {
            return false
        }
        
        guard let decoded58 = address.base58DecodedData?.bytes,
            decoded58.count > 0 else {
                return false
        }
        
        guard let cborArray = try? CBORDecoder(input: decoded58).decodeItem(),
            let addressArray = cborArray[0],
            let checkSumArray = cborArray[1] else {
                return false
        }
        
        guard case let CBOR.tagged(_, cborByteString) = addressArray,
            case let CBOR.byteString(addressBytes) = cborByteString else {
                return false
        }
        
        guard case let CBOR.unsignedInt(checksum) = checkSumArray else {
            return false
        }
        
        let calculatedChecksum = UInt64(addressBytes.crc32())
        return calculatedChecksum == checksum
    }
}
