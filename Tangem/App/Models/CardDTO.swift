//
//  CardDTO.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

/// Response for `ReadCommand`. Contains detailed card information.
@available(iOS 13.0, *)
public struct CardDTO: Codable {
    /// Unique Tangem card ID number.
    public let cardId: String
    /// Tangem internal manufacturing batch ID.
    public let batchId: String
    /// Public key that is used to authenticate the card against manufacturer’s database.
    /// It is generated one time during card manufacturing.
    public let cardPublicKey: Data
    /// Version of Tangem Card Operation System.
    public let firmwareVersion: FirmwareVersion
    /// Information about manufacturer
    public let manufacturer: Card.Manufacturer
    /// Information about issuer
    public let issuer: Card.Issuer
    /// Card setting, that were set during the personalization process
    public internal(set) var settings: Settings
    /// When this value is `current`, it means that the application is linked to the card,
    /// and COS will not enforce security delay if `SignCommand` will be called
    /// with `TlvTag.TerminalTransactionSignature` parameter containing a correct signature of raw data
    /// to be signed made with `TlvTag.TerminalPublicKey`.
    public let linkedTerminalStatus: Card.LinkedTerminalStatus
    /// Access code (aka PIN1) is set.
    public internal(set) var isAccessCodeSet: Bool
    /// Passcode (aka PIN2) is set.
    /// COS v. 4.33 and higher - always available
    /// COS v. 1.19 and lower - always unavailable
    /// COS  v > 1.19 &&  v < 4.33 - available only if `isResettingUserCodesAllowed` set to true
    public internal(set) var isPasscodeSet: Bool?
    /// Array of ellipctic curves, supported by this card. Only wallets with these curves can be created.
    public let supportedCurves: [EllipticCurve]
    /// Status of card's backup
    public internal(set) var backupStatus: Card.BackupStatus?
    /// Wallets, created on the card, that can be used for signature
    public internal(set) var wallets: [Card.Wallet] = []
    /// Card's attestation report
    public internal(set) var attestation: Attestation = .empty

    init(card: Card) {
        self.cardId = card.cardId
        self.batchId = card.batchId
        self.cardPublicKey = card.cardPublicKey
        self.firmwareVersion = card.firmwareVersion
        self.manufacturer = card.manufacturer
        self.issuer = card.issuer
        self.settings = .init(settings: card.settings)
        self.linkedTerminalStatus = card.linkedTerminalStatus
        self.isAccessCodeSet = card.isAccessCodeSet
        self.isPasscodeSet = card.isPasscodeSet
        self.supportedCurves = card.supportedCurves
        self.backupStatus = card.backupStatus
        self.wallets = card.wallets
        self.attestation = card.attestation
    }
}

// MARK:- Card Settings
@available(iOS 13.0, *)
public extension CardDTO {
    struct Settings: Codable {
        /// Delay in milliseconds before executing a command that affects any sensitive data or wallets on the card
        public let securityDelay: Int
        /// Maximum number of wallets that can be created for this card
        public let maxWalletsCount: Int
        /// Is allowed to change access code
        public internal(set) var isSettingAccessCodeAllowed: Bool
        /// Is  allowed to change passcode
        public internal(set) var isSettingPasscodeAllowed: Bool
        /// Is allowed to remove access code
        public internal(set) var isResettingUserCodesAllowed: Bool
        /// Is LinkedTerminal feature enabled
        public let isLinkedTerminalEnabled: Bool
        /// All  encryption modes supported by the card
        public let supportedEncryptionModes: [EncryptionMode]
        /// Is allowed to write files
        public let isFilesAllowed: Bool
        /// Is allowed to use hd wallet
        public let isHDWalletAllowed: Bool
        /// Is allowed to create backup
        public let isBackupAllowed: Bool

        init(settings: Card.Settings) {
            self.securityDelay = settings.securityDelay
            self.maxWalletsCount = settings.maxWalletsCount
            self.isSettingAccessCodeAllowed = settings.isSettingAccessCodeAllowed
            self.isSettingPasscodeAllowed = settings.isSettingPasscodeAllowed
            self.isResettingUserCodesAllowed = settings.isResettingUserCodesAllowed
            self.isLinkedTerminalEnabled = settings.isLinkedTerminalEnabled
            self.supportedEncryptionModes = settings.supportedEncryptionModes
            self.isFilesAllowed = settings.isFilesAllowed
            self.isHDWalletAllowed = settings.isHDWalletAllowed
            self.isBackupAllowed = settings.isBackupAllowed
        }
    }
}

