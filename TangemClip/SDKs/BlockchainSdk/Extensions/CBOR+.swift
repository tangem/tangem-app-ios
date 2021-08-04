//
//  CBOR+.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import SwiftCBOR
import TangemSdk

extension CBOR {
    public static func indefiniteLenghtArrayWith(_ elements: [CBOR]) -> [UInt8] {
        var result = CBOR.encodeArrayStreamStart()
        result += CBOR.encodeArrayChunk(elements)
        result += CBOR.encodeStreamEnd()
        return result
    }
    
    public static func combineEncodedArrays(_ encodedArrays: [[UInt8]]) -> [UInt8] {
        var res = encodedArrays.count.encode()
        res[0] = res[0] | 0b100_00000
        res.append(contentsOf: encodedArrays.reduce(into: [], { (result, array) in
            result += array
        }))
        return res
    }
    
    public static func encodeUnspentOutput(_ output: String, index: UInt8) -> [UInt8] {
        var res = 2.encode()
        res[0] = res[0] | 0b100_00000
        
        let outputBytes = output.toUInt8
        var resString = outputBytes.count.encode()
        resString[0] = resString[0] | 0b010_00000
        res.append(contentsOf: resString)
        
        res.append(contentsOf: output.toUInt8)
        res.append(index)
        
        return res
    }
}
