//
//  ReadCommand.swift
//  TangemSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation

public typealias ReadResponse = Card

/// Determines which type of data is required for signing.
public struct SigningMethod: OptionSet {
    public let rawValue: Int
    
    public init(rawValue: Int) {
        if rawValue & 0x80 != 0 {
            self.rawValue = rawValue
        } else {
            self.rawValue = 0b10000000|(1 << rawValue)
        }
    }
    
    static let signHash = SigningMethod(rawValue: 0b10000000|(1 << 0))
    static let signRaw = SigningMethod(rawValue: 0b10000000|(1 << 1))
    static let signHashSignedByIssuer = SigningMethod(rawValue: 0b10000000|(1 << 2))
    static let signRawSignedByIssuer = SigningMethod(rawValue: 0b10000000|(1 << 3))
    static let signHashSignedByIssuerAndUpdateIssuerData = SigningMethod(rawValue: 0b10000000|(1 << 4))
    static let signRawSignedByIssuerAndUpdateIssuerData = SigningMethod(rawValue: 0b10000000|(1 << 5))
    static let signPos = SigningMethod(rawValue: 0b10000000|(1 << 6))
}

/// Elliptic curve used for wallet key operations.
public enum EllipticCurve: String {
    case secp256k1
    case ed25519
}

/// Status of the card and its wallet.
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

/// Stores and maps Tangem card settings.
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

/// Detailed information about card contents.
public struct CardData {
    public let batchId: String?
    public let manufactureDateTime: Date?
    public let issuerName: String?
    public let blockchainName: String?
    public let manufacturerSignature: Data?
    public let productMask: ProductMask?
    
    public let tokenSymbol: String?
    public let tokenContractAddress: String?
    public let tokenDecimal: Int?
}

///Response for `ReadCommand`. Contains detailed card information.
public struct Card {
    public let cardId: String
    public let manufacturerName: String?
    public let status: CardStatus?
    
    public let firmwareVersion: String?
    public let cardPublicKey: Data?
    public let settingsMask: SettingsMask?
    public let issuerPublicKey: Data?
    public let curve: EllipticCurve?
    public let maxSignatures: Int?
    public let signingMethod: SigningMethod?
    public let pauseBeforePin2: Int?
    public let walletPublicKey: Data?
    public let walletRemainingSignatures: Int?
    public let walletSignedHashes: Int?
    public let health: Int?
    public let isActivated: Bool
    public let activationSeed: Data?
    public let paymentFlowVersion: Data?
    public let userCounter: UInt32?
    public let terminalIsLinked: Bool
    public let cardData: CardData?
    
    //Dynamic NDEF
    public let remainingSignatures: Int?
    public var signedHashes: Int?
    public let challenge: Data?
    public let salt: Data?
    public let walletSignature: Data?
}

/// This command receives from the Tangem Card all the data about the card and the wallet,
///  including unique card number (CID or cardId) that has to be submitted while calling all other commands.
public final class ReadCommand: CommandSerializer {
    public typealias CommandResponse = ReadResponse
    
    public init() {}
    
    public func serialize(with environment: CardEnvironment) -> CommandApdu {
        /// `CardEnvironment` stores the pin1 value. If no pin1 value was set, it will contain
        /// default value of ‘000000’.
        /// In order to obtain card’s data, [ReadCommand] should use the correct pin 1 value.
        /// The card will not respond if wrong pin 1 has been submitted.
        var tlvData = [Tlv(.pin, value: environment.pin1.sha256())]
        if let keys = environment.terminalKeys {
            tlvData.append(Tlv(.terminalPublicKey, value: keys.publicKey))
        }
        
        let cApdu = CommandApdu(.read, tlv: tlvData)
        return cApdu
    }
    
    public func deserialize(with environment: CardEnvironment, from responseApdu: ResponseApdu) throws -> ReadResponse {
        guard let tlv = responseApdu.getTlvData(encryptionKey: environment.encryptionKey) else {
            throw TaskError.serializeCommandError
        }
        
        let mapper = TlvMapper(tlv: tlv)
        
        let card = Card(
            cardId: try mapper.map(.cardId),
            manufacturerName: try mapper.mapOptional(.manufacturerName),
            status: try mapper.mapOptional(.status),
            firmwareVersion: try mapper.mapOptional(.firmwareVersion),
            cardPublicKey: try mapper.mapOptional(.cardPublicKey),
            settingsMask: try mapper.mapOptional(.settingsMask),
            issuerPublicKey: try mapper.mapOptional(.issuerPublicKey),
            curve: try mapper.mapOptional(.curveId),
            maxSignatures: try mapper.mapOptional(.maxSignatures),
            signingMethod: try mapper.mapOptional(.signingMethod),
            pauseBeforePin2: try mapper.mapOptional(.pauseBeforePin2),
            walletPublicKey: try mapper.mapOptional(.walletPublicKey),
            walletRemainingSignatures: try mapper.mapOptional(.walletRemainingSignatures),
            walletSignedHashes: try mapper.mapOptional(.walletSignedHashes),
            health: try mapper.mapOptional(.health),
            isActivated: try mapper.map(.isActivated),
            activationSeed: try mapper.mapOptional(.activationSeed),
            paymentFlowVersion: try mapper.mapOptional(.paymentFlowVersion),
            userCounter: try mapper.mapOptional(.userCounter),
            terminalIsLinked: try mapper.map(.isLinked),
            cardData: try deserializeCardData(tlv: tlv),
            remainingSignatures: try mapper.mapOptional(.walletRemainingSignatures),
            signedHashes: try mapper.mapOptional(.walletSignedHashes),
            challenge: try mapper.mapOptional(.challenge),
            salt: try mapper.mapOptional(.salt),
            walletSignature: try mapper.mapOptional(.walletSignature))
        
        return card
    }
    
    private func deserializeCardData(tlv: [Tlv]) throws -> CardData? {
        guard let cardDataValue = tlv.value(for: .cardData),
            let cardDataTlv = Array<Tlv>.init(cardDataValue) else {
                return nil
        }
        
        let mapper = TlvMapper(tlv: cardDataTlv)
        let cardData = CardData(
            batchId: try mapper.mapOptional(.batchId),
            manufactureDateTime: try mapper.mapOptional(.manufactureDateTime),
            issuerName: try mapper.mapOptional(.issuerName),
            blockchainName: try mapper.mapOptional(.blockchainName),
            manufacturerSignature: try mapper.mapOptional(.manufacturerSignature),
            productMask: try mapper.mapOptional(.productMask),
            tokenSymbol: try mapper.mapOptional(.tokenSymbol),
            tokenContractAddress: try mapper.mapOptional(.tokenContractAddress),
            tokenDecimal: try mapper.mapOptional(.tokenDecimal))
        
        return cardData
    }
}
