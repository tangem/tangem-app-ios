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
import struct TangemUIUtils.AlertBinder

final class AddWalletSelectorViewModel: ObservableObject {
    @Published var isBuyAvailable = false
    @Published var alert: AlertBinder?

    let navigationBarHeight = OnboardingLayoutConstants.navbarSize.height
    let screenTitle = Localization.walletAddCommonTitle
    let supportButtonTitle = Localization.walletAddSupportTitle

    lazy var walletItems: [WalletItem] = makeWalletItems()
    lazy var buyItem: BuyItem = makeBuyItem()

    @Injected(\.safariManager) private var safariManager: SafariManager

    private let mobileWalletFeatureProvider = MobileWalletFeatureProvider()

    private var analyticsContextParams: Analytics.ContextParams { .empty }

    private let source: AddWalletSelectorSource
    private weak var coordinator: AddWalletSelectorRoutable?

    init(source: AddWalletSelectorSource, coordinator: AddWalletSelectorRoutable) {
        self.source = source
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
                subtitle: Localization.walletAddHardwareDescription,
                badge: BadgeView.Item(title: Localization.commonRecommended, style: .accent)
            ),
            action: weakify(self, forFunction: AddWalletSelectorViewModel.openHardwareWallet)
        )

        let mobileItem = WalletItem(
            description: WalletDescriptionItem(
                title: Localization.hwMobileWallet,
                subtitle: Localization.walletAddMobileDescription,
                badge: nil
            ),
            action: weakify(self, forFunction: AddWalletSelectorViewModel.onMobileWalletTap)
        )

        return [hardwareItem, mobileItem]
    }

    func makeBuyItem() -> BuyItem {
        BuyItem(
            title: Localization.walletAddHardwarePurchase,
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

    func onMobileWalletTap() {
        logMobileWalletTapAnalytics()
        guard mobileWalletFeatureProvider.isAvailable else {
            alert = mobileWalletFeatureProvider.makeRestrictionAlert()
            return
        }
        openMobileWallet()
    }
}

// MARK: - Navigation

private extension AddWalletSelectorViewModel {
    func openHardwareWallet() {
        coordinator?.openAddHardwareWallet()
    }

    func openMobileWallet() {
        coordinator?.openAddMobileWallet(source: .addNewWallet)
    }

    func openBuyHardwareWallet() {
        logBuyHardwareWalletAnalytics()
        safariManager.openURL(TangemShopUrlBuilder().url(utmCampaign: .users))
    }

    func openWhatToChoose() {
        safariManager.openURL(TangemBlogUrlBuilder().url(post: .mobileWallet))
    }
}

// MARK: - Analytics

private extension AddWalletSelectorViewModel {
    func logMobileWalletTapAnalytics() {
        Analytics.log(
            .buttonMobileWallet,
            params: [.source: .addNewWallet],
            contextParams: analyticsContextParams
        )
    }

    func logBuyHardwareWalletAnalytics() {
        Analytics.log(
            .basicButtonBuy,
            params: [.source: Analytics.BuyWalletSource.addWallet.parameterValue],
            contextParams: analyticsContextParams
        )
    }
}

// MARK: - Types

extension AddWalletSelectorViewModel {
    struct WalletItem: Identifiable {
        let id = UUID()
        let description: WalletDescriptionItem
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
}
