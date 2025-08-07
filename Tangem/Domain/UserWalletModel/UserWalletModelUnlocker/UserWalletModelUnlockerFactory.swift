//
//  UserWalletModelUnlockerFactory.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//
import TangemFoundation

enum UserWalletModelUnlockerFactory {
    static func makeUnlocker(userWalletModel: UserWalletModel) -> UserWalletModelUnlocker {
        return userWalletModel.resolve(CommonUserWalletModelUnlockerResolver())
    }
}

// MARK: - Protocols

protocol UserWalletModelUnlockerResolvable {
    func resolve(_ resolver: UserWalletModelUnlockerResolver) -> UserWalletModelUnlocker
}

protocol UserWalletModelUnlockerResolver {
    func resolve(userWalletId: UserWalletId, config: UserWalletConfig, walletInfo: WalletInfo) -> UserWalletModelUnlocker
}

// MARK: - Resolver

struct CommonUserWalletModelUnlockerResolver: UserWalletModelUnlockerResolver {
    func resolve(userWalletId: UserWalletId, config: UserWalletConfig, walletInfo: WalletInfo) -> UserWalletModelUnlocker {
        switch walletInfo {
        case .cardWallet:
            // already initialized card has passed onboarding
            if let encryptionKey = UserWalletEncryptionKey(config: config) {
                return ScannedCardWalletUnlocker(userWalletId: userWalletId, encryptionKey: encryptionKey)
            }

            return CardWalletUnlocker(userWalletId: userWalletId, config: config)
        case .mobileWallet(let mobileWalletInfo):
            return MobileWalletUnlocker(userWalletId: userWalletId, config: config, info: mobileWalletInfo)
        }
    }
}

// MARK: - CommonUserWalletModel + UserWalletModelUnlockerResolvable

extension CommonUserWalletModel {
    func resolve(_ resolver: UserWalletModelUnlockerResolver) -> UserWalletModelUnlocker {
        resolver.resolve(userWalletId: userWalletId, config: config, walletInfo: walletInfo)
    }
}

// MARK: - LockedUserWalletModel + UserWalletModelUnlockerResolvable

extension LockedUserWalletModel {
    func resolve(_ resolver: UserWalletModelUnlockerResolver) -> UserWalletModelUnlocker {
        resolver.resolve(userWalletId: userWalletId, config: config, walletInfo: userWallet.walletInfo)
    }
}

// MARK: - VisaUserWalletModel + UserWalletModelUnlockerResolvable

extension VisaUserWalletModel {
    func resolve(_ resolver: UserWalletModelUnlockerResolver) -> UserWalletModelUnlocker {
        userWalletModel.resolve(resolver)
    }
}

// MARK: - FakeUserWalletModel + UserWalletModelUnlockerResolvable

extension FakeUserWalletModel {
    func resolve(_ resolver: UserWalletModelUnlockerResolver) -> UserWalletModelUnlocker {
        resolver.resolve(
            userWalletId: userWalletId,
            config: config,
            walletInfo: .mobileWallet(
                HotWalletInfo(
                    hasMnemonicBackup: false,
                    hasICloudBackup: false,
                    isAccessCodeSet: false,
                    keys: []
                ))
        )
    }
}

// MARK: - UserWalletModelMock + UserWalletModelUnlockerResolvable

extension UserWalletModelMock {
    func resolve(_ resolver: UserWalletModelUnlockerResolver) -> UserWalletModelUnlocker {
        resolver.resolve(
            userWalletId: userWalletId,
            config: config,
            walletInfo: .mobileWallet(
                HotWalletInfo(
                    hasMnemonicBackup: false,
                    hasICloudBackup: false,
                    isAccessCodeSet: false,
                    keys: []
                ))
        )
    }
}
