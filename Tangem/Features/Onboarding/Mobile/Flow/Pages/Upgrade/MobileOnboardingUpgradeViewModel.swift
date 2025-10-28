//
//  MobileOnboardingUpgradeViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI
import TangemFoundation
import TangemLocalization
import TangemAssets

final class MobileOnboardingUpgradeViewModel: ObservableObject {
    // [REDACTED_TODO_COMMENT]
    let screenTitle = "Upgrade to Hardware Wallet"
    let buyButtonTitle = Localization.detailsBuyWallet
    let continueButtonTitle = Localization.commonContinue

    lazy var infoItems: [InfoItem] = makeInfoItems()

    @Injected(\.safariManager) private var safariManager: SafariManager

    private weak var delegate: MobileOnboardingUpgradeDelegate?

    init(delegate: MobileOnboardingUpgradeDelegate) {
        self.delegate = delegate
    }
}

// MARK: - Internal methods

extension MobileOnboardingUpgradeViewModel {
    func onContinueTap() {
        delegate?.upgradeContinue()
    }

    func onBuyTap() {
        safariManager.openURL(TangemBlogUrlBuilder().url(root: .pricing))
    }
}

// MARK: - Private methods

extension MobileOnboardingUpgradeViewModel {
    func makeInfoItems() -> [InfoItem] {
        let keyTrait = InfoItem(
            icon: Assets.Glyphs.mobileSecurity,
            title: Localization.hwUpgradeKeyMigrationTitle,
            subtitle: Localization.hwUpgradeKeyMigrationDescription
        )

        let fundsTrait = InfoItem(
            icon: Assets.Visa.securityCheck,
            title: Localization.hwUpgradeFundsAccessTitle,
            subtitle: Localization.hwUpgradeFundsAccessDescription
        )

        let securityTrait = InfoItem(
            icon: Assets.lock24,
            title: Localization.hwUpgradeGeneralSecurityTitle,
            subtitle: Localization.hwUpgradeGeneralSecurityDescription
        )

        return [keyTrait, fundsTrait, securityTrait]
    }
}

// MARK: - Types

extension MobileOnboardingUpgradeViewModel {
    struct InfoItem: Identifiable {
        let id = UUID()
        let icon: ImageType
        let title: String
        let subtitle: String
    }
}
