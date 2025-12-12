//
//  MobileOnboardingSeedPhraseImportViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import TangemFoundation
import TangemMobileWalletSdk
import TangemUIUtils
import TangemSdk

final class MobileOnboardingSeedPhraseImportViewModel: ObservableObject {
    @Published var isCreating: Bool = false
    @Published var alert: AlertBinder?

    lazy var importViewModel = OnboardingSeedPhraseImportViewModel(
        inputProcessor: SeedPhraseInputProcessor(),
        delegate: self
    )

    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    private lazy var mobileSdk: MobileWalletSdk = CommonMobileWalletSdk()

    private let analyticsContextParams: Analytics.ContextParams = .custom(.mobileWallet)

    private weak var delegate: MobileOnboardingSeedPhraseImportDelegate?

    init(delegate: MobileOnboardingSeedPhraseImportDelegate) {
        self.delegate = delegate
    }
}

// MARK: - Internal methods

extension MobileOnboardingSeedPhraseImportViewModel {
    func onAppear() {
        logScreenOpenedAnalytics()
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
                    let walletCreationHelper = WalletCreationHelper(
                        userWalletId: userWalletId,
                        userWalletName: nil,
                        userWalletConfig: userWalletConfig
                    )

                    try? await walletCreationHelper.createWallet()
                }

                guard let userWalletModel = CommonUserWalletModelFactory().makeModel(
                    walletInfo: .mobileWallet(walletInfo),
                    keys: .mobileWallet(keys: walletInfo.keys),
                ) else {
                    throw UserWalletRepositoryError.cantUnlockWallet
                }

                try viewModel.userWalletRepository.add(userWalletModel: userWalletModel)

                await runOnMain {
                    viewModel.isCreating = false
                    viewModel.logWalletImportedAnalytics(
                        seedLength: mnemonic.mnemonicComponents.count,
                        isPassphraseEmpty: passphrase.isEmpty
                    )
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
        let params: [Analytics.ParameterKey: String] = [
            .creationType: Analytics.ParameterValue.walletCreationTypeSeedImport.rawValue,
            .seedLength: "\(seedLength)",
            .passphrase: isPassphraseEmpty
                ? Analytics.ParameterValue.empty.rawValue
                : Analytics.ParameterValue.full.rawValue,
            .source: Analytics.ParameterValue.importWallet.rawValue,
        ]

        Analytics.log(
            event: .walletCreatedSuccessfully,
            params: params,
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
}
