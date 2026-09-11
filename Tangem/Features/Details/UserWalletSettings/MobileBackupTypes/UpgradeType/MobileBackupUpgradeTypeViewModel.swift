//
//  MobileBackupUpgradeTypeViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import TangemFoundation
import TangemLocalization

final class MobileBackupUpgradeTypeViewModel: ObservableObject {
    @Published private(set) var item: Item?

    private var analyticsContextParams: Analytics.ContextParams {
        .custom(userWalletModel.analyticsContextData)
    }

    private let userWalletModel: UserWalletModel
    private weak var delegate: MobileBackupUpgradeTypeDelegate?

    init(userWalletModel: UserWalletModel, delegate: MobileBackupUpgradeTypeDelegate) {
        self.userWalletModel = userWalletModel
        self.delegate = delegate
        item = makeItem()
    }
}

// MARK: - Private methods

private extension MobileBackupUpgradeTypeViewModel {
    func makeItem() -> Item {
        let badge = BadgeView.Item(title: Localization.commonRecommended, style: .accent)
        let action = weakify(self, forFunction: MobileBackupUpgradeTypeViewModel.onItemTap)

        return Item(
            title: Localization.hwBackupUpgradeTitle,
            description: Localization.hwBackupUpgradeDescription,
            badge: badge,
            action: action
        )
    }

    func onItemTap() {
        logTapAnalytics()

        runTask(in: self) { viewModel in
            await viewModel.openUpgradeFlow()
        }
    }
}

// MARK: - Routing

private extension MobileBackupUpgradeTypeViewModel {
    func openUpgradeFlow() async {
        await delegate?.onUpgradeTap()
    }
}

// MARK: - Analytics

private extension MobileBackupUpgradeTypeViewModel {
    func logTapAnalytics() {
        Analytics.log(.walletSettingsButtonHardwareUpdate, contextParams: analyticsContextParams)
    }
}

// MARK: - Types

extension MobileBackupUpgradeTypeViewModel {
    struct Item {
        let title: String
        let description: String
        let badge: BadgeView.Item
        let action: () -> Void
    }
}
