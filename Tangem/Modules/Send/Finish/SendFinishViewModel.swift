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

    var amountValue: Amount? { get }
    var amountText: String { get } // remove
    var destinationText: String? { get }
    var additionalField: (SendAdditionalFields, String)? { get }
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

    let destinationViewTypes: [SendDestinationSummaryViewType]
    let amountSummaryViewData: AmountSummaryViewData?
    let feeSummaryViewModel: DefaultTextWithTitleRowViewData?

    weak var router: SendFinishRoutable?

    private let transactionURL: URL

    init?(input: SendFinishViewModelInput, walletInfo: SendWalletInfo) {
        let sectionViewModelFactory = SendSummarySectionViewModelFactory(
            tokenItem: input.tokenItem,
            currencyId: walletInfo.currencyId,
            tokenIconInfo: walletInfo.tokenIconInfo
        )

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

        destinationViewTypes = sectionViewModelFactory.makeDestinationViewTypes(address: destinationText, additionalField: input.additionalField)

        amountSummaryViewData = sectionViewModelFactory.makeAmountViewModel(from: input.amountValue)

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
