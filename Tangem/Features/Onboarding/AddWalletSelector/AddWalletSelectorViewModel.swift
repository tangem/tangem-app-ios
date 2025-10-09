//
//  AddWalletSelectorViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI
import TangemLocalization
import TangemAssets

final class AddWalletSelectorViewModel: ObservableObject {
    @Published var isBuyAvailable = false

    let navigationBarHeight = OnboardingLayoutConstants.navbarSize.height
    let screenTitle = "Choose how to add your wallet"
    let supportButtonTitle = "What to choose?"

    lazy var walletItems: [WalletItem] = makeWalletItems()
    lazy var buyItem: BuyItem = makeBuyItem()

    @Injected(\.safariManager) private var safariManager: SafariManager

    private weak var coordinator: AddWalletSelectorRoutable?

    init(coordinator: AddWalletSelectorRoutable) {
        self.coordinator = coordinator
    }
}

// MARK: - Internal methods

extension AddWalletSelectorViewModel {
    func onAppear() {
        scheduleBuyAvailability()
    }

    func onSupportTap() {
        openWhatToChoose()
    }
}

// MARK: - Private methods

private extension AddWalletSelectorViewModel {
    func makeWalletItems() -> [WalletItem] {
        let hardwareItem = WalletItem(
            description: WalletDescriptionItem(
                title: Localization.walletCreateHardwareTitle,
                subtitle: "Scan your Tangem card or ring to restore it or import from another wallet.",
                badge: BadgeView.Item(title: "Recommended", style: .accent)
            ),
            infos: [
                WalletInfoItem(icon: Assets.Glyphs.addData, title: "Create Hardware Wallet"),
                WalletInfoItem(icon: Assets.Glyphs.importData, title: "Import seed phrase"),
            ],
            action: weakify(self, forFunction: AddWalletSelectorViewModel.openHardwareWallet)
        )

        let mobileItem = WalletItem(
            description: WalletDescriptionItem(
                title: Localization.hwMobileWallet,
                subtitle: "Restore your wallet on your phone or import from another app — convenient, but less secure than a Tangem card.",
                badge: nil
            ),
            infos: [
                WalletInfoItem(icon: Assets.Glyphs.mobileWallet, title: Localization.hwCreateTitle),
                WalletInfoItem(icon: Assets.Glyphs.importData, title: "Import seed phrase"),
            ],
            action: weakify(self, forFunction: AddWalletSelectorViewModel.openMobileWallet)
        )

        return [hardwareItem, mobileItem]
    }

    func makeBuyItem() -> BuyItem {
        BuyItem(
            title: "Want to purchase a Tangem Wallet?",
            buttonTitle: Localization.walletImportBuyTitle,
            buttonAction: weakify(self, forFunction: AddWalletSelectorViewModel.openBuyHardwareWallet)
        )
    }

    func scheduleBuyAvailability() {
        guard !isBuyAvailable else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            self?.isBuyAvailable = true
        }
    }
}

// MARK: - Navigation

private extension AddWalletSelectorViewModel {
    func openHardwareWallet() {
        coordinator?.openAddHardwareWallet()
    }

    func openMobileWallet() {
        Analytics.log(.buttonMobileWallet)
        coordinator?.openAddMobileWallet()
    }

    func openBuyHardwareWallet() {
        Analytics.log(.onboardingButtonBuy, params: [.source: .createWallet])
        safariManager.openURL(TangemBlogUrlBuilder().url(root: .pricing))
    }

    func openWhatToChoose() {
        safariManager.openURL(TangemBlogUrlBuilder().url(post: .mobileVsHardware))
    }
}

// MARK: - Types

extension AddWalletSelectorViewModel {
    struct WalletItem: Identifiable {
        let id = UUID()
        let description: WalletDescriptionItem
        let infos: [WalletInfoItem]
        let action: () -> Void
    }

    struct BuyItem {
        let title: String
        let buttonTitle: String
        let buttonAction: () -> Void
    }

    struct WalletDescriptionItem {
        let title: String
        let subtitle: String
        let badge: BadgeView.Item?
    }

    struct WalletInfoItem: Identifiable {
        let id = UUID()
        let icon: ImageType
        let title: String
    }
}
