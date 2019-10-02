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
    
    /// Optional encryption
    private let encryptionKey: Data?
    
    public init(_ instruction: Instruction, tlv: [Tlv], encryptionMode: EncryptionMode = .none, encryptionKey: Data? = nil) {
        self.init(instruction: instruction.rawValue, tlv: tlv, p1: encryptionMode.rawValue, p2: 0x0, encryptionKey: encryptionKey)
    }
    
    public init(instruction: Byte, tlv: [Tlv], p1: Byte = 0x0, p2: Byte = 0x0, encryptionKey: Data? = nil) {
        cla = Constants.isoCLA
        ins = instruction
        self.p1 = p1
        self.p2 = p2
        self.encryptionKey = encryptionKey
        data = tlv.serialize() //serialize tlv array
    }
    
    /// Serialize command apdu to raw Data
    /// - Parameter encryptionKey: encrypt if key exist
    public func serizalize() -> NFCISO7816APDU? {
        let lc = data.count
        var apdu = Data()
        
        let apduLength = calculateApduLength(for: lc)
        apdu.reserveCapacity(apduLength)
        
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
    
    /// calculate length for efficient reserve capacity
    /// - Parameter dataLength: data  count
    private func calculateApduLength(for dataLength: Int) -> Int {
        var length = 4 // CLA, INS, P1, P2
        
        if dataLength > 0 { //if has data
            length += 1 // reserve for LC
            if dataLength >= 256 {
                length += 2 //long length format
            }
            length += dataLength // DATA length
        }
        
        return length
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
