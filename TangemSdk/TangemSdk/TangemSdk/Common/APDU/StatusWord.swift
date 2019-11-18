//
//  Status.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation

/// Part of a response from the card, shows the status of the operation   (combined sw1 and sw2)
public enum StatusWord: UInt16 {
    case unknown = 0x0000
    case processCompleted = 0x9000
    case invalidParams = 0x6A86
    case errorProcessingCommand = 0x6286
    case invalidState = 0x6985
    case insNotSupported = 0x6D00
    case needEcryption = 0x6982
    case needPause = 0x9789
    case pin1Changed = 0x9001
    case pin2Changed = 0x9002
    case pin3Changed = 0x9003
    //case pinsNotChanged = 0x9000 //equal to processCompleted
}
