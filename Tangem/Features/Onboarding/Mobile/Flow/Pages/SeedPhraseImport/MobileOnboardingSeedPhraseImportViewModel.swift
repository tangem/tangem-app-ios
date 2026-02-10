//
//  MobileOnboardingSeedPhraseImportViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import UIKit
import TangemFoundation
import TangemLocalization
import TangemMobileWalletSdk
import TangemUIUtils
import TangemSdk

final class MobileOnboardingSeedPhraseImportViewModel: ObservableObject {
    @Published var isCreating: Bool = false
    @Published var alert: AlertBinder?

    lazy var importViewModel = OnboardingSeedPhraseImportViewModel(
        inputProcessor: SeedPhraseInputProcessor(),
        tangemIconProvider: CommonTangemIconProvider(hasNFCInteraction: false),
        delegate: self
    )

    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    private lazy var mobileSdk: MobileWalletSdk = CommonMobileWalletSdk()

    private let analyticsContextParams: Analytics.ContextParams = .custom(.mobileWallet)

    private weak var delegate: MobileOnboardingSeedPhraseImportDelegate?

    private var bag: Set<AnyCancellable> = []

    init(delegate: MobileOnboardingSeedPhraseImportDelegate) {
        self.delegate = delegate
        bind()
    }
}

// MARK: - Internal methods

extension MobileOnboardingSeedPhraseImportViewModel {
    func onAppear() {
        logScreenOpenedAnalytics()
    }
}

// MARK: - Private methods

private extension MobileOnboardingSeedPhraseImportViewModel {
    func bind() {
        NotificationCenter.default.publisher(for: UIApplication.userDidTakeScreenshotNotification)
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { viewModel, _ in
                viewModel.alert = AlertBuilder.makeOkGotItAlert(message: Localization.onboardingSeedScreenshotAlert)
                viewModel.logScreenCaptureAnalytics()
            }
            .store(in: &bag)
    }
}

// MARK: - SeedPhraseImportDelegate

extension MobileOnboardingSeedPhraseImportViewModel: SeedPhraseImportDelegate {
    func importSeedPhrase(mnemonic: Mnemonic, passphrase: String) {
        isCreating = true
        logImportTapAnalytics()

        runTask(in: self) { viewModel in
            do {
                let initializer = MobileWalletInitializer()

                let walletInfo = try await initializer.initializeWallet(mnemonic: mnemonic, passphrase: passphrase)

                let userWalletConfig = MobileUserWalletConfig(mobileWalletInfo: walletInfo)
                let userWalletId = UserWalletId(config: userWalletConfig)

                guard !viewModel.userWalletRepository.models.contains(where: { $0.userWalletId == userWalletId }) else {
                    throw UserWalletRepositoryError.duplicateWalletAdded
                }

                if let userWalletId {
                    Task.detached {
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

                guard let userWalletModel = CommonUserWalletModelFactory().makeModel(
                    walletInfo: .mobileWallet(walletInfo),
                    keys: .mobileWallet(keys: walletInfo.keys),
                ) else {
                    throw UserWalletRepositoryError.cantUnlockWallet
                }

                AmplitudeWrapper.shared.setUserIdIfOnboarding(userWalletId: userWalletModel.userWalletId)

                viewModel.logWalletImportedAnalytics(
                    seedLength: mnemonic.mnemonicComponents.count,
                    isPassphraseEmpty: passphrase.isEmpty
                )

                try viewModel.userWalletRepository.add(userWalletModel: userWalletModel)

                await runOnMain {
                    viewModel.isCreating = false
                    viewModel.logOnboardingFinishedAnalytics()
                    viewModel.delegate?.didImportSeedPhrase(userWalletModel: userWalletModel)
                }
            } catch {
                AppLogger.error("Failed to create wallet", error: error)
                await runOnMain {
                    viewModel.isCreating = false
                    viewModel.alert = error.alertBinder
                }
            }
        }
    }
}

// MARK: - Analytics

private extension MobileOnboardingSeedPhraseImportViewModel {
    func logScreenOpenedAnalytics() {
        Analytics.log(.onboardingSeedImportScreenOpened, contextParams: analyticsContextParams)
    }

    func logImportTapAnalytics() {
        Analytics.log(.onboardingSeedButtonImport, contextParams: analyticsContextParams)
    }

    func logWalletImportedAnalytics(seedLength: Int, isPassphraseEmpty: Bool) {
        var params: [Analytics.ParameterKey: String] = [
            .creationType: Analytics.ParameterValue.walletCreationTypeSeedImport.rawValue,
            .seedLength: "\(seedLength)",
            .passphrase: isPassphraseEmpty
                ? Analytics.ParameterValue.empty.rawValue
                : Analytics.ParameterValue.full.rawValue,
            .source: Analytics.ParameterValue.importWallet.rawValue,
        ]

        params.enrich(with: ReferralAnalyticsHelper().getReferralParams())

        Analytics.log(
            event: .walletCreatedSuccessfully,
            params: params,
            analyticsSystems: .all,
            contextParams: analyticsContextParams
        )
    }

    func logOnboardingFinishedAnalytics() {
        Analytics.log(
            .onboardingFinished,
            params: [.source: .importWallet],
            contextParams: analyticsContextParams
        )
    }

    func logScreenCaptureAnalytics() {
        Analytics.log(.onboardingSeedScreenCapture, contextParams: analyticsContextParams)
    }
}
