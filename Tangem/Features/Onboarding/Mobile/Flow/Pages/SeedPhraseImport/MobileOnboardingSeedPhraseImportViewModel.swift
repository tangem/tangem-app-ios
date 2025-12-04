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

    private weak var delegate: MobileOnboardingSeedPhraseImportDelegate?

    init(delegate: MobileOnboardingSeedPhraseImportDelegate) {
        self.delegate = delegate
    }
}

// MARK: - Internal methods

extension MobileOnboardingSeedPhraseImportViewModel {
    func onAppear() {
        Analytics.log(
            event: .onboardingSeedImportScreenOpened,
            params: [:],
            contextParams: .custom(.mobileWallet)
        )
    }
}

// MARK: - SeedPhraseImportDelegate

extension MobileOnboardingSeedPhraseImportViewModel: SeedPhraseImportDelegate {
    func importSeedPhrase(mnemonic: Mnemonic, passphrase: String) {
        isCreating = true

        Analytics.log(
            event: .onboardingSeedButtonImportWallet,
            params: [:],
            contextParams: .custom(.mobileWallet)
        )

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
                    viewModel.trackWalletImported(
                        seedLength: mnemonic.mnemonicComponents.count,
                        isPassphraseEmpty: passphrase.isEmpty
                    )
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
    func trackWalletImported(seedLength: Int, isPassphraseEmpty: Bool) {
        let params: [Analytics.ParameterKey: String] = [
            .creationType: Analytics.ParameterValue.walletCreationTypeSeedImport.rawValue,
            .seedLength: "\(seedLength)",
            .passphrase: isPassphraseEmpty
                ? Analytics.ParameterValue.empty.rawValue
                : Analytics.ParameterValue.full.rawValue,
        ]

        Analytics.log(
            event: .walletCreatedSuccessfully,
            params: params,
            contextParams: .custom(.mobileWallet)
        )
    }
}
