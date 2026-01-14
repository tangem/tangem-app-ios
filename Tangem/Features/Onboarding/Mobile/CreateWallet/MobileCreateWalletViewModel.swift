//
//  MobileCreateWalletViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemAssets
import TangemLocalization
import TangemMobileWalletSdk
import TangemFoundation
import struct TangemUIUtils.AlertBinder

final class MobileCreateWalletViewModel: ObservableObject {
    @Published var isCreating: Bool = false
    @Published var alert: AlertBinder?

    let title = Localization.hwCreateTitle
    let createButtonTitle = Localization.onboardingCreateWalletButtonCreateWallet
    let importButtonTitle = Localization.hwImportExistingWallet

    let navBarHeight: CGFloat = OnboardingLayoutConstants.navbarSize.height

    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    private let mobileWalletFeatureProvider = MobileWalletFeatureProvider()

    lazy var infoItems: [InfoItem] = makeInfoItems()

    private let analyticsContextParams: Analytics.ContextParams = .custom(.mobileWallet)

    private var isAppeared = false

    private let source: MobileCreateWalletSource
    private weak var coordinator: MobileCreateWalletRoutable?
    private weak var delegate: MobileCreateWalletDelegate?

    init(
        source: MobileCreateWalletSource,
        coordinator: MobileCreateWalletRoutable,
        delegate: MobileCreateWalletDelegate
    ) {
        self.source = source
        self.coordinator = coordinator
        self.delegate = delegate
    }
}

// MARK: - Internal methods

extension MobileCreateWalletViewModel {
    func onFirstAppear() {
        guard !isAppeared else { return }
        isAppeared = true
        logScreenOpenedAnalytics()
        logOnboardingStartedAnalytics()
    }

    func onBackTap() {
        runTask(in: self) { viewModel in
            await viewModel.close()
        }
    }

    func onCreateTap() {
        guard mobileWalletFeatureProvider.isAvailable else {
            alert = mobileWalletFeatureProvider.makeRestrictionAlert()
            return
        }

        isCreating = true
        logCreateWalletTapAnalytics()

        runTask(in: self) { viewModel in
            do {
                let initializer = MobileWalletInitializer()

                let walletInfo = try await initializer.initializeWallet(mnemonic: nil, passphrase: nil)

                Task.detached {
                    let userWalletConfig = MobileUserWalletConfig(mobileWalletInfo: walletInfo)
                    if let userWalletId = UserWalletId(config: userWalletConfig) {
                        let remoteIdentifierBuilder = CryptoAccountsRemoteIdentifierBuilder(userWalletId: userWalletId)
                        let mapper = CryptoAccountsNetworkMapper(
                            supportedBlockchains: userWalletConfig.supportedBlockchains,
                            remoteIdentifierBuilder: remoteIdentifierBuilder.build(from:)
                        )
                        let walletsNetworkService = CommonWalletsNetworkService(userWalletId: userWalletId)
                        let networkService = CommonCryptoAccountsNetworkService(
                            userWalletId: userWalletId,
                            mapper: mapper,
                            walletsNetworkService: walletsNetworkService
                        )
                        let walletCreationHelper = WalletCreationHelper(
                            userWalletId: userWalletId,
                            userWalletName: nil,
                            userWalletConfig: userWalletConfig,
                            networkService: networkService
                        )

                        try? await walletCreationHelper.createWallet()
                    }
                }

                guard let newUserWalletModel = CommonUserWalletModelFactory().makeModel(
                    walletInfo: .mobileWallet(walletInfo),
                    keys: .mobileWallet(keys: walletInfo.keys),
                ) else {
                    throw UserWalletRepositoryError.cantUnlockWallet
                }

                try viewModel.userWalletRepository.add(userWalletModel: newUserWalletModel)

                await runOnMain {
                    viewModel.isCreating = false
                    viewModel.logWalletCreatedAnalytics()
                    viewModel.logOnboardingFinishedAnalytics()
                    viewModel.delegate?.onCreateWallet(userWalletModel: newUserWalletModel)
                }
            } catch {
                AppLogger.error("Failed to create wallet", error: error)
                await runOnMain {
                    viewModel.isCreating = false
                }
            }
        }
    }

    func onImportTap() {
        logImportWalletTapAnalytics()
        guard mobileWalletFeatureProvider.isAvailable else {
            alert = mobileWalletFeatureProvider.makeRestrictionAlert()
            return
        }
        runTask(in: self) { viewModel in
            await viewModel.openImportWallet()
        }
    }
}

// MARK: - Navigation

@MainActor
private extension MobileCreateWalletViewModel {
    func openImportWallet() {
        let source = MobileOnboardingFlowSource.importWallet
        let input = MobileOnboardingInput(
            flow: .walletImport(source: source),
            shouldLogOnboardingStartedAnalytics: false
        )
        let options = OnboardingCoordinator.Options.mobileInput(input)
        coordinator?.openOnboarding(options: options)
    }

    func close() {
        coordinator?.closeMobileCreateWallet()
    }
}

// MARK: - Private methods

private extension MobileCreateWalletViewModel {
    func makeInfoItems() -> [InfoItem] {
        [
            InfoItem(
                icon: Assets.cog24,
                title: Localization.hwCreateKeysTitle,
                subtitle: Localization.hwCreateKeysDescription
            ),
            InfoItem(
                icon: Assets.lock24,
                title: Localization.hwCreateSeedTitle,
                subtitle: Localization.hwCreateSeedDescription
            ),
        ]
    }
}

// MARK: - Analytics

private extension MobileCreateWalletViewModel {
    func logScreenOpenedAnalytics() {
        let params: [Analytics.ParameterKey: String] = [
            .source: source.analyticsParameterValue.rawValue,
        ]

        Analytics.log(
            event: .onboardingCreateMobileScreenOpened,
            params: params,
            contextParams: analyticsContextParams
        )

        Analytics.log(
            event: .afWalletEntryScreen,
            params: params,
            analyticsSystems: [.appsFlyer],
            contextParams: analyticsContextParams
        )
    }

    func logOnboardingStartedAnalytics() {
        Analytics.log(
            .onboardingStarted,
            params: [.source: source.analyticsParameterValue],
            contextParams: analyticsContextParams
        )
    }

    func logCreateWalletTapAnalytics() {
        Analytics.log(.buttonCreateWallet, contextParams: analyticsContextParams)
    }

    func logWalletCreatedAnalytics() {
        let params: [Analytics.ParameterKey: String] = [
            .creationType: Analytics.ParameterValue.walletCreationTypeNewSeed.rawValue,
            .seedLength: Constants.seedPhraseLength,
            .passphrase: Analytics.ParameterValue.empty.rawValue,
            .source: source.analyticsParameterValue.rawValue,
        ]

        Analytics.log(
            event: .walletCreatedSuccessfully,
            params: params,
            contextParams: analyticsContextParams
        )

        Analytics.log(
            event: .afWalletCreatedSuccessfully,
            params: params,
            analyticsSystems: [.appsFlyer],
            contextParams: analyticsContextParams
        )
    }

    func logOnboardingFinishedAnalytics() {
        Analytics.log(
            .onboardingFinished,
            params: [.source: source.analyticsParameterValue],
            contextParams: analyticsContextParams
        )
    }

    func logImportWalletTapAnalytics() {
        Analytics.log(.onboardingSeedButtonImportWallet, contextParams: analyticsContextParams)
    }
}

// MARK: - Types

extension MobileCreateWalletViewModel {
    struct InfoItem: Identifiable {
        let id: UUID = .init()
        let icon: ImageType
        let title: String
        let subtitle: String
    }
}

extension MobileCreateWalletViewModel {
    enum Constants {
        static let seedPhraseLength = "12"
    }
}
