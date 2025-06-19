//
//  ImportWalletSelectorViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI
import TangemAssets

final class ImportWalletSelectorViewModel: ObservableObject {
    let navigationBarTitle = "Add existing wallet"
    let screenTitle = "Import wallet"

    var walletItems: [WalletItem] = []
    let buyItem: BuyItem

    private weak var coordinator: ImportWalletSelectorRoutable?
    private weak var delegate: ImportWalletSelectorDelegate?

    init(coordinator: ImportWalletSelectorRoutable, delegate: ImportWalletSelectorDelegate) {
        self.coordinator = coordinator
        self.delegate = delegate
        buyItem = BuyItem(
            title: "Want to purchase a Tangem Wallet?",
            buttonTitle: "Buy Now"
        )
        walletItems = makeWalletItems()
    }
}

// MARK: - Internal methods

extension ImportWalletSelectorViewModel {
    func onBuyTap() {
        delegate?.openBuyCard()
    }
}

// MARK: - Private methods

private extension ImportWalletSelectorViewModel {
    func makeWalletItems() -> [WalletItem] {
        [
            WalletItem(
                title: "Import a recovery phrase",
                titleIcon: nil,
                infoTag: nil,
                description: "Your your seed phrase to recover your wallet",
                isEnabled: true,
                action: { [weak coordinator] in
                    coordinator?.openOnboarding()
                }
            ),
            WalletItem(
                title: "Scan a Tangem Wallet",
                titleIcon: Assets.tangemIcon,
                infoTag: nil,
                description: "Physical cards that securely store your crypto offline.",
                isEnabled: true,
                action: { [weak delegate] in
                    delegate?.scanCard()
                }
            ),
            WalletItem(
                title: "Import from iCloud ",
                titleIcon: nil,
                infoTag: InfoTag(text: "Coming Soon", style: .secondary),
                description: "Recover an existing wallet stored in your iCloud backup",
                isEnabled: false,
                action: {}
            ),
        ]
    }
}

// MARK: - Types

extension ImportWalletSelectorViewModel {
    struct WalletItem: Identifiable {
        let id = UUID()
        let title: String
        let titleIcon: ImageType?
        let infoTag: InfoTag?
        let description: String
        let isEnabled: Bool
        let action: () -> Void
    }

    struct InfoTag {
        let text: String
        let style: InfoTagStyle
    }

    enum InfoTagStyle {
        case secondary

        var color: Color {
            switch self {
            case .secondary:
                Colors.Text.secondary
            }
        }

        var bgColor: Color {
            switch self {
            case .secondary:
                Colors.Control.unchecked
            }
        }
    }

    struct BuyItem {
        let title: String
        let buttonTitle: String
    }
}
