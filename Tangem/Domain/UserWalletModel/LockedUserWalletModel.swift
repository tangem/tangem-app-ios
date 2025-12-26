//
//  LockedUserWalletModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemAssets
import TangemSdk
import TangemNFT
import BlockchainSdk
import TangemVisa
import TangemFoundation
import TangemMobileWalletSdk

class LockedUserWalletModel: UserWalletModel {
    @Injected(\.visaRefreshTokenRepository) private var visaRefreshTokenRepository: VisaRefreshTokenRepository
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    let walletModelsManager: WalletModelsManager = LockedWalletModelsManager()
    var userTokensManager: UserTokensManager { _userTokensManager }
    private let _userTokensManager = LockedUserTokensManager()
    let nftManager: NFTManager = NotSupportedNFTManager()
    let walletImageProvider: WalletImageProviding
    var config: UserWalletConfig

    var isUserWalletLocked: Bool { true }

    var tokensCount: Int? { nil }

    var cardSetLabel: String { config.cardSetLabel }

    var hasBackupCards: Bool {
        userWallet.walletInfo.hasBackupCards
    }

    var hasImportedWallets: Bool { false }

    var emailConfig: EmailConfig? { nil }

    var signer: TangemSigner {
        fatalError("Should not be called for locked wallets")
    }

    var userWalletId: UserWalletId { .init(value: userWallet.userWalletId) }

    var updatePublisher: AnyPublisher<UpdateResult, Never> { _updatePublisher.eraseToAnyPublisher() }

    var emailData: [EmailCollectedData] {
        var data = config.emailData

        let userWalletIdItem = EmailCollectedData(type: .card(.userWalletId), data: userWalletId.stringValue)
        data.append(userWalletIdItem)

        return data
    }

    var tangemApiAuthData: TangemApiAuthorizationData? {
        userWallet.walletInfo.tangemApiAuthData
    }

    var totalBalance: TotalBalanceState {
        .loading(cached: .none)
    }

    var totalBalancePublisher: AnyPublisher<TotalBalanceState, Never> {
        .just(output: totalBalance)
    }

    var analyticsContextData: AnalyticsContextData {
        userWallet.walletInfo.analyticsContextData
    }

    var wcWalletModelProvider: WalletConnectWalletModelProvider {
        CommonWalletConnectWalletModelProvider(walletModelsManager: walletModelsManager)
    }

    var wcAccountsWalletModelProvider: WalletConnectAccountsWalletModelProvider {
        CommonWalletConnectAccountsWalletModelProvider(accountModelsManager: accountModelsManager)
    }

    var userTokensPushNotificationsManager: UserTokensPushNotificationsManager {
        CommonUserTokensPushNotificationsManager(
            userWalletId: userWalletId,
            walletModelsManager: walletModelsManager,
            userTokensManager: userTokensManager,
            remoteStatusSyncing: _userTokensManager,
            derivationManager: nil
        )
    }

    var accountModelsManager: AccountModelsManager {
        DummyCommonAccountModelsManager()
    }
    
    var tangemPayManager: TangemPayManager {
        TangemPayManager(
            userWalletId: userWalletId,
            keysRepository: keysRepository,
            tangemPayAuthorizingInteractor: tangemPayAuthorizingInteractor,
            signer: signer
        )
    }

    var refcodeProvider: RefcodeProvider? {
        return nil
    }

    var keysRepository: KeysRepository {
        CommonKeysRepository(
            userWalletId: userWalletId,
            encryptionKey: .init(userWalletIdSeed: Data()),
            keys: .cardWallet(keys: [])
        )
    }

    var keysDerivingInteractor: any KeysDeriving {
        fatalError("Should not be called for locked wallets")
    }

    var tangemPayAuthorizingInteractor: TangemPayAuthorizing {
        fatalError("Should not be called for locked wallets")
    }

    var name: String { userWallet.name }
    let backupInput: OnboardingInput? = nil
    var userWallet: StoredUserWallet

    private let _updatePublisher: PassthroughSubject<UpdateResult, Never> = .init()

    init(with userWallet: StoredUserWallet) {
        self.userWallet = userWallet
        config = UserWalletConfigFactory().makeConfig(walletInfo: userWallet.walletInfo)
        walletImageProvider = CommonWalletImageProviderFactory().imageProvider(for: userWallet.walletInfo)
    }

    func validate() -> Bool {
        // Nothing to validate for locked wallets
        return true
    }

    func update(type: UpdateRequest) {
        switch type {
        case .backupCompleted(let card, let associatedCardIds):
            if case .mobileWallet = userWallet.walletInfo {
                syncRemoteAfterUpgrade()
            }

            let cardInfo = CardInfo(
                card: CardDTO(card: card),
                walletData: .none,
                associatedCardIds: associatedCardIds
            )

            var mutableCardInfo = cardInfo
            mutableCardInfo.card.wallets = []
            userWallet.walletInfo = .cardWallet(mutableCardInfo)
            config = UserWalletConfigFactory().makeConfig(walletInfo: userWallet.walletInfo)
            userWalletRepository.savePublicData()
            updatePrivateDataAfterIncompletedBackup(cardInfo: cardInfo)
        case .newName:
            break
        case .accessCodeDidSet:
            break
        case .accessCodeDidSkip:
            break
        case .iCloudBackupCompleted:
            break
        case .mnemonicBackupCompleted:
            break
        case .paeraCustomerCreated:
            break
        }
    }

    func addAssociatedCard(cardId: String) {}

    func updatePrivateDataAfterIncompletedBackup(cardInfo: CardInfo) {
        let config = UserWalletConfigFactory().makeConfig(cardInfo: cardInfo)
        guard let encryptionKey = UserWalletEncryptionKey(config: config) else {
            return
        }

        let dataStorage = UserWalletDataStorage()

        guard let existingInfo = dataStorage.fetchPrivateData(encryptionKeys: [userWalletId: encryptionKey])[userWalletId] else {
            return
        }

        var mutableCardInfo = cardInfo

        switch existingInfo {
        case .cardWallet(let keys):
            for wallet in mutableCardInfo.card.wallets {
                if let existingDerivedKeys = keys[wallet.publicKey]?.derivedKeys {
                    mutableCardInfo.card.wallets[wallet.publicKey]?.derivedKeys = existingDerivedKeys
                }
            }
        case .mobileWallet(let keys):
            for wallet in mutableCardInfo.card.wallets {
                if let existingDerivedKeys = keys[wallet.publicKey]?.derivedKeys {
                    mutableCardInfo.card.wallets[wallet.publicKey]?.derivedKeys = existingDerivedKeys
                }
            }
        }

        dataStorage.savePrivateData(
            sensitiveInfo: .cardWallet(keys: mutableCardInfo.card.wallets),
            userWalletId: userWalletId,
            encryptionKey: encryptionKey
        )

        cleanMobileWallet()
    }

    private func syncRemoteAfterUpgrade() {
        runTask(in: self) { model in
            let walletCreationHelper = WalletCreationHelper(
                userWalletId: model.userWalletId,
                userWalletName: model.name,
                userWalletConfig: model.config
            )

            try? await walletCreationHelper.updateWallet()
        }
    }
}

extension LockedUserWalletModel: MainHeaderSupplementInfoProvider {
    var walletHeaderImagePublisher: AnyPublisher<ImageType?, Never> {
        .just(output: config.cardHeaderImage)
    }
}

extension LockedUserWalletModel: AnalyticsContextDataProvider {
    func getAnalyticsContextData() -> AnalyticsContextData? {
        guard case .cardWallet(let cardInfo) = userWallet.walletInfo else {
            return nil
        }

        return AnalyticsContextData(
            productType: config.productType,
            batchId: cardInfo.card.batchId,
            firmware: cardInfo.card.firmwareVersion.stringValue,
            baseCurrency: config.embeddedBlockchain?.currencySymbol,
            userWalletId: userWalletId
        )
    }
}

extension LockedUserWalletModel: UserWalletSerializable {
    func serializePublic() -> StoredUserWallet {
        return userWallet
    }

    func serializePrivate() -> StoredUserWallet.SensitiveInfo {
        fatalError("Should not be called for locked wallets")
    }
}

extension LockedUserWalletModel: AssociatedCardIdsProvider {
    var associatedCardIds: Set<String> {
        switch userWallet.walletInfo {
        case .cardWallet(let cardInfo):
            return cardInfo.associatedCardIds
        case .mobileWallet:
            return []
        }
    }
}

private extension LockedUserWalletModel {
    func cleanMobileWallet() {
        let mobileSdk = CommonMobileWalletSdk()
        do {
            try mobileSdk.delete(walletIDs: [userWalletId])
        } catch {
            AppLogger.error("Failed to delete mobile wallet after upgrade:", error: error)
        }
    }
}
