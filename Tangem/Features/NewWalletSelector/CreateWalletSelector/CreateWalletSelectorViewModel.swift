//
//  CreateWalletSelectorViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization

final class CreateWalletSelectorViewModel: ObservableObject {
    @Published var isScanAvailable = false

    let navigationBarHeight = OnboardingLayoutConstants.navbarSize.height
    let supportButtonTitle = Localization.walletCreateNavInfoTitle
    let screenTitle = Localization.walletCreateTitle

    var walletItems: [WalletItem] = []
    let scanItem: ScanItem

    private weak var coordinator: CreateWalletSelectorRoutable?
    private weak var delegate: CreateWalletSelectorDelegate?

    init(coordinator: CreateWalletSelectorRoutable, delegate: CreateWalletSelectorDelegate) {
        self.coordinator = coordinator
        self.delegate = delegate
        scanItem = ScanItem(
            title: Localization.walletCreateScanQuestion,
            buttonTitle: Localization.walletCreateScanTitle,
            buttonIcon: Assets.tangemIcon
        )
        walletItems = makeWalletItems()
    }
}

// MARK: - Internal methods

extension CreateWalletSelectorViewModel {
    func onAppear() {
        scheduleScanAvailability()
    }

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
                title: Localization.walletCreateMobileTitle,
                infoTag: InfoTag(text: Localization.commonFree, style: .secondary),
                description: Localization.walletCreateMobileDescription,
                action: { [weak coordinator] in
                    coordinator?.openMobileWallet()
                }
            ),
            WalletItem(
                title: Localization.walletCreateHardwareTitle,
                infoTag: InfoTag(text: Localization.walletCreateHardwareBadge("$54.90"), style: .accent),
                description: Localization.walletCreateHardwareDescription,
                action: { [weak coordinator] in
                    coordinator?.openHardwareWallet()
                }
            ),
        ]
    }

    func scheduleScanAvailability() {
        guard !isScanAvailable else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            self?.isScanAvailable = true
        }
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
