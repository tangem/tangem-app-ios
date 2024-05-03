//
//  ReceiveBottomSheetViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import UIKit
import SwiftUI
import Combine
import CombineExt

class ReceiveBottomSheetViewModel: ObservableObject, Identifiable {
    @Published var showToast: Bool = false

    let addressInfos: [ReceiveAddressInfo]
    let networkWarningMessage: String

    let id = UUID()
    let addressIndexUpdateNotifier = PassthroughSubject<Int, Never>()

    let iconURL: URL?

    var customTokenColor: Color? {
        tokenItem.token?.customTokenColor
    }

    private let tokenItem: TokenItem

    private var currentIndex = 0
    private var indexUpdateSubscription: AnyCancellable?

    var warningMessageFull: String {
        Localization.receiveBottomSheetWarningMessageFull(tokenItem.currencySymbol)
    }

    init(tokenItem: TokenItem, addressInfos: [ReceiveAddressInfo]) {
        self.tokenItem = tokenItem
        iconURL = tokenItem.id != nil ? IconURLBuilder().tokenIconURL(id: tokenItem.id!) : nil
        self.addressInfos = addressInfos

        networkWarningMessage = Localization.receiveBottomSheetWarningMessage(
            tokenItem.name,
            tokenItem.currencySymbol,
            tokenItem.networkName
        )

        bind()
    }

    func onViewAppear() {
        Analytics.log(.receiveScreenOpened)
    }

    func headerForAddress(with info: ReceiveAddressInfo) -> String {
        let name: String
        if addressInfos.count > 1 {
            name = "\(info.localizedName.capitalizingFirstLetter()) \(tokenItem.name)"
        } else {
            name = tokenItem.name
        }
        return Localization.receiveBottomSheetWarningMessage(name, tokenItem.currencySymbol, tokenItem.networkName)
    }

    func copyToClipboard() {
        Analytics.log(event: .buttonCopyAddress, params: [
            .token: tokenItem.currencySymbol,
            .source: Analytics.ParameterValue.receive.rawValue,
        ])
        UIPasteboard.general.string = addressInfos[currentIndex].address
        showToast = true
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
