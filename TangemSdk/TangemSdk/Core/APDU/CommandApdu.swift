//
//  CommandApdu.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
#if canImport(CoreNFC)
import CoreNFC
#endif

@available(iOS 13.0, *)
public struct CommandApdu {
    //MARK: Header
    private let cla: Byte
    private let ins: Byte
    private let p1:  Byte
    private let p2:  Byte
    
    //MARK: Body
    private let data: Data
    private let le: Byte = 0x00 //  Estiamted response length. Not used
    
    public init(_ instruction: Instruction, tlv: [Tlv]) {
        self.init(instruction: instruction.rawValue, tlv: tlv )
    }
    
    public init(instruction: Byte, tlv: [Tlv]) {
           cla = Constants.isoCLA
           ins = instruction
           p1 = 0
           p2 = 0
           data = tlv.bytes //serizalize tlv array
    }
    
    /// Serialize command apdu to raw Data
    /// - Parameter encryptionKey: encrypt if key exist
    public func serizalize(encryptionKey: Data? = nil) -> NFCISO7816APDU? {
        //calculate length for efficient reserve capacity
        var length = 4 // CLA, INS, P1, P2
        let lc = data.count
        if lc > 0 { //if has data
            length += 1 // reserve for LC
            if lc >= 256 {
                length += 2 //long length format
            }
            length += lc // DATA length
        }
        
        var apdu = Data()
        apdu.reserveCapacity(length)
        apdu.append(cla)
        apdu.append(ins)
        apdu.append(p1)
        apdu.append(p2)
        
        if lc > 0 { //if has data
            if lc < 256 { //short len
                apdu.append(lc.byte)
            } else { //long len
                apdu.append(0)
                apdu.append(contentsOf: lc.bytes2bigEndian)
            }
            apdu.append(contentsOf: data)
        }
        
        return NFCISO7816APDU(data: apdu)
    }
}

//MARK: Constants
@available(iOS 13.0, *)
private extension CommandApdu {
    private enum Constants {
        //ISO CLA format
        static let isoCLA: Byte = 0x00
    }
}
