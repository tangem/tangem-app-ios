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
import TangemLocalization

final class ImportWalletSelectorViewModel: ObservableObject {
    @Published var isBuyAvailable = false

    let navigationBarTitle = Localization.homeButtonAddExistingWallet
    let screenTitle = Localization.walletImportTitle

    var walletItems: [WalletItem] = []
    let buyItem: BuyItem

    private weak var coordinator: ImportWalletSelectorRoutable?
    private weak var delegate: ImportWalletSelectorDelegate?

    init(coordinator: ImportWalletSelectorRoutable, delegate: ImportWalletSelectorDelegate) {
        self.coordinator = coordinator
        self.delegate = delegate
        buyItem = BuyItem(
            title: Localization.walletImportBuyQuestion,
            buttonTitle: Localization.walletImportBuyTitle
        )
        walletItems = makeWalletItems()
    }
}

// MARK: - Internal methods

extension ImportWalletSelectorViewModel {
    func onAppear() {
        scheduleBuyAvailability()
    }

    func onBuyTap() {
        delegate?.openBuyCard()
    }
}

// MARK: - Private methods

private extension ImportWalletSelectorViewModel {
    func makeWalletItems() -> [WalletItem] {
        [
            WalletItem(
                title: Localization.walletImportSeedTitle,
                titleIcon: nil,
                infoTag: nil,
                description: Localization.walletImportSeedDescription,
                isEnabled: true,
                action: { [weak coordinator] in
                    coordinator?.openOnboarding()
                }
            ),
            WalletItem(
                title: Localization.walletImportScanTitle,
                titleIcon: Assets.tangemIcon,
                infoTag: nil,
                description: Localization.walletImportScanDescription,
                isEnabled: true,
                action: { [weak delegate] in
                    delegate?.scanCard()
                }
            ),
            WalletItem(
                title: Localization.walletImportIcloudTitle,
                titleIcon: nil,
                infoTag: InfoTag(text: Localization.commonComingSoon, style: .secondary),
                description: Localization.walletImportIcloudDescription,
                isEnabled: false,
                action: {}
            ),
        ]
    }

    func scheduleBuyAvailability() {
        guard !isBuyAvailable else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            self?.isBuyAvailable = true
        }
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
