//
//  HotOnboardingSeedPhraseImportViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import TangemFoundation
import TangemHotSdk
import struct TangemSdk.Mnemonic

final class HotOnboardingSeedPhraseImportViewModel: ObservableObject {
    @Published var isCreating: Bool = false

    lazy var importViewModel = OnboardingSeedPhraseImportViewModel(
        inputProcessor: SeedPhraseInputProcessor(),
        delegate: self
    )

    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    private weak var delegate: HotOnboardingSeedPhraseImportDelegate?

    init(delegate: HotOnboardingSeedPhraseImportDelegate) {
        self.delegate = delegate
    }
}

// MARK: - SeedPhraseImportDelegate

extension HotOnboardingSeedPhraseImportViewModel: SeedPhraseImportDelegate {
    func importSeedPhrase(mnemonic: Mnemonic, passphrase: String) {
        isCreating = true

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
