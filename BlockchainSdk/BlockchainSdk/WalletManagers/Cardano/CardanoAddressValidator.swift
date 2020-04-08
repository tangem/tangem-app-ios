//
//  CardanoAddressValidator.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import SwiftCBOR

public class CardanoAddressValidator {
    func validate(_ address: String) -> Bool {
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
