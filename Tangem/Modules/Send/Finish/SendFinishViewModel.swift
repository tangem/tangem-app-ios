//
//  SendFinishViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import Combine
import BlockchainSdk

protocol SendFinishViewModelInput: AnyObject {
    var tokenItem: TokenItem { get }

    var amountText: String { get }
    var destinationText: String? { get }
    var feeText: String { get } // remvoe?>
    var feeValue: Fee? { get }
    var transactionTime: Date? { get }
    var transactionURL: URL? { get }
}

class SendFinishViewModel: ObservableObject {
    let amountText: String
    let destinationText: String
    let feeText: String
    let transactionTime: String

    var amountSummaryViewData: AmountSummaryViewData
    var feeSummaryViewModel: DefaultTextWithTitleRowViewData?

    weak var router: SendFinishRoutable?

    private let transactionURL: URL

    init?(input: SendFinishViewModelInput) {
        let sectionViewModelFactory = SendSummarySectionViewModelFactory(tokenItem: input.tokenItem)
        
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short

        guard
            let destinationText = input.destinationText,
            let transactionTime = input.transactionTime,
            let transactionURL = input.transactionURL

        else {
            return nil
        }

        amountSummaryViewData = AmountSummaryViewData(
            title: Localization.sendAmountLabel,
            amount: "100.00 USDT",
            amountFiat: "99.98$",
            tokenIconInfo: .init(
                name: "tether",
                blockchainIconName: "ethereum.fill",
                imageURL: TokenIconURLBuilder().iconURL(id: "tether"),
                isCustom: false,
                customTokenColor: nil
            )
        )
        
        feeSummaryViewModel = sectionViewModelFactory.makeFeeViewModel(from: input.feeValue)

        amountText = input.amountText
        self.destinationText = destinationText
        feeText = input.feeText
        self.transactionTime = formatter.string(from: transactionTime)
        self.transactionURL = transactionURL
    }

    func explore() {
        router?.explore(url: transactionURL)
    }

    func share() {
        router?.share(url: transactionURL)
    }

    func close() {
        router?.dismiss()
    }
}
