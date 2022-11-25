//
//  CardDTO.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk

@available(iOS 13.0, *)
public struct CardDTO: Codable {
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
    public internal(set) var wallets: [Card.Wallet] = []
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

@available(iOS 13.0, *)
public extension CardDTO {
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
