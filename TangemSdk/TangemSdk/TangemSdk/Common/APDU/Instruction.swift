//
//  Instruction.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation

/// Instruction code that determines the type of the command that is sent to the Tangem card.
/// It is used in the construction of `CommandApdu`.
public enum Instruction: Byte {
    case unknown = 0x00
    case read = 0xF2
    case verifyCard = 0xF3
    case validateCard = 0xF4
    case verifyCode = 0xF5
    case writeIssuerData = 0xF6
    case getIssuerData = 0xF7
    case createWallet = 0xF8
    case checkWallet = 0xF9
    case swapPin = 0xFA
    case sign = 0xFB
    case purgeWallet = 0xFC
    case activate = 0xFE
    case openSession = 0xFF
}
