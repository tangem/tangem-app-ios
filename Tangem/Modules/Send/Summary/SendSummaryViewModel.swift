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

    var userInputAmountPublisher: AnyPublisher<Amount?, Never> { get }
    var destinationTextPublisher: AnyPublisher<String, Never> { get }
    var additionalFieldPublisher: AnyPublisher<(SendAdditionalFields, String)?, Never> { get }
    var feeValuePublisher: AnyPublisher<Fee?, Never> { get }
    var feeOptionPublisher: AnyPublisher<FeeOption, Never> { get }

    var isSending: AnyPublisher<Bool, Never> { get }

    func updateFees() -> AnyPublisher<FeeUpdateResult, Error>
    func send()
}

class SendSummaryViewModel: ObservableObject {
    let walletSummaryViewModel: SendWalletSummaryViewModel
    let canEditAmount: Bool
    let canEditDestination: Bool

    var sendButtonText: String {
        isSending ? Localization.sendSending : Localization.commonSend
    }

    var sendButtonIcon: MainButton.Icon? {
        isSending ? nil : .trailing(Assets.tangemIcon)
    }

    var destinationBackground: Color {
        sectionBackground(canEdit: canEditDestination)
    }

    var amountBackground: Color {
        sectionBackground(canEdit: canEditAmount)
    }

    @Published var isSendButtonDisabled = false
    @Published var isSending = false
    @Published var alert: AlertBinder?

    @Published var destinationViewTypes: [SendDestinationSummaryViewType] = []
    @Published var amountSummaryViewData: AmountSummaryViewData?
    @Published var feeSummaryViewData: DefaultTextWithTitleRowViewData?
    @Published var feeOptionIcon: Image?

    @Published var showSectionContent = false
    @Published private(set) var notificationInputs: [NotificationViewInput] = []

    weak var router: SendSummaryRoutable?

    private let sectionViewModelFactory: SendSummarySectionViewModelFactory
    private var screenIdleStartTime: Date?
    private var bag: Set<AnyCancellable> = []
    private let input: SendSummaryViewModelInput
    private let notificationManager: SendNotificationManager

    init(input: SendSummaryViewModelInput, notificationManager: SendNotificationManager, walletInfo: SendWalletInfo) {
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

    func onAppear() {
        withAnimation(SendView.Constants.sectionContentAnimation) {
            showSectionContent = true
        }

        screenIdleStartTime = Date()
    }

    func onDisappear() {
        showSectionContent = false
        screenIdleStartTime = nil
    }

    func didTapSummary(for step: SendStep) {
        if isSending {
            return
        }

        router?.openStep(step)
    }

    func send() {
        guard let screenIdleStartTime else { return }

        let feeValidityInterval: TimeInterval = 60
        let now = Date()
        if now.timeIntervalSince(screenIdleStartTime) <= feeValidityInterval {
            input.send()
            return
        }

        input.updateFees()
            .sink { [weak self] completion in
                if case .failure = completion {
                    self?.alert = AlertBuilder.makeOkErrorAlert(message: Localization.sendAlertTransactionFailedTitle)
                }
            } receiveValue: { [weak self] result in
                self?.screenIdleStartTime = Date()

                if let oldFee = result.oldFee, result.newFee > oldFee {
                    self?.alert = AlertBuilder.makeOkGotItAlert(message: Localization.sendAlertFeeIncreasedTitle)
                } else {
                    self?.input.send()
                }
            }
            .store(in: &bag)
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
            .userInputAmountPublisher
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

        input
            .feeOptionPublisher
            .map {
                $0.icon.image
            }
            .assign(to: \.feeOptionIcon, on: self, ownership: .weak)
            .store(in: &bag)

        notificationManager
            .notificationPublisher(for: .summary)
            .assign(to: \.notificationInputs, on: self, ownership: .weak)
            .store(in: &bag)

        notificationManager
            .hasNotifications(with: .critical)
            .assign(to: \.isSendButtonDisabled, on: self, ownership: .weak)
            .store(in: &bag)
    }

    private func sectionBackground(canEdit: Bool) -> Color {
        canEdit ? Colors.Background.action : Colors.Button.disabled
    }
}
