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

final class MobileCreateWalletViewModel: ObservableObject {
    @Published var isCreating: Bool = false

    let title = Localization.hwCreateTitle
    let createButtonTitle = Localization.onboardingCreateWalletButtonCreateWallet
    let importButtonTitle = Localization.hwImportExistingWallet

    let navBarHeight: CGFloat = OnboardingLayoutConstants.navbarSize.height

    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    lazy var infoItems: [InfoItem] = makeInfoItems()

    private weak var coordinator: MobileCreateWalletRoutable?
    private weak var delegate: MobileCreateWalletDelegate?

    init(coordinator: MobileCreateWalletRoutable, delegate: MobileCreateWalletDelegate) {
        self.coordinator = coordinator
        self.delegate = delegate
    }
}

// MARK: - Internal methods

extension MobileCreateWalletViewModel {
    func onAppear() {
        Analytics.log(.createWalletScreenOpened, contextParams: .custom(.mobileWallet))
    }

    func onBackTap() {
        runTask(in: self) { viewModel in
            await viewModel.close()
        }
    }

    func onCreateTap() {
        isCreating = true
        Analytics.log(
            event: .buttonCreateWallet,
            params: [:],
            contextParams: .custom(.mobileWallet)
        )

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

    func onImportTap() {
        runTask(in: self) { viewModel in
            await viewModel.openImportWallet()
        }
    }
}

// MARK: - Navigation

@MainActor
private extension MobileCreateWalletViewModel {
    func openImportWallet() {
        let input = MobileOnboardingInput(flow: .walletImport)
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

    func trackWalletCreated() {
        let params: [Analytics.ParameterKey: String] = [
            .creationType: Analytics.ParameterValue.walletCreationTypeNewSeed.rawValue,
            .seedLength: Constants.seedPhraseLength,
            .passphrase: Analytics.ParameterValue.empty.rawValue,
        ]

        Analytics.log(
            event: .walletCreatedSuccessfully,
            params: params,
            contextParams: .custom(.mobileWallet)
        )
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
