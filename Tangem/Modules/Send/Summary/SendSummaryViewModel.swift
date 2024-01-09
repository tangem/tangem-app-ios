//
//  SendSummaryViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import Combine
import BlockchainSdk

protocol SendSummaryViewModelInput: AnyObject {
    var amountText: String { get } // remove
    var canEditAmount: Bool { get }
    var canEditDestination: Bool { get }

    var tokenItem: TokenItem { get }

    var amountPublisher: AnyPublisher<Amount?, Never> { get }
    var destinationTextPublisher: AnyPublisher<String, Never> { get }
    var additionalFieldPublisher: AnyPublisher<(SendAdditionalFields, String)?, Never> { get }
    var destinationTextBinding: Binding<String> { get }
    var feeTextPublisher: AnyPublisher<String?, Never> { get } // remove
    var feeValuePublisher: AnyPublisher<Fee?, Never> { get }

    var isSending: AnyPublisher<Bool, Never> { get }

    func send()
}

class SendSummaryViewModel: ObservableObject {
    let canEditAmount: Bool
    let canEditDestination: Bool

    let amountText: String
    let destinationText: String

    @Published var isSending = false
    @Published var feeText: String = ""

    @Published var destinationViewTypes: [SendDestinationSummaryViewType] = []
    @Published var amountSummaryViewData: AmountSummaryViewData?
    @Published var feeSummaryViewModel: DefaultTextWithTitleRowViewData?

    let walletSummaryViewModel: SendWalletSummaryViewModel

    weak var router: SendSummaryRoutable?

    private var feeFormatter: SwappingFeeFormatter {
        CommonSwappingFeeFormatter(
            balanceFormatter: BalanceFormatter(),
            balanceConverter: BalanceConverter(),
            fiatRatesProvider: SwappingRatesProvider()
        )
    }

    private let sectionViewModelFactory: SendSummarySectionViewModelFactory

    private var bag: Set<AnyCancellable> = []
    private weak var input: SendSummaryViewModelInput?

    init(input: SendSummaryViewModelInput, walletInfo: SendWalletInfo) {
        sectionViewModelFactory = SendSummarySectionViewModelFactory(tokenItem: input.tokenItem)

        walletSummaryViewModel = SendWalletSummaryViewModel(
            walletName: walletInfo.walletName,
            totalBalance: walletInfo.balance
        )

        amountText = input.amountText

        canEditAmount = input.canEditAmount
        canEditDestination = input.canEditDestination

        destinationText = input.destinationTextBinding.wrappedValue

        self.input = input

        bind(from: input, walletInfo: walletInfo)
    }

    func didTapSummary(for step: SendStep) {
        router?.openStep(step)
    }

    func send() {
        input?.send()
    }

    private func bind(from input: SendSummaryViewModelInput, walletInfo: SendWalletInfo) {
        input
            .isSending
            .assign(to: \.isSending, on: self, ownership: .weak)
            .store(in: &bag)

        Publishers.CombineLatest(input.destinationTextPublisher, input.additionalFieldPublisher)
            .map { destination, additionalField in
                var destinationViewTypes: [SendDestinationSummaryViewType] = [
                    .address(address: destination),
                ]

                if let (additionalFieldType, additionalFieldValue) = additionalField {
                    destinationViewTypes.append(.additionalField(type: additionalFieldType, value: additionalFieldValue))
                }

                return destinationViewTypes
            }
            .assign(to: \.destinationViewTypes, on: self)
            .store(in: &bag)

        input
            .feeTextPublisher
            .map {
                $0 ?? ""
            }
            .assign(to: \.feeText, on: self, ownership: .weak)
            .store(in: &bag)

        input
            .amountPublisher
            .compactMap { amount in
                guard let amount else { return nil }

                let formattedAmount = amount.description

                let amountFiat: String?
                if let currencyId = walletInfo.currencyId,
                   let fiatValue = BalanceConverter().convertToFiat(value: amount.value, from: currencyId) {
                    amountFiat = fiatValue.currencyFormatted(code: AppSettings.shared.selectedCurrencyCode, maximumFractionDigits: 2)
                } else {
                    amountFiat = nil
                }
                return AmountSummaryViewData(
                    title: Localization.sendAmountLabel,
                    amount: formattedAmount,
                    amountFiat: amountFiat ?? "",
                    tokenIconInfo: walletInfo.tokenIconInfo
                )
            }
            .assign(to: \.amountSummaryViewData, on: self, ownership: .weak)
            .store(in: &bag)

        input
            .feeValuePublisher
            .map { [weak self] fee in
                self?.sectionViewModelFactory.makeFeeViewModel(from: fee)
            }
            .assign(to: \.feeSummaryViewModel, on: self, ownership: .weak)
            .store(in: &bag)
    }
}
