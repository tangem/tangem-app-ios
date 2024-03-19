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
    var userInputAmountValue: Amount? { get }
    var destinationText: String? { get }
    var additionalField: (SendAdditionalFields, String)? { get }
    var feeValue: Fee? { get }

    var transactionTime: Date? { get }
    var transactionURL: URL? { get }
}

class SendFinishViewModel: ObservableObject {
    @Published var showHeader = false
    @Published var showButtons = false

    let transactionTime: String

    let destinationViewTypes: [SendDestinationSummaryViewType]
    let amountSummaryViewData: SendAmountSummaryViewData?
    let feeSummaryViewData: SendFeeSummaryViewData?

    weak var router: SendFinishRoutable?

    private let transactionURL: URL

    init?(input: SendFinishViewModelInput, walletInfo: SendWalletInfo) {
        guard
            let destinationText = input.destinationText,
            let transactionTime = input.transactionTime,
            let transactionURL = input.transactionURL
        else {
            return nil
        }

        let sectionViewModelFactory = SendSummarySectionViewModelFactory(
            feeCurrencySymbol: walletInfo.feeCurrencySymbol,
            feeCurrencyId: walletInfo.feeCurrencyId,
            isFeeApproximate: walletInfo.isFeeApproximate,
            currencyId: walletInfo.currencyId,
            tokenIconInfo: walletInfo.tokenIconInfo
        )

        destinationViewTypes = sectionViewModelFactory.makeDestinationViewTypes(
            address: destinationText,
            additionalField: input.additionalField
        )
        amountSummaryViewData = sectionViewModelFactory.makeAmountViewData(from: input.userInputAmountValue)
        feeSummaryViewData = sectionViewModelFactory.makeFeeViewData(from: input.feeValue)

        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        self.transactionTime = formatter.string(from: transactionTime)
        self.transactionURL = transactionURL
    }

    func onAppear() {
        showHeader = true
        showButtons = true
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
