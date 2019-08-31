//
//  CardTag.swift
//  TangemKit
//
//  Created by [REDACTED_AUTHOR]
//

public enum CardTag: UInt8 {
    case unknown = 0x00
    case cardId = 0x01
    case pin = 0x10
    case pin2 = 0x11
    case transactionOutHash = 0x50
    case transactionOutHashSize = 0x51
    case signature = 0x61
    case walletRemainingSignatures = 0x62
    case walletSignedHashes = 0x63
    case pause = 0x1C
    case flash = 0x28
    case issuerTxSignature = 0x34
}
