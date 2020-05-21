//
//  CommandApdu.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import CoreNFC


/// Class that provides conversion of serialized request and Instruction code
/// to a raw data that can be sent to the card.
public struct CommandApdu: Equatable {    
    //MARK: Header
    fileprivate let cla: Byte
    /// Instruction code that determines the type of request for the card.
    fileprivate let ins: Byte
    fileprivate let p1:  Byte
    fileprivate let p2:  Byte
    
    //MARK: Body
    /// An array of  serialized TLVs that are to be sent to the card
    fileprivate let data: Data
    fileprivate let le: Int
    
    /// Convinience initializer
    /// - Parameter instruction: Instruction code
    /// - Parameter tlv: data
    public init(_ instruction: Instruction, tlv: Data) {
        self.init(ins: instruction.rawValue, tlv: tlv)
    }
    
    /// Raw initializer
    /// - Parameter cla: Instruction class (CLA) byte
    /// - Parameter ins: Instruction code (INS) byte
    /// - Parameter p1:  P1 parameter byte
    /// - Parameter p2:  P2 parameter byte
    /// - Parameter le:  Le byte
    /// - Parameter tlv: data
    /// - Parameter encryptionKey: optional encryption - not implemented
    public init(cla: Byte = 0x00,
                ins: Byte,
                p1: Byte = 0x0,
                p2: Byte = 0x0,
                le: Int = -1,
                tlv: Data) {
        self.cla = cla
        self.ins = ins
        self.p1 = p1
        self.p2 = p2
        self.le = le
        data = tlv
    }
    
    
    /// <#Description#>
    /// - Parameters:
    /// - Parameter encryptionMode:  optional encryption mode. Default to none
    /// - Parameter encryptionKey:  optional encryption
    /// - Returns: <#description#>
    public func encrypt(encryptionMode: EncryptionMode = .none, encryptionKey: Data? = nil) -> CommandApdu {
        return self
    }
}

@available(iOS 13.0, *)
extension NFCISO7816APDU {
    convenience init(_ commandApdu: CommandApdu) {
        self.init(instructionClass: commandApdu.cla, instructionCode: commandApdu.ins, p1Parameter: commandApdu.p1, p2Parameter: commandApdu.p2, data: commandApdu.data, expectedResponseLength: commandApdu.le)
    }
}
