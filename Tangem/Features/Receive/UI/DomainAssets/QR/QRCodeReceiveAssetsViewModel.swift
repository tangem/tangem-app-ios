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

    private weak var coordinator: QRCodeReceiveAssetsRoutable?

    // MARK: - Init

    init(
        flow: ReceiveFlow,
        tokenItem: TokenItem,
        addressInfo: ReceiveAddressInfo,
        coordinator: QRCodeReceiveAssetsRoutable?
    ) {
        self.tokenItem = tokenItem
        self.addressInfo = addressInfo
        self.flow = flow
        self.coordinator = coordinator

        memoWarningMessage = tokenItem.blockchain.hasMemo ? Localization.receiveBottomSheetNoMemoRequiredMessage : nil
    }

    func onViewAppear() {
        Analytics.log(event: .receiveScreenOpened, params: [.token: tokenItem.currencySymbol])
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
        coordinator?.copyToClipboard(with: addressInfo.address)
    }

    func share() {
        coordinator?.share(with: addressInfo.address)
    }
}
