//
//  ResponseApdu.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation

public class ResponseApdu {
    /// Raw status from combined sw1 and sw2
    public var sw: UInt16 { return UInt16( (UInt16(sw1) << 8) | UInt16(sw2) ) }
    /// Status from combined sw1 and sw2
    public var status: Status? { return Status(rawValue: sw) }
    
    private let sw1: Byte
    private let sw2: Byte
    private let data: Data
    
    public init(_ data: Data, _ sw1: Byte, _ sw2: Byte) {
        self.sw1 = sw1
        self.sw2 = sw2
        self.data = data
    }
    
    /// Deserialize raw apdu data
    /// - Parameter encryptionKey: decrypt if key exist - not implemented
    public func getTlvData(encryptionKey: Data? = nil) -> [Tlv]? {
        guard let tlv = Array<Tlv>.init(data) else { // Initialize TLV array with raw data from card response
            return nil
        }
        
        //handle nested tlv here to facilitate further response mapping
        let allTlv = tlv.compactMap { tlv -> [Tlv]? in
            if tlv.tag.hasNestedTlv, let nestedTlv = Array<Tlv>.init(tlv.value) {
                return nestedTlv
            }
            return nil
        }.flatMap { $0 }
        //[REDACTED_TODO_COMMENT]
        return allTlv
    }
}
