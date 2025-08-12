//
//  HotOnboardingCreateWalletViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemAssets
import TangemLocalization
import TangemHotSdk
import TangemFoundation

final class HotOnboardingCreateWalletViewModel: ObservableObject {
    @Published var isCreating: Bool = false

    let title = Localization.hwCreateTitle
    let createButtonTitle = Localization.onboardingCreateWalletButtonCreateWallet

    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    lazy var infoItems: [InfoItem] = makeInfoItems()

    private weak var delegate: HotOnboardingCreateWalletDelegate?

    init(delegate: HotOnboardingCreateWalletDelegate) {
        self.delegate = delegate
    }
}

// MARK: - Internal methods

extension HotOnboardingCreateWalletViewModel {
    func onCreateTap() {
        isCreating = true

        runTask(in: self) { viewModel in
            do {
                let initializer = MobileWalletInitializer()

                let walletInfo = try await initializer.initializeWallet(mnemonic: nil, passphrase: nil)

                guard let newUserWalletModel = CommonUserWalletModelFactory().makeModel(
                    walletInfo: .mobileWallet(walletInfo),
                    keys: .mobileWallet(keys: walletInfo.keys),
                ) else {
                    throw UserWalletRepositoryError.cantUnlockWallet
                }

                try viewModel.userWalletRepository.add(userWalletModel: newUserWalletModel)

                await runOnMain {
                    viewModel.isCreating = false
                    viewModel.handleWalletCreated(newUserWalletModel)
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

// MARK: - Private methods

private extension HotOnboardingCreateWalletViewModel {
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

    func handleWalletCreated(_ newUserWalletModel: UserWalletModel) {
        delegate?.onCreateWallet(userWalletModel: newUserWalletModel)
    }
}

// MARK: - Types

extension HotOnboardingCreateWalletViewModel {
    struct InfoItem: Identifiable {
        let id: UUID = .init()
        let icon: ImageType
        let title: String
        let subtitle: String
    }
}
