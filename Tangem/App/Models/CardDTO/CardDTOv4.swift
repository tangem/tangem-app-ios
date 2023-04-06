//
//  CardDTO.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

struct CardDTOv4: Codable {
    public let cardId: String
    public let batchId: String
    public let cardPublicKey: Data
    public let firmwareVersion: FirmwareVersion
    public let manufacturer: Card.Manufacturer
    public let issuer: Card.Issuer
    public internal(set) var settings: Settings
    public let linkedTerminalStatus: Card.LinkedTerminalStatus
    public internal(set) var isAccessCodeSet: Bool
    public internal(set) var isPasscodeSet: Bool?
    public let supportedCurves: [EllipticCurve]
    public internal(set) var backupStatus: Card.BackupStatus?
    public internal(set) var wallets: [Wallet] = []
    public internal(set) var attestation: Attestation = .empty

    init(card: Card) {
        cardId = card.cardId
        batchId = card.batchId
        cardPublicKey = card.cardPublicKey
        firmwareVersion = card.firmwareVersion
        manufacturer = card.manufacturer
        issuer = card.issuer
        settings = .init(settings: card.settings)
        linkedTerminalStatus = card.linkedTerminalStatus
        isAccessCodeSet = card.isAccessCodeSet
        isPasscodeSet = card.isPasscodeSet
        supportedCurves = card.supportedCurves
        backupStatus = card.backupStatus
        wallets = card.wallets.map {
            .init(
                publicKey: $0.publicKey,
                chainCode: $0.chainCode,
                curve: $0.curve,
                settings: $0.settings,
                index: $0.index,
                proof: $0.proof,
                hasBackup: $0.hasBackup
            )
        }
        attestation = card.attestation
    }
}

extension CardDTOv4 {
    struct Settings: Codable {
        public let securityDelay: Int
        public let maxWalletsCount: Int
        public internal(set) var isSettingAccessCodeAllowed: Bool
        public internal(set) var isSettingPasscodeAllowed: Bool
        public internal(set) var isResettingUserCodesAllowed: Bool
        public let isLinkedTerminalEnabled: Bool
        public let supportedEncryptionModes: [EncryptionMode]
        public let isFilesAllowed: Bool
        public let isHDWalletAllowed: Bool
        public let isBackupAllowed: Bool

        init(settings: Card.Settings) {
            securityDelay = settings.securityDelay
            maxWalletsCount = settings.maxWalletsCount
            isSettingAccessCodeAllowed = settings.isSettingAccessCodeAllowed
            isSettingPasscodeAllowed = settings.isSettingPasscodeAllowed
            isResettingUserCodesAllowed = settings.isRemovingUserCodesAllowed
            isLinkedTerminalEnabled = settings.isLinkedTerminalEnabled
            supportedEncryptionModes = settings.supportedEncryptionModes
            isFilesAllowed = settings.isFilesAllowed
            isHDWalletAllowed = settings.isHDWalletAllowed
            isBackupAllowed = settings.isBackupAllowed
        }
    }
}

extension CardDTOv4 {
    /// Describing wallets created on card
    struct Wallet: Codable {
        /// Wallet's public key.  For `secp256k1`, the key can be compressed or uncompressed. Use `Secp256k1Key` for any conversions.
        public let publicKey: Data
        /// Optional chain code for BIP32 derivation.
        public let chainCode: Data?
        /// Elliptic curve used for all wallet key operations.
        public let curve: EllipticCurve
        /// Wallet's settings
        public let settings: Card.Wallet.Settings
        /// Total number of signed hashes returned by the wallet since its creation
        /// COS 1.16+
        public var totalSignedHashes: Int?
        /// Remaining number of `Sign` operations before the wallet will stop signing any data.
        /// - Note: This counter were deprecated for cards with COS 4.0 and higher
        public var remainingSignatures: Int?
        /// Index of the wallet in the card storage
        public let index: Int
        /// Proof for BLS Proof of possession scheme (POP)
        public let proof: Data?
        /// Does this wallet has a backup
        public var hasBackup: Bool
        /// Derived keys according to `Config.defaultDerivationPaths`
        public var derivedKeys: [DerivationPath: ExtendedPublicKey] = [:]
    }
}
