//
//  MobileWalletSocialBackupManager.swift
//  TangemMobileWalletBackup
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemMobileWalletSdk

public protocol MobileWalletSocialBackupManager {
    var isStorageAvailable: Bool { get }

    @discardableResult
    func createBackup(
        context: MobileWalletContext,
        userWalletId: UserWalletId,
        recoveryKey: Data
    ) async throws -> MobileWalletSocialBackup

    func hasBackup() async throws -> Bool

    func loadBackup() async throws -> MobileWalletSocialBackup?

    func importBackup(_ backup: MobileWalletSocialBackup, recoveryKey: Data) async throws -> any WalletBackupPayload

    func deleteBackup(userWalletId: UserWalletId) async throws
}

public final class CommonMobileWalletSocialBackupManager: MobileWalletSocialBackupManager {
    private let fileName = WalletBackupConstants.socialBackupFileName

    private let mobileWalletSdk: MobileWalletSdk
    private let storage: WalletBackupStorage
    private let backupResolver: SocialWalletBackupFormatResolver

    public convenience init(destination: MobileWalletBackupDestination) {
        let storage: WalletBackupStorage = switch destination {
        case .iCloud: ICloudBackupStorage(directory: Self.icloudStorageDirectory)
        }

        self.init(
            mobileWalletSdk: CommonMobileWalletSdk(),
            storage: storage,
            backupResolver: CommonSocialWalletBackupFormatResolver()
        )
    }

    init(
        mobileWalletSdk: MobileWalletSdk,
        storage: WalletBackupStorage,
        backupResolver: SocialWalletBackupFormatResolver
    ) {
        self.mobileWalletSdk = mobileWalletSdk
        self.storage = storage
        self.backupResolver = backupResolver
    }

    public var isStorageAvailable: Bool {
        storage.isAvailable
    }

    @discardableResult
    public func createBackup(
        context: MobileWalletContext,
        userWalletId: UserWalletId,
        recoveryKey: Data
    ) async throws -> MobileWalletSocialBackup {
        guard storage.isAvailable else {
            throw WalletBackupStorageError.storageUnavailable
        }

        let mnemonicWords = try mobileWalletSdk.exportMnemonic(context: context)
        let requiresPassphrase = try mobileWalletSdk.exportPassphrase(context: context).isNotEmpty
        let payload = CommonWalletBackupPayload(
            mnemonicWords: mnemonicWords,
            requiresPassphrase: requiresPassphrase
        )

        let format = SocialWalletBackupFormatVersion.current.resolve(backupResolver)
        let file = try format.makeFile(
            payload: payload,
            walletId: userWalletId.stringValue,
            key: recoveryKey
        )
        let fileData = try encode(file)
        let backup = try format.backup(from: fileData)

        try await storage.write(fileData, fileName: fileName)

        return backup
    }

    public func hasBackup() async throws -> Bool {
        try await backupFile() != nil
    }

    public func loadBackup() async throws -> MobileWalletSocialBackup? {
        guard let file = try await backupFile() else {
            return nil
        }

        let fileData = try await storage.read(file: file)

        let format = try resolveFormat(fileData: fileData)
        return try format.backup(from: fileData)
    }

    public func importBackup(
        _ backup: MobileWalletSocialBackup,
        recoveryKey: Data
    ) async throws -> any WalletBackupPayload {
        let format = try resolveFormat(fileData: backup.fileData)
        return try format.payload(from: backup.fileData, key: recoveryKey)
    }

    public func deleteBackup(userWalletId: UserWalletId) async throws {
        guard let file = try await backupFile() else {
            throw WalletBackupStorageError.fileNotFound
        }

        let fileData = try await storage.read(file: file)
        let backup = try resolveFormat(fileData: fileData).backup(from: fileData)

        guard backup.walletId == userWalletId.stringValue else {
            throw WalletBackupStorageError.walletMismatch
        }

        try await storage.delete(file: file)
    }
}

// MARK: - Private implementation

private extension CommonMobileWalletSocialBackupManager {
    /// Internal and debug builds keep the file user-visible so QA can inspect it.
    static var icloudStorageDirectory: ICloudBackupStorage.Directory {
        AppEnvironment.current.isInternalOrDebug ? .documents : .socialBackup
    }

    func backupFile() async throws -> WalletBackupStorageFile? {
        guard storage.isAvailable else {
            throw WalletBackupStorageError.storageUnavailable
        }

        let files = try await storage.files()
        return files.first(where: { $0.name == fileName })
    }

    func resolveFormat(fileData: Data) throws -> any SocialWalletBackupFormat {
        guard
            let rawVersion = WalletBackupVersionReader.version(in: fileData),
            let version = SocialWalletBackupFormatVersion(rawValue: rawVersion)
        else {
            throw WalletBackupDecodingError.unsupportedVersion
        }

        return version.resolve(backupResolver)
    }

    func encode(_ file: some Encodable) throws -> Data {
        do {
            return try WalletBackupJSONCodec.encode(file)
        } catch {
            throw WalletBackupEncodingError.encodingFailed(error)
        }
    }
}
