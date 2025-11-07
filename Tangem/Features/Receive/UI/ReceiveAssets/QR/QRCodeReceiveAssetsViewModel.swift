//
//  QRCodeReceiveAssetsViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine
import CombineExt
import TangemLocalization
import TangemAssets
import TangemUI

final class QRCodeReceiveAssetsViewModel: ObservableObject, Identifiable {
    // MARK: - Public Properties

    let addressInfo: ReceiveAddressInfo
    let memoWarningMessage: String?

    // MARK: - Private Implementation

    private let tokenItem: TokenItem
    private let flow: ReceiveFlow

    private let analyticsLogger: QRCodeReceiveAssetsAnalyticsLogger
    private weak var coordinator: QRCodeReceiveAssetsRoutable?

    // MARK: - Init

    init(
        flow: ReceiveFlow,
        tokenItem: TokenItem,
        addressInfo: ReceiveAddressInfo,
        analyticsLogger: QRCodeReceiveAssetsAnalyticsLogger,
        coordinator: QRCodeReceiveAssetsRoutable?
    ) {
        self.tokenItem = tokenItem
        self.addressInfo = addressInfo
        self.flow = flow
        self.analyticsLogger = analyticsLogger
        self.coordinator = coordinator

        memoWarningMessage = tokenItem.blockchain.hasMemo ? Localization.receiveBottomSheetNoMemoRequiredMessage : nil

        initialAppear()
    }

    func headerForAddress(with info: ReceiveAddressInfo) -> String {
        let name: String = tokenItem.name

        return switch flow {
        case .nft:
            Localization.receiveBottomSheetWarningMessageCompact(Localization.detailsNftTitle, tokenItem.networkName)
        case .crypto where tokenItem.blockchain.isL2EthereumNetwork:
            Localization.receiveBottomSheetWarningMessageCompact(name, tokenItem.networkName)
        case .crypto:
            Localization.receiveBottomSheetWarningMessage(name, tokenItem.currencySymbol, tokenItem.networkName)
        }
    }

    func stringForAddress(_ address: String) -> NSAttributedString {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .byCharWrapping
        paragraphStyle.alignment = .center

        let attributes: [NSAttributedString.Key: Any] = [
            .paragraphStyle: paragraphStyle,
            .font: UIFonts.Bold.callout,
            .foregroundColor: UIColor(Colors.Text.primary1),
        ]

        return NSAttributedString(string: address, attributes: attributes)
    }

    func copyToClipboard() {
        analyticsLogger.logCopyButtonTapped()
        coordinator?.copyToClipboard(with: addressInfo.address)
    }

    func share() {
        analyticsLogger.logShareButtonTapped()
        coordinator?.share(with: addressInfo.address)
    }

    private func initialAppear() {
        analyticsLogger.logQRCodeReceiveAssetsScreenOpened()
    }
}
