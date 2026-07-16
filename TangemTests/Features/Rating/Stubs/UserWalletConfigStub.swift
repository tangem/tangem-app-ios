//
//  UserWalletConfigStub.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BlockchainSdk
import Combine
import Foundation
import TangemAssets
import TangemSdk
import TangemUI
@testable import Tangem

struct UserWalletConfigStub: UserWalletConfig {
    let cardsCount: Int = 1
    let cardSetLabel: String = "Test"
    let defaultName: String = "Test"
    let existingCurves: [EllipticCurve] = []
    let createWalletCurves: [EllipticCurve] = []
    let tangemSigner: TangemSigner = TangemSignerStub()
    let generalNotificationEvents: [GeneralNotificationEvent] = []
    let isWalletsCreated: Bool = true
    let supportedBlockchains: Set<Blockchain> = []
    let defaultBlockchains: [TokenItem] = []
    let persistentBlockchains: [TokenItem] = []
    let embeddedBlockchain: TokenItem? = nil
    let emailData: [EmailCollectedData] = []
    let userWalletIdSeed: Data? = nil
    let productType: Analytics.ProductType = .wallet
    let cardHeaderImage: ImageType? = nil
    let walletThumbnailType: ThumbnailWalletViewType? = nil
    let cardSessionFilter: SessionFilter = .cardId("test")
    var contextBuilder: WalletCreationContextBuilder { fatalError("Not implemented for stub") }

    func getFeatureAvailability(_ feature: UserWalletFeature) -> UserWalletFeature.Availability { .available }
    func makeAnyWalletManagerFactory() -> AnyWalletManagerFactory { AnyWalletManagerFactoryStub() }
    func makeOnboardingStepsBuilder(backupService: BackupService) -> any OnboardingStepsBuilder { OnboardingStepsBuilderStub() }
    func makeBackupService() -> BackupService { GenericBackupServiceFactory(isAccessCodeSet: false).makeBackupService() }
    func makeTangemSdk() -> TangemSdk { GenericTangemSdkFactory(isAccessCodeSet: false).makeTangemSdk() }
    func makeMainHeaderProviderFactory() -> MainHeaderProviderFactory { MainHeaderProviderFactoryStub() }
    func makeActionButtonsRole() -> ActionButtonsWalletRole { ActionButtonsWalletRole(providesHotCryptoTokens: false, forcesActionButtonsRow: false, preselectsUserWalletInBuy: false) }
}

// MARK: - TangemSigner

final class TangemSignerStub: TangemSigner {
    let hasNFCInteraction: Bool = false
    let latestSignerType: TangemSignerType? = nil

    func sign(hashes: [Data], walletPublicKey: Wallet.PublicKey) -> AnyPublisher<[SignatureInfo], any Error> {
        Fail(error: NSError(domain: "stub", code: 0)).eraseToAnyPublisher()
    }

    func sign(hash: Data, walletPublicKey: Wallet.PublicKey) -> AnyPublisher<SignatureInfo, any Error> {
        Fail(error: NSError(domain: "stub", code: 0)).eraseToAnyPublisher()
    }

    func sign(dataToSign: [SignData], walletPublicKey: Wallet.PublicKey) -> AnyPublisher<[SignatureInfo], any Error> {
        Fail(error: NSError(domain: "stub", code: 0)).eraseToAnyPublisher()
    }
}

// MARK: - EmailDataProvider

final class EmailDataProviderStub: EmailDataProvider {
    let emailData: [EmailCollectedData] = []
    let emailConfig: EmailConfig? = nil
}

// MARK: - AnyWalletManagerFactory

struct AnyWalletManagerFactoryStub: AnyWalletManagerFactory {
    func makeWalletManager(blockchainNetwork: BlockchainNetwork, tokens: [Token], keys: [KeyInfo], apiList: APIList) throws -> WalletManager {
        throw AnyWalletManagerFactoryError.noDerivation
    }
}

// MARK: - OnboardingStepsBuilder

struct OnboardingStepsBuilderStub: OnboardingStepsBuilder {
    func buildOnboardingSteps() -> OnboardingSteps { .singleWallet([]) }
    func buildBackupSteps() -> OnboardingSteps? { nil }
}

// MARK: - MainHeaderProviderFactory

struct MainHeaderProviderFactoryStub: MainHeaderProviderFactory {
    func makeHeaderBalanceProvider(for model: UserWalletModel) -> MainHeaderBalanceProvider {
        MainHeaderBalanceProviderStub()
    }

    func makeHeaderSubtitleProvider(for userWalletModel: UserWalletModel, isMultiWallet: Bool) -> MainHeaderSubtitleProvider {
        MainHeaderSubtitleProviderStub()
    }
}

struct MainHeaderBalanceProviderStub: MainHeaderBalanceProvider {
    var balance: LoadableBalanceView.State { .loaded(text: "") }

    var balancePublisher: AnyPublisher<LoadableBalanceView.State, Never> {
        Just(.loaded(text: "")).eraseToAnyPublisher()
    }
}

struct MainHeaderSubtitleProviderStub: MainHeaderSubtitleProvider {
    var isLoadingPublisher: AnyPublisher<Bool, Never> {
        Just(false).eraseToAnyPublisher()
    }

    var subtitlePublisher: AnyPublisher<MainHeaderSubtitleInfo, Never> {
        Just(.init(messages: [], formattingOption: .default)).eraseToAnyPublisher()
    }

    var containsSensitiveInfo: Bool { false }
}
