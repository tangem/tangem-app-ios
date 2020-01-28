//
//  TlvTag.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation

/// Contains all possible value types that value for `TlvTag` can contain.
public enum TlvValueType {
    case hexString
    case utf8String
    case intValue
    case boolValue
    case data
    case ellipticCurve
    case dateTime
    case productMask
    case settingsMask
    case cardStatus
    case signingMethod
    case byte
}
/// Contains all TLV tags, with their code and descriptive name.
public enum TlvTag: Byte {
    case unknown = 0x00
    case cardId = 0x01
    case pin = 0x10
    case pin2 = 0x11
    case transactionOutHash = 0x50
    case transactionOutHashSize = 0x51
    case walletSignature = 0x61
    case walletRemainingSignatures = 0x62
    case walletSignedHashes = 0x63
    case pause = 0x1C
    case flash = 0x28
    case issuerTxSignature = 0x34
    case status = 0x02
    case cardPublicKey = 0x03
    case cardSignature = 0x04
    case curveId = 0x05
    case hashAlgId = 0x06
    case signingMethod = 0x07
    case maxSignatures = 0x08
    case pauseBeforePin2 = 0x09
    case settingsMask = 0x0A
    case cardData = 0x0C
    case ndefData = 0x0D
    case health = 0x0F
    case newPin = 0x12
    case newPin2 = 0x13
    case newPinHash = 0x14
    case newPin2Hash = 0x15
    case challenge = 0x16
    case salt = 0x17
    case validationCounter = 0x18
    case cvc = 0x19
    case sessionKeyA = 0x1A
    case sessionKeyB = 0x1B
    case manufacturerName = 0x20
    case manufacturerSignature = 0x21
    case issuerPublicKey = 0x30
    case issuerTransactionPublicKey = 0x31
    case issuerData = 0x32
    case issuerDataSignature = 0x33
    case issuerDataCounter = 0x35
    case isActivated = 0x3A
    case activationSeed = 0x3B
    case paymentFlowVersion = 0x54
    case userCounter = 0x2C
    case resetPin = 0x36
    case codePageAddress = 0x40
    case codePageCount = 0x41
    case codeHash = 0x42
    case trOutRaw = 0x52
    case walletPublicKey = 0x60
    case firmwareVersion = 0x80
    case batchId = 0x81
    case manufactureDateTime = 0x82
    case issuerName = 0x83
    case blockchainName = 0x84
    case manufacturerPublicKey = 0x85
    case cardIDManufacturerSignature = 0x86
    case tokenSymbol = 0xA0
    case tokenContractAddress = 0xA1
    case tokenDecimal = 0xA2
    case denomination = 0xC0
    case validatedBalance = 0xC1
    case lastSignDate = 0xC2
    case denominationText = 0xC3
    case checkWalletCounter = 0x64
    case productMask = 0x8A
    case isLinked = 0x58
    case terminalPublicKey = 0x5C
    case terminalTransactionSignature = 0x57
    case legacyMode = 0x29
    
    /// `TlvValueType` associated with a `TlvTag`
    var valueType: TlvValueType {
        switch self {
        case .cardId, .pin, .pin2, .batchId:
            return .hexString
        case .manufacturerName, .firmwareVersion, .issuerName, .blockchainName, .tokenSymbol, .tokenContractAddress:
            return .utf8String
        case .curveId:
            return .ellipticCurve
        case .maxSignatures, .pauseBeforePin2,
             .walletRemainingSignatures, .walletSignedHashes, .health, .userCounter, .tokenDecimal, .issuerDataCounter:
            return .intValue
        case .isActivated, .isLinked:
            return .boolValue
        case .manufactureDateTime:
            return .dateTime
        case .productMask:
            return .productMask
        case .settingsMask:
            return .settingsMask
        case .status:
            return .cardStatus
        case .signingMethod:
            return .signingMethod
        case .transactionOutHashSize, .legacyMode:
            return .byte
        default:
            return .data
        }
    }
}
