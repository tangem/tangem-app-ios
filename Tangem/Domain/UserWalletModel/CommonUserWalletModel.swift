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
    let walletImageProvider: WalletImageProviding
    let userTokensPushNotificationsManager: UserTokensPushNotificationsManager

    private let walletManagersRepository: WalletManagersRepository

    var emailConfig: EmailConfig? {
        config.emailConfig
    }

    let userWalletId: UserWalletId

    private(set) var walletInfo: WalletInfo
    var config: UserWalletConfig

    private(set) var name: String

    private let _updatePublisher: PassthroughSubject<Void, Never> = .init()
    private let _userWalletNamePublisher: CurrentValueSubject<String, Never>
    private let _cardHeaderImagePublisher: CurrentValueSubject<ImageType?, Never>

    init(
        walletInfo: WalletInfo,
        name: String,
        config: UserWalletConfig,
        userWalletId: UserWalletId,
        walletManagersRepository: WalletManagersRepository,
        walletModelsManager: WalletModelsManager,
        userTokensManager: UserTokensManager,
        userTokenListManager: UserTokenListManager,
        nftManager: NFTManager,
        keysRepository: KeysRepository,
        derivationManager: DerivationManager?,
        totalBalanceProvider: TotalBalanceProviding,
        userTokensPushNotificationsManager: UserTokensPushNotificationsManager
    ) {
        self.walletInfo = walletInfo
        self.config = config
        self.userWalletId = userWalletId
        self.name = name
        self.walletManagersRepository = walletManagersRepository
        self.walletModelsManager = walletModelsManager
        self.userTokensManager = userTokensManager
        self.userTokenListManager = userTokenListManager
        self.nftManager = nftManager
        self.keysRepository = keysRepository
        self.derivationManager = derivationManager
        self.totalBalanceProvider = totalBalanceProvider
        self.userTokensPushNotificationsManager = userTokensPushNotificationsManager
        walletImageProvider = CommonWalletImageProviderFactory().imageProvider(for: walletInfo)

        _userWalletNamePublisher = .init(name)
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

        case .mobileWallet(let hotWalletInfo):
            return true
        }
    }

    private func appendPersistentBlockchains() {
        guard let persistentBlockchains = config.persistentBlockchains else {
            return
        }

        userTokenListManager.update(.append(persistentBlockchains), shouldUpload: true)
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

    var tangemApiAuthData: TangemApiTarget.AuthData {
        walletInfo.tangemApiAuthData
    }

    var hasBackupCards: Bool {
        walletInfo.hasBackupCards
    }

    var signer: TangemSigner {
        config.tangemSigner
    }

    var cardsCount: Int {
        config.cardsCount
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
                userWalletModel: self,
                sdkFactory: config,
                onboardingStepsBuilderFactory: config
            )

            return factory.makeBackupInput(cardInfo: cardInfo)
        case .mobileWallet:
            return nil
        }
    }

    var updatePublisher: AnyPublisher<Void, Never> {
        _updatePublisher.eraseToAnyPublisher()
    }

    func updateWalletName(_ name: String) {
        self.name = name
        _userWalletNamePublisher.send(name)
        userWalletRepository.savePublicData()
    }

    /// You should create new CommonUserWalletModel from card  for backup mobile wallet
    func onBackupUpdate(type: BackupUpdateType) {
        switch walletInfo {
        case .cardWallet(let cardInfo):
            switch type {
            case .primaryCardBackuped(let card):
                var mutableCardInfo = cardInfo
                for updatedWallet in card.wallets {
                    mutableCardInfo.card.wallets[updatedWallet.publicKey]?.hasBackup = updatedWallet.hasBackup
                }

                mutableCardInfo.card.settings = CardDTO.Settings(settings: card.settings)
                mutableCardInfo.card.isAccessCodeSet = card.isAccessCodeSet
                mutableCardInfo.card.backupStatus = card.backupStatus

                walletInfo = .cardWallet(mutableCardInfo)

                config = UserWalletConfigFactory().makeConfig(cardInfo: mutableCardInfo)
                _cardHeaderImagePublisher.send(config.cardHeaderImage)
                // prevent save until onboarding completed
                if userWalletRepository.models.first(where: { $0.userWalletId == userWalletId }) != nil {
                    userWalletRepository.save(userWalletModel: self)
                }
                _updatePublisher.send()
            case .backupCompleted:
                // we have to read an actual status from backup validator
                _updatePublisher.send()
            }

            // update for ring image
            _cardHeaderImagePublisher.send(config.cardHeaderImage)
        case .mobileWallet:
            return
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

    func cleanup() {
        switch walletInfo {
        case .cardWallet(let cardInfo):
            try? visaRefreshTokenRepository.deleteToken(cardId: cardInfo.card.cardId)

            if AppSettings.shared.saveAccessCodes {
                do {
                    let accessCodeRepository = AccessCodeRepository()
                    try accessCodeRepository.deleteAccessCode(for: Array(cardInfo.associatedCardIds))
                } catch {
                    Analytics.error(error: error)
                    AppLogger.error(error: error)
                }
            }
        case .mobileWallet(let mobileWalletInfo):
            return
        }
    }
}

extension CommonUserWalletModel: MainHeaderSupplementInfoProvider {
    var walletHeaderImagePublisher: AnyPublisher<ImageType?, Never> { _cardHeaderImagePublisher.removeDuplicates().eraseToAnyPublisher() }

    var userWalletNamePublisher: AnyPublisher<String, Never> { _userWalletNamePublisher.eraseToAnyPublisher() }
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
        walletInfo.keysDerivingInteractor
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
        case .mobileWallet(let hotWalletInfo):
            let newStoredUserWallet = StoredUserWallet(
                userWalletId: userWalletId.value,
                name: name,
                walletInfo: .mobileWallet(hotWalletInfo),
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
