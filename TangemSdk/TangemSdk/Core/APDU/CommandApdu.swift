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
public class CommandApdu {
    //MARK: Header
    fileprivate let cla: Byte
    fileprivate let ins: Byte
    fileprivate let p1:  Byte
    fileprivate let p2:  Byte
    
    //MARK: Body
    fileprivate let data: Data
    fileprivate let le: Int
    
    /// Optional encryption
    private let encryptionKey: Data?
    
    /// Convinience initializer
    /// - Parameter instruction: Instruction code
    /// - Parameter tlv: data
    /// - Parameter encryptionMode:  optional encryption mode. Default to none
    /// - Parameter encryptionKey:  optional encryption
    public convenience init(_ instruction: Instruction, tlv: [Tlv], encryptionMode: EncryptionMode = .none, encryptionKey: Data? = nil) {
        self.init(ins: instruction.rawValue,
                  p1: encryptionMode.rawValue,
                  tlv: tlv,
                  encryptionKey: encryptionKey)
    }
    
    /// Raw initializer
    /// - Parameter cla: Instruction class (CLA) byte
    /// - Parameter ins: Instruction code (INS) byte
    /// - Parameter p1:  P1 parameter byte
    /// - Parameter p2:  P2 parameter byte
    /// - Parameter le:  Le byte
    /// - Parameter tlv: data
    /// - Parameter encryptionKey: optional encryption
    public init(cla: Byte = 0x00,
                ins: Byte,
                p1: Byte = 0x0,
                p2: Byte = 0x0,
                le: Int = -1,
                tlv: [Tlv],
                encryptionKey: Data? = nil) {
        self.cla = cla
        self.ins = ins
        self.p1 = p1
        self.p2 = p2
        self.le = le
        self.encryptionKey = encryptionKey
        data = tlv.serialize() //serialize tlv array
    }
}

@available(iOS 13.0, *)
extension NFCISO7816APDU {
    convenience init(_ commandApdu: CommandApdu) {
        self.init(instructionClass: commandApdu.cla, instructionCode: commandApdu.ins, p1Parameter: commandApdu.p1, p2Parameter: commandApdu.p2, data: commandApdu.data, expectedResponseLength: commandApdu.le)
    }
}
