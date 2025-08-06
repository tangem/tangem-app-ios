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

final class HotOnboardingCreateWalletViewModel {
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    let title = Localization.hwCreateTitle
    let createButtonTitle = Localization.onboardingCreateWalletButtonCreateWallet

    lazy var infoItems: [InfoItem] = makeInfoItems()

    private weak var delegate: HotOnboardingCreateWalletDelegate?

    init(delegate: HotOnboardingCreateWalletDelegate) {
        self.delegate = delegate
    }
}

// MARK: - Internal methods

extension HotOnboardingCreateWalletViewModel {
    func onCreateTap() {
        runTask(in: self) { @MainActor viewModel in
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

                try viewModel.handleWalletCreated(newUserWalletModel)
            } catch {
                AppLogger.error("Failed to create wallet", error: error)
                throw error
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

    @MainActor
    private func handleWalletCreated(_ newUserWalletModel: UserWalletModel) throws {
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
