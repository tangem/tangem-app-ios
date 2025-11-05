//
//  ReceiveBottomSheetViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine
import CombineExt
import TangemLocalization
import TangemAssets
import TangemUI
import TangemAccessibilityIdentifiers

final class ReceiveBottomSheetViewModel: ObservableObject, Identifiable {
    let notificationInputs: [NotificationViewInput]
    let addressInfos: [ReceiveAddressInfo]
    let memoWarningMessage: String?
    let addressIndexUpdateNotifier = PassthroughSubject<Int, Never>()

    private let tokenItem: TokenItem
    private let flow: ReceiveFlow

    private var currentIndex = 0
    private var indexUpdateSubscription: AnyCancellable?

    init(
        flow: ReceiveFlow,
        tokenItem: TokenItem,
        notificationInputs: [NotificationViewInput],
        addressInfos: [ReceiveAddressInfo]
    ) {
        self.tokenItem = tokenItem
        self.notificationInputs = notificationInputs
        self.addressInfos = addressInfos
        self.flow = flow
        memoWarningMessage = tokenItem.blockchain.hasMemo ? Localization.receiveBottomSheetNoMemoRequiredMessage : nil

        bind()
    }

    func onViewAppear() {
        Analytics.log(event: .receiveScreenOpened, params: [.token: tokenItem.currencySymbol])
    }

    func headerForAddress(with info: ReceiveAddressInfo) -> String {
        let name: String
        if addressInfos.count > 1 {
            name = "\(info.localizedName.capitalizingFirstLetter()) \(tokenItem.name)"
        } else {
            name = tokenItem.name
        }

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
        copyAnalytics()
        UIPasteboard.general.string = addressInfos[currentIndex].address

        Toast(
            view: SuccessToast(text: Localization.walletNotificationAddressCopied)
                .accessibilityIdentifier(ActionButtonsAccessibilityIdentifiers.addressCopiedToast)
        )
        .present(
            layout: .top(padding: 12),
            type: .temporary()
        )
    }

    func share() {
        shareAnalytics()
        let address = addressInfos[currentIndex].address
        // [REDACTED_TODO_COMMENT]
        let av = UIActivityViewController(activityItems: [address], applicationActivities: nil)
        UIApplication.modalFromTop(av)
    }

    private func bind() {
        indexUpdateSubscription = addressIndexUpdateNotifier
            .assign(to: \.currentIndex, on: self, ownership: .weak)
    }

    private func shareAnalytics() {
        switch flow {
        case .nft:
            Analytics.log(event: .nftReceiveShareAddressButtonClicked, params: [.blockchain: tokenItem.blockchain.displayName])
        case .crypto:
            Analytics.log(event: .buttonShareAddress, params: [
                .token: tokenItem.currencySymbol,
                .blockchain: tokenItem.blockchain.displayName,
            ])
        }
    }

    private func copyAnalytics() {
        switch flow {
        case .nft:
            Analytics.log(event: .nftReceiveCopyAddressButtonClicked, params: [.blockchain: tokenItem.blockchain.displayName])

        case .crypto:
            Analytics.log(event: .buttonCopyAddress, params: [
                .token: tokenItem.currencySymbol,
                .source: Analytics.ParameterValue.receive.rawValue,
                .blockchain: tokenItem.blockchain.displayName,
            ])
        }
    }
}
