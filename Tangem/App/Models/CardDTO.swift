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
        wallets = card.wallets
        attestation = card.attestation
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
            securityDelay = settings.securityDelay
            maxWalletsCount = settings.maxWalletsCount
            isSettingAccessCodeAllowed = settings.isSettingAccessCodeAllowed
            isSettingPasscodeAllowed = settings.isSettingPasscodeAllowed
            isResettingUserCodesAllowed = settings.isResettingUserCodesAllowed
            isLinkedTerminalEnabled = settings.isLinkedTerminalEnabled
            supportedEncryptionModes = settings.supportedEncryptionModes
            isFilesAllowed = settings.isFilesAllowed
            isHDWalletAllowed = settings.isHDWalletAllowed
            isBackupAllowed = settings.isBackupAllowed
        }
    }
}
