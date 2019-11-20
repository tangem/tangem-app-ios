//
//  ResponseApdu.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation

/// Stores response data from the card and parses it to `Tlv` and `StatusWord`.
public struct ResponseApdu {
    /// Status word code, reflecting the status of the response
    public var sw: UInt16 { return UInt16( (UInt16(sw1) << 8) | UInt16(sw2) ) }
    /// Parsed status word.
    public var statusWord: StatusWord { return StatusWord(rawValue: sw) ?? .unknown }
    
    private let sw1: Byte
    private let sw2: Byte
    private let data: Data
    
    public init(_ data: Data, _ sw1: Byte, _ sw2: Byte) {
        self.sw1 = sw1
        self.sw2 = sw2
        self.data = data
    }
    
    /// Converts raw response data  to the array of TLVs.
    /// - Parameter encryptionKey: key to decrypt response.
    /// (Encryption / decryption functionality is not implemented yet.)
    public func getTlvData(encryptionKey: Data? = nil) -> [Tlv]? {
        guard let tlv = Array<Tlv>.init(data) else { // Initialize TLV array with raw data from card response
            return nil
        }
        
        //[REDACTED_TODO_COMMENT]
        return tlv
    }
}
