//
//  ReadCommand.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation

public typealias Card = ReadResponse

public enum SigningMethod: Int {
    case signHash = 0
    case signRaw = 1
    case signHashValidatedByIssuer = 2
    case signRawValidatedByIssuer = 3
    case signHashValidatedByIssuerAndWriteIssuerData = 4
    case SignRawValidatedByIssuerAndWriteIssuerData = 5
    case signPos = 6
}

public enum EllipticCurve: String {
    case secp256k1
    case ed25519
}

public enum CardStatus: Int {
    case notPersonalized = 0
    case empty = 1
    case loaded = 2
    case purged = 3
}

public enum ProductMask: Byte {
    case note = 0x01
    case tag = 0x02
    case card = 0x04
}

public struct SettingsMask: OptionSet {
    public let rawValue: Int
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    static let isReusable = SettingsMask(rawValue: 0x0001)
    static let useActivation = SettingsMask(rawValue: 0x0002)
    static let prohibitPurgeWallet = SettingsMask(rawValue: 0x0004)
    static let useBlock = SettingsMask(rawValue: 0x0008)
    static let allowSetPIN1 = SettingsMask(rawValue: 0x0010)
    static let allowSetPIN2 = SettingsMask(rawValue: 0x0020)
    static let useCvc = SettingsMask(rawValue: 0x0040)
    static let prohibitDefaultPIN1 = SettingsMask(rawValue: 0x0080)
    static let useOneCommandAtTime = SettingsMask(rawValue: 0x0100)
    static let useNDEF = SettingsMask(rawValue: 0x0200)
    static let useDynamicNDEF = SettingsMask(rawValue: 0x0400)
    static let smartSecurityDelay = SettingsMask(rawValue: 0x0800)
    static let disablePrecomputedNDEF = SettingsMask(rawValue: 0x00010000)
    static let skipSecurityDelayIfValidatedByIssuer = SettingsMask(rawValue: 0x00020000)
    static let skipCheckPIN2CVCIfValidatedByIssuer = SettingsMask(rawValue: 0x00040000)
    static let skipSecurityDelayIfValidatedByLinkedTerminal = SettingsMask(rawValue: 0x00080000)
    static let restrictOverwriteIssuerExtraDara = SettingsMask(rawValue: 0x00100000)
    static let requireTermTxSignature = SettingsMask(rawValue: 0x01000000)
    static let requireTermCertSignature = SettingsMask(rawValue: 0x02000000)
    static let checkPIN3OnCard = SettingsMask(rawValue: 0x04000000)
}

public struct ReadResponse: TlvMappable {
    let cardId: String
    let manufacturerName: String
    let status: CardStatus
    
    let firmwareVersion: String?
    let cardPublicKey: String?
    let settingsMask: SettingsMask?
    let issuerPublicKey: String?
    let curve: EllipticCurve?
    let maxSignatures: Int?
    let signingMethpod: SigningMethod?
    let pauseBeforePin2: Int?
    let walletPublicKey: Data?
    let walletRemainingSignatures: Int?
    let walletSignedHashes: Int?
    let health: Int?
    let isActivated: Bool?
    let activationSeed: Data?
    let paymentFlowVersion: Data?
    let userCounter: UInt32?
    
    //Card Data
    
    let batchId: Int?
    let manufactureDateTime: String?
    let issuerName: String?
    let blockchainName: String?
    let manufacturerSignature: Data?
    let productMask: ProductMask?
    
    let tokenSymbol: String?
    let tokenContractAddress: String?
    let tokenDecimal: Int?
    
    //Dynamic NDEF
    
    let remainingSignatures: Int?
    let signedHashes: Int?
    
    public init?(from tlv: [Tlv]) {
        let mapper = TlvMapper(tlv: tlv)
        do {
            cardId = try mapper.map(.cardId)
            manufacturerName = try mapper.map(.manufacturerName)
            status = try mapper.map(.status)
            
            curve = try mapper.mapOptional(.curveId)
            walletPublicKey = try mapper.mapOptional(.walletPublicKey)
            firmwareVersion = try mapper.mapOptional(.firmwareVersion)
            cardPublicKey = try mapper.mapOptional(.cardPublicKey)
            settingsMask = try mapper.mapOptional(.settingsMask)
            issuerPublicKey = try mapper.mapOptional(.issuerPublicKey)
            maxSignatures = try mapper.mapOptional(.maxSignatures)
            signingMethpod = try mapper.mapOptional(.signingMethod)
            pauseBeforePin2 = try mapper.mapOptional(.pauseBeforePin2)
            walletRemainingSignatures = try mapper.mapOptional(.walletRemainingSignatures)
            walletSignedHashes = try mapper.mapOptional(.walletSignedHashes)
            health = try mapper.mapOptional(.health)
            isActivated = try mapper.mapOptional(.isActivated)
            activationSeed = try mapper.mapOptional(.activationSeed)
            paymentFlowVersion = try mapper.mapOptional(.paymentFlowVersion)
            userCounter = try mapper.mapOptional(.userCounter)
            batchId = try mapper.mapOptional(.batchId)
            manufactureDateTime = try mapper.mapOptional(.manufactureDateTime)
            issuerName = try mapper.mapOptional(.issuerName)
            blockchainName = try mapper.mapOptional(.blockchainName)
            manufacturerSignature = try mapper.mapOptional(.manufacturerSignature)
            productMask = try mapper.mapOptional(.productMask)
            
            tokenSymbol = try mapper.mapOptional(.tokenSymbol)
            tokenContractAddress = try mapper.mapOptional(.tokenContractAddress)
            tokenDecimal = try mapper.mapOptional(.tokenDecimal)
            
            remainingSignatures = try mapper.mapOptional(.walletRemainingSignatures)
            signedHashes = try mapper.mapOptional(.walletSignedHashes)
        } catch {
            print(error)
            return nil
        }
    }
}

@available(iOS 13.0, *)
public final class ReadCommand: CommandSerializer {
    public typealias CommandResponse = ReadResponse
    
    let pin1: String
    
    init(pin1: String) {
        self.pin1 = pin1
    }
    
    public func serialize(with environment: CardEnvironment) -> CommandApdu {
        var tlvData = [Tlv(.pin, value: environment.pin1.sha256())]
        if let keys = environment.terminalKeys {
            tlvData.append(Tlv(.terminalPublicKey, value: keys.publicKey))
        }
        
        let cApdu = CommandApdu(.read, tlv: tlvData)
        return cApdu
    }
}
