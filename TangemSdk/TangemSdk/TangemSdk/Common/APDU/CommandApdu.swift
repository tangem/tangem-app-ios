//
//  CommandApdu.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import CoreNFC


public struct CommandApdu: Equatable {
    /// Fix nfc issues with long-running commands and security delay for iPhone 7/7+. Card firmware 2.39
    /// 4 - Timeout setting for ping nfc-module
    private static let legacyMode = Tlv(.legacyMode, value: Data([Byte(4)]))
    
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
    public init(_ instruction: Instruction, tlv: [Tlv], encryptionMode: EncryptionMode = .none, encryptionKey: Data? = nil) {
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
    /// - Parameter encryptionKey: optional encryption - not implemented
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
        data = CommandApdu.applyAdditionalParams(tlv: tlv).serialize() //serialize tlv array
        
        //[REDACTED_TODO_COMMENT]
    }
    
    private static func applyAdditionalParams(tlv: [Tlv]) -> [Tlv] {
        var modifiedTlv = tlv
        if needLegacyMode {
            modifiedTlv.append(legacyMode)
        }
        return modifiedTlv
    }
    
    /// Fix nfc issues with long-running commands and security delay for iPhone 7/7+. Card firmware 2.39
    private static var needLegacyMode: Bool {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier == "iPhone9,1" || identifier == "iPhone9,2" || identifier == "iPhone9,3" || identifier == "iPhone9,4"
    }
}

@available(iOS 13.0, *)
extension NFCISO7816APDU {
    convenience init(_ commandApdu: CommandApdu) {
        self.init(instructionClass: commandApdu.cla, instructionCode: commandApdu.ins, p1Parameter: commandApdu.p1, p2Parameter: commandApdu.p2, data: commandApdu.data, expectedResponseLength: commandApdu.le)
    }
}
