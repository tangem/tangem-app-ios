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
    var canEditAmount: Bool { get }
    var canEditDestination: Bool { get }

    var tokenItem: TokenItem { get }

    var amountPublisher: AnyPublisher<Amount?, Never> { get }
    var destinationTextPublisher: AnyPublisher<String, Never> { get }
    var additionalFieldPublisher: AnyPublisher<(SendAdditionalFields, String)?, Never> { get }
    var feeValuePublisher: AnyPublisher<Fee?, Never> { get }

    var isSending: AnyPublisher<Bool, Never> { get }

    func send()
}

class SendSummaryViewModel: ObservableObject {
    let canEditAmount: Bool
    let canEditDestination: Bool

    @Published var isSending = false

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
    private let walletInfo: SendWalletInfo
    private var bag: Set<AnyCancellable> = []
    private weak var input: SendSummaryViewModelInput?

    init(input: SendSummaryViewModelInput, walletInfo: SendWalletInfo) {
        self.input = input
        self.walletInfo = walletInfo

        sectionViewModelFactory = SendSummarySectionViewModelFactory(
            tokenItem: input.tokenItem,
            currencyId: walletInfo.currencyId,
            tokenIconInfo: walletInfo.tokenIconInfo
        )

        walletSummaryViewModel = SendWalletSummaryViewModel(
            walletName: walletInfo.walletName,
            totalBalance: walletInfo.balance
        )

        canEditAmount = input.canEditAmount
        canEditDestination = input.canEditDestination

        bind()
    }

    func didTapSummary(for step: SendStep) {
        router?.openStep(step)
    }

    func send() {
        input?.send()
    }

    private func bind() {
        guard let input else { return }

        input
            .isSending
            .assign(to: \.isSending, on: self, ownership: .weak)
            .store(in: &bag)

        Publishers.CombineLatest(input.destinationTextPublisher, input.additionalFieldPublisher)
            .map { [weak self] destination, additionalField in
                self?.sectionViewModelFactory.makeDestinationViewTypes(address: destination, additionalField: additionalField) ?? []
            }
            .assign(to: \.destinationViewTypes, on: self)
            .store(in: &bag)

        input
            .amountPublisher
            .compactMap { [weak self] amount in
                self?.sectionViewModelFactory.makeAmountViewModel(from: amount)
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
