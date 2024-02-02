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

    let walletSummaryViewModel: SendWalletSummaryViewModel
    @Published var destinationViewTypes: [SendDestinationSummaryViewType] = []
    @Published var amountSummaryViewData: AmountSummaryViewData?
    @Published var feeSummaryViewData: DefaultTextWithTitleRowViewData?

    @Published private(set) var notificationInputs: [NotificationViewInput] = []

    weak var router: SendSummaryRoutable?

    private let sectionViewModelFactory: SendSummarySectionViewModelFactory
    private var bag: Set<AnyCancellable> = []
    private let input: SendSummaryViewModelInput
    private let notificationManager: NotificationManager

    init(input: SendSummaryViewModelInput, notificationManager: NotificationManager, walletInfo: SendWalletInfo) {
        self.input = input
        self.notificationManager = notificationManager

        sectionViewModelFactory = SendSummarySectionViewModelFactory(
            feeCurrencySymbol: walletInfo.feeCurrencySymbol,
            feeCurrencyId: walletInfo.feeCurrencyId,
            isFeeApproximate: walletInfo.isFeeApproximate,
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
        input.send()
    }

    private func bind() {
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
                self?.sectionViewModelFactory.makeAmountViewData(from: amount)
            }
            .assign(to: \.amountSummaryViewData, on: self, ownership: .weak)
            .store(in: &bag)

        input
            .feeValuePublisher
            .map { [weak self] fee in
                self?.sectionViewModelFactory.makeFeeViewData(from: fee)
            }
            .assign(to: \.feeSummaryViewData, on: self, ownership: .weak)
            .store(in: &bag)

        (notificationManager as! SendNotificationManager)
            .notificationPublisher(for: .summary)
//            .transactionCreationNotificationPublisher()
            .assign(to: \.notificationInputs, on: self, ownership: .weak)
            .store(in: &bag)
    }
}
