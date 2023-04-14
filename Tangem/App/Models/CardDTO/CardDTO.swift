//
//  CardDTOv4.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

struct CardDTO: Codable {
    public let cardId: String
    public let batchId: String
    public let cardPublicKey: Data
    public let firmwareVersion: FirmwareVersion
    public let manufacturer: Card.Manufacturer
    public let issuer: Card.Issuer
    public internal(set) var settings: Settings
    public internal(set) var userSettings: UserSettings
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
        userSettings = .init(isUserCodeRecoveryAllowed: card.userSettings.isUserCodeRecoveryAllowed)
        linkedTerminalStatus = card.linkedTerminalStatus
        isAccessCodeSet = card.isAccessCodeSet
        isPasscodeSet = card.isPasscodeSet
        supportedCurves = card.supportedCurves
        backupStatus = card.backupStatus
        wallets = mapWallets(card.wallets)
        attestation = card.attestation
    }

    init(cardDTOv4: CardDTOv4) {
        cardId = cardDTOv4.cardId
        batchId = cardDTOv4.batchId
        cardPublicKey = cardDTOv4.cardPublicKey
        firmwareVersion = cardDTOv4.firmwareVersion
        manufacturer = cardDTOv4.manufacturer
        issuer = cardDTOv4.issuer
        settings = .init(settingsV4: cardDTOv4.settings)
        userSettings = .init(isUserCodeRecoveryAllowed: cardDTOv4.firmwareVersion >= .backupAvailable)
        linkedTerminalStatus = cardDTOv4.linkedTerminalStatus
        isAccessCodeSet = cardDTOv4.isAccessCodeSet
        isPasscodeSet = cardDTOv4.isPasscodeSet
        supportedCurves = cardDTOv4.supportedCurves
        backupStatus = cardDTOv4.backupStatus
        wallets = cardDTOv4.wallets.map {
            .init(
                publicKey: $0.publicKey,
                chainCode: $0.chainCode,
                curve: $0.curve,
                settings: $0.settings,
                index: $0.index,
                proof: $0.proof,
                isImported: cardDTOv4.firmwareVersion < .keysImportAvailable ? false : nil,
                hasBackup: $0.hasBackup
            )
        }
        attestation = cardDTOv4.attestation
    }

    mutating func updateWallets(with newWallets: [Card.Wallet]) {
        wallets = mapWallets(newWallets)
    }

    private func mapWallets(_ cardWallets: [Card.Wallet]) -> [CardDTO.Wallet] {
        return cardWallets.map {
            .init(
                publicKey: $0.publicKey,
                chainCode: $0.chainCode,
                curve: $0.curve,
                settings: $0.settings,
                index: $0.index,
                proof: $0.proof,
                isImported: $0.isImported,
                hasBackup: $0.hasBackup
            )
        }
    }
}

extension CardDTO {
    struct Settings: Codable {
        public let securityDelay: Int
        public let maxWalletsCount: Int
        public internal(set) var isSettingAccessCodeAllowed: Bool
        public internal(set) var isSettingPasscodeAllowed: Bool
        public internal(set) var isRemovingUserCodesAllowed: Bool
        public let isLinkedTerminalEnabled: Bool
        public let supportedEncryptionModes: [EncryptionMode]
        public let isFilesAllowed: Bool
        public let isHDWalletAllowed: Bool
        public let isBackupAllowed: Bool
        public let isKeysImportAllowed: Bool

        init(settings: Card.Settings) {
            securityDelay = settings.securityDelay
            maxWalletsCount = settings.maxWalletsCount
            isSettingAccessCodeAllowed = settings.isSettingAccessCodeAllowed
            isSettingPasscodeAllowed = settings.isSettingPasscodeAllowed
            isRemovingUserCodesAllowed = settings.isRemovingUserCodesAllowed
            isLinkedTerminalEnabled = settings.isLinkedTerminalEnabled
            supportedEncryptionModes = settings.supportedEncryptionModes
            isFilesAllowed = settings.isFilesAllowed
            isHDWalletAllowed = settings.isHDWalletAllowed
            isBackupAllowed = settings.isBackupAllowed
            isKeysImportAllowed = settings.isKeysImportAllowed
        }

        init(settingsV4: CardDTOv4.Settings) {
            securityDelay = settingsV4.securityDelay
            maxWalletsCount = settingsV4.maxWalletsCount
            isSettingAccessCodeAllowed = settingsV4.isSettingAccessCodeAllowed
            isSettingPasscodeAllowed = settingsV4.isSettingPasscodeAllowed
            isRemovingUserCodesAllowed = settingsV4.isResettingUserCodesAllowed
            isLinkedTerminalEnabled = settingsV4.isLinkedTerminalEnabled
            supportedEncryptionModes = settingsV4.supportedEncryptionModes
            isFilesAllowed = settingsV4.isFilesAllowed
            isHDWalletAllowed = settingsV4.isHDWalletAllowed
            isBackupAllowed = settingsV4.isBackupAllowed
            isKeysImportAllowed = false
        }
    }
}

extension CardDTO {
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
        /// Has this key been imported to a card. E.g. from seed phrase
        public let isImported: Bool?
        /// Does this wallet has a backup
        public var hasBackup: Bool
        /// Derived keys according to `Config.defaultDerivationPaths`
        public var derivedKeys: [DerivationPath: ExtendedPublicKey] = [:]
    }
}

extension CardDTO {
    struct UserSettings: Codable {
        /// Is allowed to recover user codes
        public internal(set) var isUserCodeRecoveryAllowed: Bool
    }
}

extension Array where Element == CardDTO.Wallet {
    subscript(publicKey: Data) -> Element? {
        get {
            return first(where: { $0.publicKey == publicKey })
        }
        set(newValue) {
            let index = firstIndex(where: { $0.publicKey == publicKey })

            if let newValue = newValue {
                if let index = index {
                    self[index] = newValue
                } else {
                    append(newValue)
                }
            } else {
                if let index = index {
                    remove(at: index)
                }
            }
        }
    }
}
