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
    var destination2: AnyPublisher<String, Never> { get }
    var additionalField2: AnyPublisher<(SendAdditionalFields, String)?, Never> { get }
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

    @Published var dest: [SendDestinationSummaryViewType] = []

    let walletSummaryViewModel: SendWalletSummaryViewModel
    var amountSummaryViewData: AmountSummaryViewData?
    var feeSummaryViewModel: DefaultTextWithTitleRowViewData?

    weak var router: SendSummaryRoutable?

    private var feeFormatter: SwappingFeeFormatter {
        CommonSwappingFeeFormatter(
            balanceFormatter: BalanceFormatter(),
            balanceConverter: BalanceConverter(),
            fiatRatesProvider: SwappingRatesProvider()
        )
    }

    private var bag: Set<AnyCancellable> = []
    private weak var input: SendSummaryViewModelInput?

    let ddd: AnyPublisher<[SendDestinationSummaryViewType], Never>
    init(input: SendSummaryViewModelInput, walletInfo: SendWalletInfo) {
        walletSummaryViewModel = SendWalletSummaryViewModel(
            walletName: walletInfo.walletName,
            totalBalance: walletInfo.balance
        )

        amountText = input.amountText

        ddd =
            .just(output: [
                SendDestinationSummaryViewType.address(address: "0x391316d97a07027a0702c8A002c8A0C25d8470"),
                SendDestinationSummaryViewType.additionalField(type: .memo, value: "123456789"),
            ])

        canEditAmount = input.canEditAmount
        canEditDestination = input.canEditDestination

        destinationText = input.destinationTextBinding.wrappedValue

        self.input = input

        Publishers.CombineLatest(input.destination2, input.additionalField2)
            .map {
                destination, add in

                var v: [SendDestinationSummaryViewType] = [
                    .address(address: destination),
                ]

                if let add {
                    v.append(.additionalField(type: add.0, value: add.1))
                }

                return v
            }
            .assign(to: \.dest, on: self)
            .store(in: &bag)

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
            .map { value in
                guard let value else { return nil }

                let formattedValue = self.feeFormatter.format(
                    fee: value.amount.value,
                    tokenItem: input.tokenItem
                )

                return DefaultTextWithTitleRowViewData(title: Localization.sendNetworkFeeTitle, text: formattedValue)
            }
            .assign(to: \.feeSummaryViewModel, on: self, ownership: .weak)
            .store(in: &bag)
    }
}
