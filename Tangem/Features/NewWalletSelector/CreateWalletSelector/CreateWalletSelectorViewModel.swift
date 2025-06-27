//
//  CreateWalletSelectorViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

final class CreateWalletSelectorViewModel {
    let navigationBarHeight = OnboardingLayoutConstants.navbarSize.height
    let supportButtonTitle = "What to choose?"
    let screenTitle = "Choose how you want to create your wallet"

    var walletItems: [WalletItem] = []
    let scanItem: ScanItem

    private weak var coordinator: CreateWalletSelectorRoutable?
    private weak var delegate: CreateWalletSelectorDelegate?

    init(coordinator: CreateWalletSelectorRoutable, delegate: CreateWalletSelectorDelegate) {
        self.coordinator = coordinator
        self.delegate = delegate
        scanItem = ScanItem(
            title: "Do you already have Tangem Wallet?",
            buttonTitle: "Scan device",
            buttonIcon: Assets.tangemIcon
        )
        walletItems = makeWalletItems()
    }
}

// MARK: - Internal methods

extension CreateWalletSelectorViewModel {
    func onSupportTap() {
        coordinator?.openWhatToChoose()
    }

    func onScanTap() {
        delegate?.scanCard()
    }
}

// MARK: - Private methods

private extension CreateWalletSelectorViewModel {
    func makeWalletItems() -> [WalletItem] {
        [
            WalletItem(
                title: "Mobile Wallet",
                infoTag: InfoTag(text: "Free", style: .secondary),
                description: "A secure wallet is created on your phone in seconds.",
                action: { [weak coordinator] in
                    coordinator?.openMobileWallet()
                }
            ),
            WalletItem(
                title: "Hardware Wallet",
                infoTag: InfoTag(text: "From $54.90", style: .accent),
                description: "Buy Tangem Wallet — physical cards that securely store your crypto offline.",
                action: { [weak coordinator] in
                    coordinator?.openHardwareWallet()
                }
            ),
        ]
    }
}

// MARK: - Types

extension CreateWalletSelectorViewModel {
    struct WalletItem {
        let title: String
        let infoTag: InfoTag
        let description: String
        let action: () -> Void
    }

    struct InfoTag {
        let text: String
        let style: InfoTagStyle
    }

    enum InfoTagStyle {
        case secondary
        case accent

        var color: Color {
            switch self {
            case .secondary:
                Colors.Text.secondary
            case .accent:
                Colors.Text.accent
            }
        }

        var bgColor: Color {
            switch self {
            case .secondary:
                Colors.Control.unchecked
            case .accent:
                Colors.Text.accent.opacity(0.1)
            }
        }
    }

    struct ScanItem {
        let title: String
        let buttonTitle: String
        let buttonIcon: ImageType
    }
}
