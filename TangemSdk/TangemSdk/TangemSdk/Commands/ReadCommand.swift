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
public struct SigningMethod: OptionSet, Codable {
    public let rawValue: Int
    
    public init(rawValue: Int) {
        if rawValue & 0x80 != 0 {
            self.rawValue = rawValue
        } else {
            self.rawValue = 0b10000000|(1 << rawValue)
        }
    }
    
    public static let signHash = SigningMethod(rawValue: 0b10000000|(1 << 0))
    public static let signRaw = SigningMethod(rawValue: 0b10000000|(1 << 1))
    public static let signHashSignedByIssuer = SigningMethod(rawValue: 0b10000000|(1 << 2))
    public static let signRawSignedByIssuer = SigningMethod(rawValue: 0b10000000|(1 << 3))
    public static let signHashSignedByIssuerAndUpdateIssuerData = SigningMethod(rawValue: 0b10000000|(1 << 4))
    public static let signRawSignedByIssuerAndUpdateIssuerData = SigningMethod(rawValue: 0b10000000|(1 << 5))
    public static let signPos = SigningMethod(rawValue: 0b10000000|(1 << 6))
    
    public func encode(to encoder: Encoder) throws {
        var values = [String]()
        if contains(SigningMethod.signHash) {
            values.append("sign hash")
        }
        if contains(SigningMethod.signRaw) {
            values.append("sign raw transaction")
        }
        if contains(SigningMethod.signHashSignedByIssuer) {
            values.append("sign hash signed by issuer")
        }
        if contains(SigningMethod.signRawSignedByIssuer) {
            values.append("sign raw signed by issuer")
        }
        if contains(SigningMethod.signHashSignedByIssuerAndUpdateIssuerData) {
            values.append("sign hash signed by issuer and update Issuer_Data")
        }
        if contains(SigningMethod.signRawSignedByIssuerAndUpdateIssuerData) {
            values.append("sign raw signed by issuer and update Issuer_Data")
        }
        if contains(SigningMethod.signPos) {
            values.append("sign POS")
        }
        
        var container = encoder.singleValueContainer()
        try container.encode(values)
    }
}

/// Elliptic curve used for wallet key operations.
public enum EllipticCurve: String, Codable {
    case secp256k1
    case ed25519
}

/// Status of the card and its wallet.
public enum CardStatus: Int, Codable {
    case notPersonalized = 0
    case empty = 1
    case loaded = 2
    case purged = 3
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode("\(self)")
    }
}

public struct ProductMask: OptionSet, Codable {
    public let rawValue: Byte
    
    public init(rawValue: Byte) {
        self.rawValue = rawValue
    }
    
    public static let note = ProductMask(rawValue: 0x01)
    public static let tag = ProductMask(rawValue: 0x02)
    public static let card = ProductMask(rawValue: 0x04)
    
    public func encode(to encoder: Encoder) throws {
        var values = [String]()
        if contains(ProductMask.note) {
            values.append("note")
        }
        if contains(ProductMask.tag) {
            values.append("tag")
        }
        if contains(ProductMask.card) {
            values.append("card")
        }
        
        var container = encoder.singleValueContainer()
        try container.encode(values)
    }
}

/// Stores and maps Tangem card settings.
public struct SettingsMask: OptionSet, Codable {
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
    static let allowUnencrypted = SettingsMask(rawValue: 0x1000)
    static let allowFastEncryption = SettingsMask(rawValue: 0x2000)
    static let protectIssuerDataAgainstReplay = SettingsMask(rawValue: 0x4000)
    static let allowSelectBlockchain = SettingsMask(rawValue: 0x8000)
    static let disablePrecomputedNDEF = SettingsMask(rawValue: 0x00010000)
    static let skipSecurityDelayIfValidatedByIssuer = SettingsMask(rawValue: 0x00020000)
    static let skipCheckPIN2CVCIfValidatedByIssuer = SettingsMask(rawValue: 0x00040000)
    static let skipSecurityDelayIfValidatedByLinkedTerminal = SettingsMask(rawValue: 0x00080000)
    static let restrictOverwriteIssuerExtraDara = SettingsMask(rawValue: 0x00100000)
    static let requireTermTxSignature = SettingsMask(rawValue: 0x01000000)
    static let requireTermCertSignature = SettingsMask(rawValue: 0x02000000)
    static let checkPIN3OnCard = SettingsMask(rawValue: 0x04000000)

    public func encode(to encoder: Encoder) throws {
        var values = [String]()
        if contains(SettingsMask.isReusable) {
            values.append("Is_Reusable")
        }
        if contains(SettingsMask.useActivation) {
            values.append("Use_Activation")
        }
        if contains(SettingsMask.prohibitPurgeWallet) {
            values.append("Prohibit_Purge_Wallet")
        }
        if contains(SettingsMask.useBlock) {
            values.append("Use_Block")
        }
        if contains(SettingsMask.allowSetPIN1) {
            values.append("Allow_SET_PIN1")
        }
        if contains(SettingsMask.allowSetPIN2) {
            values.append("Allow_SET_PIN2")
        }
        if contains(SettingsMask.useCvc) {
            values.append("Use_CVC")
        }
        if contains(SettingsMask.prohibitDefaultPIN1) {
            values.append("Prohibit_Default_PIN1")
        }
        if contains(SettingsMask.useOneCommandAtTime) {
            values.append("Use_One_CommandAtTime")
        }
        if contains(SettingsMask.useNDEF) {
            values.append("Use_NDEF")
        }
        if contains(SettingsMask.useDynamicNDEF) {
            values.append("Use_Dynamic_NDEF")
        }
        if contains(SettingsMask.smartSecurityDelay) {
            values.append("Smart_Security_Delay")
        }
        if contains(SettingsMask.allowUnencrypted) {
            values.append("Allow_Unencrypted")
        }
        if contains(SettingsMask.allowFastEncryption) {
            values.append("Allow_Fast_Encryption")
        }
        if contains(SettingsMask.protectIssuerDataAgainstReplay) {
            values.append("Protect_Issuer_Data_Against_Replay")
        }
        if contains(SettingsMask.allowSelectBlockchain) {
            values.append("Allow_Select_Blockchain")
        }
        if contains(SettingsMask.disablePrecomputedNDEF) {
            values.append("Disable_PrecomputedNDEF")
        }
        if contains(SettingsMask.skipSecurityDelayIfValidatedByIssuer) {
            values.append("Skip_Security_Delay_If_Validated_By_Issuer")
        }
        if contains(SettingsMask.skipCheckPIN2CVCIfValidatedByIssuer) {
            values.append("Skip_Check_PIN2_and_CVC_If_Validated_By_Issuer")
        }
        if contains(SettingsMask.skipSecurityDelayIfValidatedByLinkedTerminal) {
            values.append("Skip_Security_Delay_If_Validated_By_Linked_Terminal")
        }
        if contains(SettingsMask.restrictOverwriteIssuerExtraDara) {
            values.append("Restrict_Overwrite_Issuer_Extra_Data")
        }
        if contains(SettingsMask.requireTermTxSignature) {
            values.append("Require_Term_Tx_Signature")
        }
        if contains(SettingsMask.requireTermCertSignature) {
            values.append("Require_Term_Cert_Signature")
        }
        if contains(SettingsMask.checkPIN3OnCard) {
            values.append("Check_PIN3_on_Card")
        }
        var container = encoder.singleValueContainer()
        try container.encode(values)
    }
}

/// Detailed information about card contents.
public struct CardData: TlvCodable {
    /// Tangem internal manufacturing batch ID.
    public let batchId: String?
    /// Timestamp of manufacturing.
    public let manufactureDateTime: Date?
    /// Name of the issuer.
    public let issuerName: String?
    /// Name of the blockchain.
    public let blockchainName: String?
    /// Signature of CardId with manufacturer’s private key.
    public let manufacturerSignature: Data?
    /// Mask of products enabled on card.
    public let productMask: ProductMask?
    /// Name of the token.
    public let tokenSymbol: String?
    /// Smart contract address.
    public let tokenContractAddress: String?
    /// Number of decimals in token value.
    public let tokenDecimal: Int?
}

///Response for `ReadCommand`. Contains detailed card information.
public struct Card: TlvCodable {
    /// Unique Tangem card ID number.
    public let cardId: String?
    /// Name of Tangem card manufacturer.
    public let manufacturerName: String?
    /// Current status of the card.
    public let status: CardStatus?
    /// Version of Tangem COS.
    public let firmwareVersion: String?
    /// Public key that is used to authenticate the card against manufacturer’s database.
    /// It is generated one time during card manufacturing.
    public let cardPublicKey: Data?
    /// Card settings defined by personalization (bit mask: 0 – Enabled, 1 – Disabled).
    public let settingsMask: SettingsMask?
    /// Public key that is used by the card issuer to sign IssuerData field.
    public let issuerPublicKey: Data?
    /// Explicit text name of the elliptic curve used for all wallet key operations.
    /// Supported curves: ‘secp256k1’ and ‘ed25519’.
    public let curve: EllipticCurve?
    /// Total number of signatures allowed for the wallet when the card was personalized.
    public let maxSignatures: Int?
    /// Defines what data should be submitted to SIGN command.
    public let signingMethod: SigningMethod?
    /// Delay in seconds before COS executes commands protected by PIN2.
    public let pauseBeforePin2: Int?
    /// Public key of the blockchain wallet.
    public let walletPublicKey: Data?
    /// Remaining number of `SignCommand` operations before the wallet will stop signing transactions.
    public let walletRemainingSignatures: Int?
    /// Total number of signed single hashes returned by the card in
    /// `SignCommand` responses since card personalization.
    /// Sums up array elements within all `SignCommand`.
    public let walletSignedHashes: Int?
    /// Any non-zero value indicates that the card experiences some hardware problems.
    /// User should withdraw the value to other blockchain wallet as soon as possible.
    /// Non-zero Health tag will also appear in responses of all other commands.
    public let health: Int?
    /// Whether the card requires issuer’s confirmation of activation
    public let isActivated: Bool
    /// A random challenge generated by personalisation that should be signed and returned
    /// to COS by the issuer to confirm the card has been activated.
    /// This field will not be returned if the card is activated
    public let activationSeed: Data?
    /// Returned only if `SigningMethod.SignPos` enabling POS transactions is supported by card
    public let paymentFlowVersion: Data?
    /// This value can be initialized by terminal and will be increased by COS on execution of every `SignCommand`.
    /// For example, this field can store blockchain “nonce” for quick one-touch transaction on POS terminals.
    /// Returned only if `SigningMethod.SignPos`  enabling POS transactions is supported by card.
    public let userCounter: UInt32?
    /// When this value is true, it means that the application is linked to the card,
    /// and COS will not enforce security delay if `SignCommand` will be called
    /// with `TlvTag.TerminalTransactionSignature` parameter containing a correct signature of raw data
    /// to be signed made with `TlvTag.TerminalPublicKey`.
    public let terminalIsLinked: Bool
    /// Detailed information about card contents. Format is defined by the card issuer.
    /// Cards complaint with Tangem Wallet application should have TLV format.
    public let cardData: CardData?
    
    //MARK: Dynamic NDEF
    /// Remaining number of allowed transaction signatures
    public let remainingSignatures: Int?
    /// Number of hashes signed after personalization (there can be
    /// severeal hases in one transaction)
    public var signedHashes: Int?
    /// First part of a message signed by card
    public let challenge: Data?
    /// Second part of a message signed by card
    public let salt: Data?
    /// [Challenge, Salt] SHA256 signature signed with Wallet_PrivateKey
    public let walletSignature: Data?
}

extension Card {
    init() {
        cardId = nil
        manufacturerName = nil
        status = nil
        firmwareVersion = nil
        cardPublicKey = nil
        settingsMask = nil
        issuerPublicKey = nil
        curve = nil
        maxSignatures = nil
        signingMethod = nil
        pauseBeforePin2 = nil
        walletPublicKey = nil
        walletRemainingSignatures = nil
        walletSignedHashes = nil
        health = nil
        isActivated = false
        activationSeed = nil
        paymentFlowVersion = nil
        userCounter = nil
        terminalIsLinked = false
        cardData = nil
        remainingSignatures = nil
        signedHashes = nil
        challenge = nil
        salt = nil
        walletSignature = nil
    }
}

/// This command receives from the Tangem Card all the data about the card and the wallet,
///  including unique card number (CID or cardId) that has to be submitted while calling all other commands.
public final class ReadCommand: Command {
    public typealias CommandResponse = ReadResponse
    public init() {}
    deinit {
           print("read deinit")
       }
    public func serialize(with environment: CardEnvironment) throws -> CommandApdu {
        /// `CardEnvironment` stores the pin1 value. If no pin1 value was set, it will contain
        /// default value of ‘000000’.
        /// In order to obtain card’s data, [ReadCommand] should use the correct pin 1 value.
        /// The card will not respond if wrong pin 1 has been submitted.
        let tlvBuilder = try createTlvBuilder(legacyMode: environment.legacyMode)
            .append(.pin, value: environment.pin1)
        if let keys = environment.terminalKeys {
            try tlvBuilder.append(.terminalPublicKey, value: keys.publicKey)
        }
        
        let cApdu = CommandApdu(.read, tlv: tlvBuilder.serialize())
        return cApdu
    }
    
    public func deserialize(with environment: CardEnvironment, from responseApdu: ResponseApdu) throws -> ReadResponse {
        guard let tlv = responseApdu.getTlvData(encryptionKey: environment.encryptionKey) else {
            throw SessionError.deserializeApduFailed
        }
        
        let mapper = TlvDecoder(tlv: tlv)
        
        let card = ReadResponse(
            cardId: try mapper.decodeOptional(.cardId),
            manufacturerName: try mapper.decodeOptional(.manufacturerName),
            status: try mapper.decodeOptional(.status),
            firmwareVersion: try mapper.decodeOptional(.firmwareVersion),
            cardPublicKey: try mapper.decodeOptional(.cardPublicKey),
            settingsMask: try mapper.decodeOptional(.settingsMask),
            issuerPublicKey: try mapper.decodeOptional(.issuerPublicKey),
            curve: try mapper.decodeOptional(.curveId),
            maxSignatures: try mapper.decodeOptional(.maxSignatures),
            signingMethod: try mapper.decodeOptional(.signingMethod),
            pauseBeforePin2: try mapper.decodeOptional(.pauseBeforePin2),
            walletPublicKey: try mapper.decodeOptional(.walletPublicKey),
            walletRemainingSignatures: try mapper.decodeOptional(.walletRemainingSignatures),
            walletSignedHashes: try mapper.decodeOptional(.walletSignedHashes),
            health: try mapper.decodeOptional(.health),
            isActivated: try mapper.decode(.isActivated),
            activationSeed: try mapper.decodeOptional(.activationSeed),
            paymentFlowVersion: try mapper.decodeOptional(.paymentFlowVersion),
            userCounter: try mapper.decodeOptional(.userCounter),
            terminalIsLinked: try mapper.decode(.isLinked),
            cardData: try deserializeCardData(tlv: tlv),
            remainingSignatures: try mapper.decodeOptional(.walletRemainingSignatures),
            signedHashes: try mapper.decodeOptional(.walletSignedHashes),
            challenge: try mapper.decodeOptional(.challenge),
            salt: try mapper.decodeOptional(.salt),
            walletSignature: try mapper.decodeOptional(.walletSignature))
        
        return card
    }
    
    private func deserializeCardData(tlv: [Tlv]) throws -> CardData? {
        guard let cardDataValue = tlv.value(for: .cardData),
            let cardDataTlv = Tlv.deserialize(cardDataValue) else {
                return nil
        }
        
        let mapper = TlvDecoder(tlv: cardDataTlv)
        let cardData = CardData(
            batchId: try mapper.decodeOptional(.batchId),
            manufactureDateTime: try mapper.decodeOptional(.manufactureDateTime),
            issuerName: try mapper.decodeOptional(.issuerName),
            blockchainName: try mapper.decodeOptional(.blockchainName),
            manufacturerSignature: try mapper.decodeOptional(.cardIDManufacturerSignature),
            productMask: try mapper.decodeOptional(.productMask),
            tokenSymbol: try mapper.decodeOptional(.tokenSymbol),
            tokenContractAddress: try mapper.decodeOptional(.tokenContractAddress),
            tokenDecimal: try mapper.decodeOptional(.tokenDecimal))
        
        return cardData
    }
}
