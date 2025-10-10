//
//  MobileBackupTypesViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation
import TangemLocalization
import TangemUIUtils
import TangemMobileWalletSdk
import class TangemSdk.BiometricsUtil

final class MobileBackupTypesViewModel: ObservableObject {
    @Published var sections: [Section] = []
    @Published var alert: AlertBinder?

    let navTitle = Localization.commonBackup

    private var isBackupNeeded: Bool {
        userWalletModel.config.hasFeature(.mnemonicBackup)
    }

    private lazy var mobileWalletSdk: MobileWalletSdk = CommonMobileWalletSdk()

    private let userWalletModel: UserWalletModel
    private weak var routable: MobileBackupTypesRoutable?

    private var bag: Set<AnyCancellable> = []

    init(userWalletModel: UserWalletModel, routable: MobileBackupTypesRoutable) {
        self.userWalletModel = userWalletModel
        self.routable = routable
        setup()
        bind()
    }
}

// MARK: - Private methods

private extension MobileBackupTypesViewModel {
    func setup() {
        sections = makeSections()
    }

    func bind() {
        userWalletModel.updatePublisher
            .withWeakCaptureOf(self)
            .sink { viewModel, result in
                viewModel.handleUpdate(result: result)
            }
            .store(in: &bag)
    }

    func handleUpdate(result: UpdateResult) {
        switch result {
        case .configurationChanged:
            setup()
        case .nameDidChange, .tangemPayOfferAccepted:
            break
        }
    }
}

// MARK: - Helpers

private extension MobileBackupTypesViewModel {
    func makeSections() -> [Section] {
        let commonSection = Section(title: nil, items: makeCommonItems())
        let recommendedSection = Section(title: Localization.expressProviderRecommended, items: makeRecommendedItems())
        return [commonSection, recommendedSection]
    }

    func makeCommonItems() -> [Item] {
        [makeSeedPhraseItem(), makeICloudItem()]
    }

    func makeRecommendedItems() -> [Item] {
        [makeHardwareItem()]
    }

    func makeSeedPhraseItem() -> Item {
        let badge: BadgeView.Item = if isBackupNeeded {
            .noBackup
        } else {
            .done
        }

        let action = weakify(self, forFunction: MobileBackupTypesViewModel.onSeedPhraseBackupTap)

        return Item(
            title: Localization.hwBackupSeedTitle,
            description: Localization.hwBackupSeedDescription,
            badge: badge,
            isEnabled: true,
            action: action
        )
    }

    func makeHardwareItem() -> Item {
        let action = weakify(self, forFunction: MobileBackupTypesViewModel.onHardwareBackupTap)
        return Item(
            title: Localization.hwBackupHardwareTitle,
            description: Localization.hwBackupHardwareDescription,
            badge: nil,
            isEnabled: true,
            action: action
        )
    }

    func makeICloudItem() -> Item {
        let badge = BadgeView.Item(title: Localization.commonComingSoon, style: .secondary)
        return Item(
            title: Localization.hwBackupIcloudTitle,
            description: Localization.hwBackupIcloudDescription,
            badge: badge,
            isEnabled: false,
            action: {}
        )
    }

    func onSeedPhraseBackupTap() {
        if isBackupNeeded {
            openSeedPhraseBackup()
        } else {
            runTask(in: self) { viewModel in
                do {
                    let context = try await viewModel.unlock()
                    await viewModel.openSeedPhraseReveal(context: context)
                } catch where error.isCancellationError {
                    AppLogger.error("Unlock is canceled", error: error)
                } catch {
                    AppLogger.error("Unlock failed:", error: error)
                    await runOnMain {
                        viewModel.alert = error.alertBinder
                    }
                }
            }
        }
    }

    func onHardwareBackupTap() {
        runTask(in: self) { viewModel in
            do {
                let context = try await viewModel.unlock()
                await viewModel.openUpgrade(context: context)
            } catch where error.isCancellationError {
                AppLogger.error("Unlock is canceled", error: error)
            } catch {
                AppLogger.error("Unlock failed:", error: error)
                await runOnMain {
                    viewModel.alert = error.alertBinder
                }
            }
        }
    }
}

// MARK: - Unlocking

private extension MobileBackupTypesViewModel {
    func unlock() async throws -> MobileWalletContext {
        let authUtil = MobileAuthUtil(
            userWalletId: userWalletModel.userWalletId,
            config: userWalletModel.config,
            biometricsProvider: CommonUserWalletBiometricsProvider()
        )
        let result = try await authUtil.unlock()

        switch result {
        case .successful(let context):
            return context

        case .canceled:
            throw CancellationError()

        case .userWalletNeedsToDelete:
            assertionFailure("Unexpected state: .userWalletNeedsToDelete should never happen.")
            throw CancellationError()
        }
    }
}

// MARK: - Navigation

private extension MobileBackupTypesViewModel {
    func openSeedPhraseBackup() {
        let input = MobileOnboardingInput(flow: .seedPhraseBackup(userWalletModel: userWalletModel))
        routable?.openMobileOnboarding(input: input)
    }

    @MainActor
    func openSeedPhraseReveal(context: MobileWalletContext) {
        let input = MobileOnboardingInput(flow: .seedPhraseReveal(context: context))
        routable?.openMobileOnboarding(input: input)
    }

    @MainActor
    func openUpgrade(context: MobileWalletContext) {
        routable?.openMobileUpgrade(userWalletModel: userWalletModel, context: context)
    }
}

// MARK: - Types

extension MobileBackupTypesViewModel {
    struct Section: Identifiable {
        let id = UUID()
        let title: String?
        let items: [Item]
    }

    struct Item: Identifiable {
        let id = UUID()
        let title: String
        let description: String
        let badge: BadgeView.Item?
        let isEnabled: Bool
        let action: () -> Void
    }
}
