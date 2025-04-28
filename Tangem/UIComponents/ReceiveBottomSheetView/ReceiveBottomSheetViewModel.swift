//
//  ReceiveBottomSheetViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import Combine
import CombineExt
import TangemAssets

class ReceiveBottomSheetViewModel: ObservableObject, Identifiable {
    let addressInfos: [ReceiveAddressInfo]
    let memoWarningMessage: String?

    let id = UUID()
    let addressIndexUpdateNotifier = PassthroughSubject<Int, Never>()

    let iconURL: URL?

    var customTokenColor: Color? {
        tokenItem.token?.customTokenColor
    }

    private let tokenItem: TokenItem

    private var currentIndex = 0
    private var indexUpdateSubscription: AnyCancellable?
    private let flow: Flow

    var assetSymbol: String {
        switch flow {
        case .nft:
            Localization.detailsNftTitle
        case .crypto:
            tokenItem.currencySymbol
        }
    }

    var networkName: String {
        tokenItem.networkName
    }

    init(flow: Flow, tokenItem: TokenItem, addressInfos: [ReceiveAddressInfo]) {
        self.tokenItem = tokenItem
        iconURL = tokenItem.id != nil ? IconURLBuilder().tokenIconURL(id: tokenItem.id!) : nil
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
        Analytics.log(event: .buttonCopyAddress, params: [
            .token: tokenItem.currencySymbol,
            .source: Analytics.ParameterValue.receive.rawValue,
        ])
        UIPasteboard.general.string = addressInfos[currentIndex].address

        Toast(view: SuccessToast(text: Localization.walletNotificationAddressCopied))
            .present(
                layout: .top(padding: 12),
                type: .temporary()
            )
    }

    func share() {
        Analytics.log(event: .buttonShareAddress, params: [.token: tokenItem.currencySymbol])
        let address = addressInfos[currentIndex].address
        // [REDACTED_TODO_COMMENT]
        let av = UIActivityViewController(activityItems: [address], applicationActivities: nil)
        UIApplication.modalFromTop(av)
    }

    private func bind() {
        indexUpdateSubscription = addressIndexUpdateNotifier
            .assign(to: \.currentIndex, on: self, ownership: .weak)
    }
}

extension ReceiveBottomSheetViewModel {
    enum Flow {
        case nft
        case crypto
    }
}
