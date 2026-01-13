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
    let nftManager: NFTManager
    let keysRepository: KeysRepository
    let totalBalanceProvider: TotalBalanceProvider
    let tangemPayAccountProvider: TangemPayAccountProviderSetupable

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
        nftManager: NFTManager,
        keysRepository: KeysRepository,
        totalBalanceProvider: TotalBalanceProvider,
        tangemPayAccountProvider: TangemPayAccountProviderSetupable,
        userTokensPushNotificationsManager: UserTokensPushNotificationsManager,
        accountModelsManager: AccountModelsManager
    ) {
        self.walletInfo = walletInfo
        self.config = config
        self.userWalletId = userWalletId
        self.name = name
        self.walletModelsManager = walletModelsManager
        self.userTokensManager = userTokensManager
        self.nftManager = nftManager
        self.keysRepository = keysRepository
        self.totalBalanceProvider = totalBalanceProvider
        self.tangemPayAccountProvider = tangemPayAccountProvider
        self.userTokensPushNotificationsManager = userTokensPushNotificationsManager
        self.accountModelsManager = accountModelsManager

        _cardHeaderImagePublisher = .init(config.cardHeaderImage)
    }

    deinit {
        AppLogger.debug(self)
    }

    private func updateConfiguration(walletInfo: WalletInfo, shouldSave: Bool = true) {
        self.walletInfo = walletInfo
        config = UserWalletConfigFactory().makeConfig(walletInfo: walletInfo)
        if shouldSave {
            userWalletRepository.save(userWalletModel: self)
            keysRepository.update(keys: walletInfo.keys)
        }
        _updatePublisher.send(.configurationChanged(model: self))
        if FeatureProvider.isAvailable(.visa) {
            tangemPayAccountProvider.setup(for: self)
        }
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

    var wcAccountsWalletModelProvider: WalletConnectAccountsWalletModelProvider {
        CommonWalletConnectAccountsWalletModelProvider(accountModelsManager: accountModelsManager)
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

        case .backupCompleted(let card, let associatedCardIds):
            var mutableCardInfo = CardInfo(
                card: CardDTO(card: card),
                walletData: .none,
                associatedCardIds: associatedCardIds
            )

            switch walletInfo {
            case .cardWallet(let existingInfo):
                for wallet in mutableCardInfo.card.wallets {
                    if let existingDerivedKeys = existingInfo.card.wallets[wallet.publicKey]?.derivedKeys {
                        mutableCardInfo.card.wallets[wallet.publicKey]?.derivedKeys = existingDerivedKeys
                    }
                }

                // prevent save until onboarding completed
                let shouldSave = userWalletRepository.models[userWalletId] != nil
                updateConfiguration(walletInfo: .cardWallet(mutableCardInfo), shouldSave: shouldSave)
                _cardHeaderImagePublisher.send(config.cardHeaderImage)

            case .mobileWallet(let existingInfo):
                for wallet in mutableCardInfo.card.wallets {
                    if let existingDerivedKeys = existingInfo.keys[wallet.publicKey]?.derivedKeys {
                        mutableCardInfo.card.wallets[wallet.publicKey]?.derivedKeys = existingDerivedKeys
                    }
                }

                _walletImageProvider = nil
                updateConfiguration(walletInfo: WalletInfo.cardWallet(mutableCardInfo))
                _cardHeaderImagePublisher.send(config.cardHeaderImage)
                cleanMobileWallet()
                syncRemoteAfterUpgrade()
            }

        case .accessCodeDidSet:
            switch walletInfo {
            case .cardWallet:
                break
            case .mobileWallet(let info):
                var mutableInfo = info
                mutableInfo.accessCodeStatus = .set
                updateConfiguration(walletInfo: .mobileWallet(mutableInfo))
            }

        case .accessCodeDidSkip:
            switch walletInfo {
            case .cardWallet:
                break
            case .mobileWallet(let info):
                var mutableInfo = info
                mutableInfo.accessCodeStatus = .skipped
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

        case .tangemPayKYCDeclined:
            _updatePublisher.send(.tangemPayKYCDeclined)
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
            return BackupValidator().validate(card: cardInfo.card)
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

extension CommonUserWalletModel: TangemPayAuthorizingProvider {
    var tangemPayAuthorizingInteractor: TangemPayAuthorizing {
        switch walletInfo {
        case .cardWallet(let cardInfo):
            return TangemPayAuthorizingCardInteractor(with: cardInfo)
        case .mobileWallet:
            return TangemPayAuthorizingMobileWalletInteractor(
                userWalletId: userWalletId,
                userWalletConfig: config
            )
        }
    }
}

// MARK: - TangemPayAccountProvider

extension CommonUserWalletModel: TangemPayAccountProvider {
    var tangemPayAccount: TangemPayAccount? {
        tangemPayAccountProvider.tangemPayAccount
    }

    var tangemPayAccountPublisher: AnyPublisher<TangemPayAccount?, Never> {
        tangemPayAccountProvider.tangemPayAccountPublisher
    }
}

// MARK: - TotalBalanceProvider

extension CommonUserWalletModel: TotalBalanceProvider {
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
            var mutableMobileWalletInfo = mobileWalletInfo
            mutableMobileWalletInfo.keys = []

            let newStoredUserWallet = StoredUserWallet(
                userWalletId: userWalletId.value,
                name: name,
                walletInfo: .mobileWallet(mutableMobileWalletInfo),
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
