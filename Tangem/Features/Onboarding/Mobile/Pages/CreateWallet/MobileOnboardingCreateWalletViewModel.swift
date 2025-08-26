//
//  MobileOnboardingCreateWalletViewModel.swift
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

final class MobileOnboardingCreateWalletViewModel: ObservableObject {
    @Published var isCreating: Bool = false

    let title = Localization.hwCreateTitle
    let createButtonTitle = Localization.onboardingCreateWalletButtonCreateWallet

    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    lazy var infoItems: [InfoItem] = makeInfoItems()

    private weak var delegate: MobileOnboardingCreateWalletDelegate?

    init(delegate: MobileOnboardingCreateWalletDelegate) {
        self.delegate = delegate
    }
}

// MARK: - Internal methods

extension MobileOnboardingCreateWalletViewModel {
    func onAppear() {
        Analytics.log(.createWalletScreenOpened)
    }

    func onCreateTap() {
        isCreating = true
        Analytics.log(event: .buttonCreateWallet, params: [.productType: Analytics.ProductType.mobileWallet.rawValue])

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
                    viewModel.trackWalletCreated()
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
}

// MARK: - Private methods

private extension MobileOnboardingCreateWalletViewModel {
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

    func trackWalletCreated() {
        let params: [Analytics.ParameterKey: String] = [
            .creationType: Analytics.ParameterValue.walletCreationTypeNewSeed.rawValue,
            .seedLength: Constants.seedPhraseLength,
            .passphrase: Analytics.ParameterValue.empty.rawValue,
        ]

        Analytics.log(
            event: .walletCreatedSuccessfully,
            params: params
        )
    }
}

// MARK: - Types

extension MobileOnboardingCreateWalletViewModel {
    struct InfoItem: Identifiable {
        let id: UUID = .init()
        let icon: ImageType
        let title: String
        let subtitle: String
    }
}

extension MobileOnboardingCreateWalletViewModel {
    enum Constants {
        static let seedPhraseLength = "12"
    }
}
