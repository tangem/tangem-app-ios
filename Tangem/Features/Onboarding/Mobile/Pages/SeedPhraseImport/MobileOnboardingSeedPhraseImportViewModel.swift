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
import struct TangemSdk.Mnemonic

final class MobileOnboardingSeedPhraseImportViewModel: ObservableObject {
    @Published var isCreating: Bool = false

    lazy var importViewModel = OnboardingSeedPhraseImportViewModel(
        inputProcessor: SeedPhraseInputProcessor(),
        delegate: self
    )

    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

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
            params: [.productType: Analytics.ProductType.mobileWallet.rawValue]
        )
    }
}

// MARK: - SeedPhraseImportDelegate

extension MobileOnboardingSeedPhraseImportViewModel: SeedPhraseImportDelegate {
    func importSeedPhrase(mnemonic: Mnemonic, passphrase: String) {
        isCreating = true

        Analytics.log(
            event: .onboardingSeedButtonImportWallet,
            params: [.productType: Analytics.ProductType.mobileWallet.rawValue]
        )

        runTask(in: self) { viewModel in
            do {
                let initializer = MobileWalletInitializer()

                let walletInfo = try await initializer.initializeWallet(mnemonic: mnemonic, passphrase: passphrase)

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
            params: params
        )
    }
}
