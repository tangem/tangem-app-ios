//
//  CommonUserWalletModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI
import BlockchainSdk
import TangemAssets
import TangemVisa
import TangemSdk
import TangemNFT
import TangemFoundation
import TangemMobileWalletSdk

class CommonUserWalletModel {
    // MARK: Services

    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository
    @Injected(\.visaRefreshTokenRepository) private var visaRefreshTokenRepository: VisaRefreshTokenRepository

    let walletModelsManager: WalletModelsManager
    let userTokensManager: UserTokensManager
    let userTokenListManager: UserTokenListManager
    let nftManager: NFTManager
    let keysRepository: KeysRepository
    let derivationManager: DerivationManager?
    let totalBalanceProvider: TotalBalanceProviding
    let userTokensPushNotificationsManager: UserTokensPushNotificationsManager
    let accountModelsManager: AccountModelsManager

    var emailConfig: EmailConfig? {
        config.emailConfig
    }

    let userWalletId: UserWalletId

    private(set) var walletInfo: WalletInfo
    var config: UserWalletConfig

    private(set) var name: String

    private var _walletImageProvider: WalletImageProviding?

    private let _updatePublisher: PassthroughSubject<UpdateResult, Never> = .init()
    private let _cardHeaderImagePublisher: CurrentValueSubject<ImageType?, Never>

    init(
        walletInfo: WalletInfo,
        name: String,
        config: UserWalletConfig,
        userWalletId: UserWalletId,
        walletModelsManager: WalletModelsManager,
        userTokensManager: UserTokensManager,
        userTokenListManager: UserTokenListManager,
        nftManager: NFTManager,
        keysRepository: KeysRepository,
        derivationManager: DerivationManager?,
        totalBalanceProvider: TotalBalanceProviding,
        userTokensPushNotificationsManager: UserTokensPushNotificationsManager,
        accountModelsManager: AccountModelsManager
    ) {
        self.walletInfo = walletInfo
        self.config = config
        self.userWalletId = userWalletId
        self.name = name
        self.walletModelsManager = walletModelsManager
        self.userTokensManager = userTokensManager
        self.userTokenListManager = userTokenListManager
        self.nftManager = nftManager
        self.keysRepository = keysRepository
        self.derivationManager = derivationManager
        self.totalBalanceProvider = totalBalanceProvider
        self.userTokensPushNotificationsManager = userTokensPushNotificationsManager
        self.accountModelsManager = accountModelsManager

        _cardHeaderImagePublisher = .init(config.cardHeaderImage)
        appendPersistentBlockchains()
        userTokensManager.sync {}
    }

    deinit {
        AppLogger.debug(self)
    }

    private func validateBackup(_ backupStatus: Card.BackupStatus?, wallets: [CardDTO.Wallet]) -> Bool {
        switch walletInfo {
        case .cardWallet(let cardInfo):
            let backupValidator = BackupValidator()
            if !backupValidator.validate(backupStatus: cardInfo.card.backupStatus, wallets: wallets) {
                return false
            }

            return true

        case .mobileWallet:
            // nothing to validate here
            return true
        }
    }

    private func appendPersistentBlockchains() {
        guard let persistentBlockchains = config.persistentBlockchains else {
            return
        }

        userTokenListManager.update(.append(persistentBlockchains), shouldUpload: true)
    }

    private func updateConfiguration(walletInfo: WalletInfo) {
        self.walletInfo = walletInfo
        config = UserWalletConfigFactory().makeConfig(walletInfo: walletInfo)
        userWalletRepository.save(userWalletModel: self)
        _updatePublisher.send(.configurationChanged(model: self))
    }
}

extension CommonUserWalletModel {
    enum WalletsBalanceState {
        case inProgress
        case loaded
    }
}

// [REDACTED_TODO_COMMENT]
extension CommonUserWalletModel: TangemSdkFactory {
    func makeTangemSdk() -> TangemSdk {
        config.makeTangemSdk()
    }
}

// MARK: - UserWalletModel

extension CommonUserWalletModel: UserWalletModel {
    var wcWalletModelProvider: WalletConnectWalletModelProvider {
        CommonWalletConnectWalletModelProvider(walletModelsManager: walletModelsManager)
    }

    var refcodeProvider: RefcodeProvider? {
        walletInfo.refcodeProvider
    }

    var tangemApiAuthData: TangemApiAuthorizationData? {
        walletInfo.tangemApiAuthData
    }

    var hasBackupCards: Bool {
        walletInfo.hasBackupCards
    }

    var signer: TangemSigner {
        config.tangemSigner
    }

    var cardSetLabel: String {
        config.cardSetLabel
    }

    var walletImageProvider: WalletImageProviding {
        if let _walletImageProvider {
            return _walletImageProvider
        }
        let walletImageProvider = CommonWalletImageProviderFactory().imageProvider(for: walletInfo)
        _walletImageProvider = walletImageProvider
        return walletImageProvider
    }

    var emailData: [EmailCollectedData] {
        var data = config.emailData

        let userWalletIdItem = EmailCollectedData(type: .card(.userWalletId), data: userWalletId.stringValue)
        data.append(userWalletIdItem)

        return data
    }

    var backupInput: OnboardingInput? {
        switch walletInfo {
        case .cardWallet(let cardInfo):
            let factory = OnboardingInputFactory(
                sdkFactory: config,
                onboardingStepsBuilderFactory: config
            )

            return factory.makeBackupInput(cardInfo: cardInfo, userWalletModel: self)
        case .mobileWallet:
            return nil
        }
    }

    var updatePublisher: AnyPublisher<UpdateResult, Never> {
        _updatePublisher.eraseToAnyPublisher()
    }

    func update(type: UpdateRequest) {
        switch type {
        case .newName(let name):
            self.name = name
            userWalletRepository.savePublicData()
            _updatePublisher.send(.nameDidChange(name: name))

        case .backupCompleted:
            // we have to read an actual status from backup validator
            _updatePublisher.send(.configurationChanged(model: self))

        case .backupStarted(let card):
            switch walletInfo {
            case .cardWallet(let cardInfo):
                var mutableCardInfo = cardInfo
                for updatedWallet in card.wallets {
                    mutableCardInfo.card.wallets[updatedWallet.publicKey]?.hasBackup = updatedWallet.hasBackup
                }

                mutableCardInfo.card.settings = CardDTO.Settings(settings: card.settings)
                mutableCardInfo.card.isAccessCodeSet = card.isAccessCodeSet
                mutableCardInfo.card.backupStatus = card.backupStatus
                updateConfiguration(walletInfo: .cardWallet(mutableCardInfo))

                _cardHeaderImagePublisher.send(config.cardHeaderImage)
                // prevent save until onboarding completed
                if userWalletRepository.models[userWalletId] != nil {
                    userWalletRepository.save(userWalletModel: self)
                }
            case .mobileWallet(let info):
                var mutableCardInfo = CardInfo(card: CardDTO(card: card), walletData: .none, associatedCardIds: [])
                for wallet in mutableCardInfo.card.wallets {
                    if let existingDerivedKeys = info.keys[wallet.publicKey]?.derivedKeys {
                        mutableCardInfo.card.wallets[wallet.publicKey]?.derivedKeys = existingDerivedKeys
                    }
                }

                _walletImageProvider = nil
                updateConfiguration(walletInfo: WalletInfo.cardWallet(mutableCardInfo))
                _cardHeaderImagePublisher.send(config.cardHeaderImage)
                cleanMobileWallet()
            }

        case .accessCodeDidSet:
            switch walletInfo {
            case .cardWallet:
                break
            case .mobileWallet(let info):
                var mutableInfo = info
                mutableInfo.isAccessCodeSet = true
                updateConfiguration(walletInfo: .mobileWallet(mutableInfo))
            }

        case .iCloudBackupCompleted:
            switch walletInfo {
            case .cardWallet:
                break
            case .mobileWallet(let info):
                var mutableInfo = info
                mutableInfo.hasICloudBackup = true
                updateConfiguration(walletInfo: .mobileWallet(mutableInfo))
            }

        case .mnemonicBackupCompleted:
            switch walletInfo {
            case .cardWallet:
                break
            case .mobileWallet(let info):
                var mutableInfo = info
                mutableInfo.hasMnemonicBackup = true
                updateConfiguration(walletInfo: .mobileWallet(mutableInfo))
            }

        case .tangemPayOfferAccepted(let tangemPayAccount):
            _updatePublisher.send(.tangemPayOfferAccepted(tangemPayAccount))
        }
    }

    func addAssociatedCard(cardId: String) {
        switch walletInfo {
        case .cardWallet(let cardInfo):
            var mutableCardInfo = cardInfo
            if !mutableCardInfo.associatedCardIds.contains(cardId) {
                mutableCardInfo.associatedCardIds.insert(cardId)
            }
            walletInfo = .cardWallet(mutableCardInfo)

        case .mobileWallet:
            return
        }
    }

    func validate() -> Bool {
        switch walletInfo {
        case .cardWallet(let cardInfo):
            let pendingBackupManager = PendingBackupManager()
            if pendingBackupManager.fetchPendingCard(cardInfo.card.cardId) != nil {
                return false
            }

            guard validateBackup(cardInfo.card.backupStatus, wallets: cardInfo.card.wallets) else {
                return false
            }

            return true
        case .mobileWallet:
            return true
        }
    }
}

extension CommonUserWalletModel: MainHeaderSupplementInfoProvider {
    var walletHeaderImagePublisher: AnyPublisher<ImageType?, Never> {
        _cardHeaderImagePublisher
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
}

extension CommonUserWalletModel: MainHeaderUserWalletStateInfoProvider {
    var isUserWalletLocked: Bool { false }

    var isTokensListEmpty: Bool { userTokenListManager.userTokensList.entries.isEmpty }

    var hasImportedWallets: Bool {
        keysRepository.keys.contains(where: { $0.isImported ?? false })
    }
}

extension CommonUserWalletModel: KeysDerivingProvider {
    var keysDerivingInteractor: KeysDeriving {
        switch walletInfo {
        case .cardWallet(let cardInfo):
            return KeysDerivingCardInteractor(with: cardInfo)
        case .mobileWallet:
            return KeysDerivingMobileWalletInteractor(userWalletId: userWalletId, userWalletConfig: config)
        }
    }
}

extension CommonUserWalletModel: TotalBalanceProviding {
    var totalBalance: TotalBalanceState {
        totalBalanceProvider.totalBalance
    }

    var totalBalancePublisher: AnyPublisher<TotalBalanceState, Never> {
        totalBalanceProvider.totalBalancePublisher
    }
}

extension CommonUserWalletModel: AnalyticsContextDataProvider {
    var analyticsContextData: AnalyticsContextData {
        walletInfo.analyticsContextData
    }
}

extension CommonUserWalletModel: UserWalletSerializable {
    func serializePublic() -> StoredUserWallet {
        let name = name.isEmpty ? config.defaultName : name

        switch walletInfo {
        case .cardWallet(let cardInfo):
            var mutableCardInfo = cardInfo
            mutableCardInfo.card.wallets = []

            let newStoredUserWallet = StoredUserWallet(
                userWalletId: userWalletId.value,
                name: name,
                walletInfo: .cardWallet(mutableCardInfo)
            )

            return newStoredUserWallet
        case .mobileWallet(let mobileWalletInfo):
            let newStoredUserWallet = StoredUserWallet(
                userWalletId: userWalletId.value,
                name: name,
                walletInfo: .mobileWallet(mobileWalletInfo),
            )

            return newStoredUserWallet
        }
    }

    func serializePrivate() -> StoredUserWallet.SensitiveInfo {
        switch walletInfo {
        case .cardWallet(let cardInfo):
            return .cardWallet(keys: cardInfo.card.wallets)
        case .mobileWallet:
            return .mobileWallet(keys: keysRepository.keys)
        }
    }
}

extension CommonUserWalletModel: AssociatedCardIdsProvider {
    var associatedCardIds: Set<String> {
        switch walletInfo {
        case .cardWallet(let cardInfo):
            return cardInfo.associatedCardIds
        case .mobileWallet:
            return []
        }
    }
}

// MARK: - Private methods

private extension CommonUserWalletModel {
    func cleanMobileWallet() {
        let mobileSdk = CommonMobileWalletSdk()
        do {
            try mobileSdk.delete(walletIDs: [userWalletId])
        } catch {
            AppLogger.error("Failed to delete mobile wallet after upgrade:", error: error)
        }
    }
}
