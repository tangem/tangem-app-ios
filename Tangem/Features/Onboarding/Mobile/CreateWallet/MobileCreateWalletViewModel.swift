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
import TangemSdk

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

                let userWalletConfig = MobileUserWalletConfig(mobileWalletInfo: walletInfo)
                if let userWalletId = UserWalletId(config: userWalletConfig) {
                    let walletCreationHelper = WalletCreationHelper(
                        userWalletId: userWalletId,
                        userWalletName: nil,
                        userWalletConfig: userWalletConfig
                    )

                    try? await walletCreationHelper.createWallet()
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

        #if DEBUG
        if shouldAutoImportSeed() {
            runTask(in: self) { viewModel in
                await viewModel.importWalletWithAutoSeed()
            }
            return
        }
        #endif

        runTask(in: self) { viewModel in
            await viewModel.openImportWallet()
        }
    }
}

// MARK: - UI Test Support

#if DEBUG
private extension MobileCreateWalletViewModel {
    /// Default seed phrase used for UI tests when no custom seed is provided.
    static let defaultUITestSeedPhrase = "tiny escape drive pupil flavor endless love walk gadget match filter luxury"

    func shouldAutoImportSeed() -> Bool {
        AppEnvironment.current.isUITest &&
            ProcessInfo.processInfo.arguments.contains("-uitest-auto-import-seed")
    }

    /// Imports wallet with predefined seed phrase for UI tests.
    /// Skips all intermediate screens and goes directly to main screen.
    func importWalletWithAutoSeed() async {
        await runOnMain {
            isCreating = true
        }

        do {
            let seed = ProcessInfo.processInfo.environment["UITEST_SEED"]
                ?? Self.defaultUITestSeedPhrase

            let mnemonic = try Mnemonic(with: seed)
            let initializer = MobileWalletInitializer()

            let walletInfo = try await initializer.initializeWallet(mnemonic: mnemonic, passphrase: "")

            let userWalletConfig = MobileUserWalletConfig(mobileWalletInfo: walletInfo)
            let userWalletId = UserWalletId(config: userWalletConfig)

            guard !userWalletRepository.models.contains(where: { $0.userWalletId == userWalletId }) else {
                throw UserWalletRepositoryError.duplicateWalletAdded
            }

            if let userWalletId {
                let walletCreationHelper = WalletCreationHelper(
                    userWalletId: userWalletId,
                    userWalletName: nil,
                    userWalletConfig: userWalletConfig
                )

                try? await walletCreationHelper.createWallet()
            }

            guard let userWalletModel = CommonUserWalletModelFactory().makeModel(
                walletInfo: .mobileWallet(walletInfo),
                keys: .mobileWallet(keys: walletInfo.keys)
            ) else {
                throw UserWalletRepositoryError.cantUnlockWallet
            }

            // Skip access code for UI tests
            userWalletModel.update(type: .accessCodeDidSkip)

            try userWalletRepository.add(userWalletModel: userWalletModel)

            await runOnMain {
                isCreating = false
                logWalletCreatedAnalytics()
                logOnboardingFinishedAnalytics()
                delegate?.onCreateWallet(userWalletModel: userWalletModel)
            }
        } catch {
            AppLogger.error("Failed to import wallet with auto seed", error: error)

            await runOnMain {
                isCreating = false
                alert = error.alertBinder
            }
        }
    }
}
#endif

// MARK: - Navigation

@MainActor
private extension MobileCreateWalletViewModel {
    func openImportWallet() {
        let source = MobileOnboardingFlowSource.importWallet
        let input = MobileOnboardingInput(flow: .walletImport(source: source))
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
