//
//  SelectorReceiveAssetsAddressPageItemViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import UIKit
import Combine
import TangemAssets
import TangemUI
import TangemLocalization

final class SelectorReceiveAssetsAddressPageItemViewModel: ObservableObject {
    var title: String {
        SelectorReceiveAssetsTitleBuilder().build(for: tokenItem, with: addressInfo.type)
    }

    var tokenIconInfo: TokenIconInfo {
        TokenIconInfoBuilder().build(from: tokenItem, isCustom: false)
    }

    var address: NSAttributedString {
        stringForAddress(addressInfo.address)
    }

    // MARK: - Private Properties

    private let tokenItem: TokenItem
    private let addressInfo: ReceiveAddressInfo
    private let analyticsLogger: ItemSelectorReceiveAssetsAnalyticsLogger
    private weak var coordinator: SelectorReceiveAssetItemRoutable?

    // MARK: - Init

    init(
        tokenItem: TokenItem,
        addressInfo: ReceiveAddressInfo,
        analyticsLogger: ItemSelectorReceiveAssetsAnalyticsLogger,
        coordinator: SelectorReceiveAssetItemRoutable?
    ) {
        self.tokenItem = tokenItem
        self.addressInfo = addressInfo
        self.analyticsLogger = analyticsLogger
        self.coordinator = coordinator
    }

    // MARK: - Actions

    func qrCodeButtonDidTap() {
        coordinator?.routeOnReceiveQR(with: addressInfo)
    }

    func copyAddressButtonDidTap() {
        analyticsLogger.logCopyAddressButtonTapped()
        coordinator?.copyToClipboard(with: addressInfo.address)
    }

    func shareButtonDidTap() {
        coordinator?.share(with: addressInfo.address)
    }

    // MARK: - Private Implementation

    private func stringForAddress(_ address: String) -> NSAttributedString {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .byCharWrapping
        paragraphStyle.alignment = .center

        let attributes: [NSAttributedString.Key: Any] = [
            .paragraphStyle: paragraphStyle,
            .font: UIFonts.Regular.footnote,
            .foregroundColor: UIColor(Colors.Text.tertiary),
        ]

        return NSAttributedString(string: address, attributes: attributes)
    }
}

extension SelectorReceiveAssetsAddressPageItemViewModel: Identifiable, Hashable, Equatable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(tokenItem)
        hasher.combine(addressInfo.address)
    }

    static func == (lhs: SelectorReceiveAssetsAddressPageItemViewModel, rhs: SelectorReceiveAssetsAddressPageItemViewModel) -> Bool {
        lhs.tokenItem == rhs.tokenItem && lhs.addressInfo.address == rhs.addressInfo.address
    }
}
