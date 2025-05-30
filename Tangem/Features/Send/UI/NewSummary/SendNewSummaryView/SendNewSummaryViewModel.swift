//
//  SendNewSummaryViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import Combine

class SendNewSummaryViewModel: ObservableObject, Identifiable {
    @Published private(set) var sendAmountCompactViewModel: SendNewAmountCompactViewModel?
    @Published private(set) var sendAmountsSeparator: SendNewAmountCompactViewSeparator.SeparatorStyle?
    @Published private(set) var sendReceiveTokenCompactViewModel: SendNewAmountCompactViewModel?
    @Published private(set) var sendDestinationCompactViewModel: SendDestinationCompactViewModel?
    @Published private(set) var stakingValidatorsCompactViewModel: StakingValidatorsCompactViewModel?
    @Published private(set) var sendFeeCompactViewModel: SendFeeCompactViewModel?

    @Published var showHint = false
    @Published var notificationInputs: [NotificationViewInput] = []
    @Published var notificationButtonIsLoading = false

    @Published var transactionDescription: String?
    @Published var transactionDescriptionIsVisible: Bool = false

    var destinationCompactViewType: SendCompactViewEditableType {
        switch destinationEditableType {
        case .disable: .disabled
        case .editable: .enabled(action: userDidTapDestination)
        case .noEditable: .enabled()
        }
    }

    var amountCompactViewType: SendCompactViewEditableType {
        switch amountEditableType {
        case .disable: .disabled
        case .editable: .enabled(action: userDidTapAmount)
        case .noEditable: .enabled()
        }
    }

    private let tokenItem: TokenItem
    private let destinationEditableType: EditableType
    private let amountEditableType: EditableType
    private let interactor: SendSummaryInteractor
    private let notificationManager: NotificationManager
    private let actionType: SendFlowActionType

    weak var router: SendSummaryStepsRoutable?

    private var receiveTokenSubscription: AnyCancellable?
    private var bag: Set<AnyCancellable> = []

    init(
        settings: Settings,
        interactor: SendSummaryInteractor,
        notificationManager: NotificationManager,
        sendAmountCompactViewModel: SendNewAmountCompactViewModel?,
        sendReceiveTokenCompactViewModel: SendNewAmountCompactViewModel?,
        sendDestinationCompactViewModel: SendDestinationCompactViewModel?,
        stakingValidatorsCompactViewModel: StakingValidatorsCompactViewModel?,
        sendFeeCompactViewModel: SendFeeCompactViewModel?
    ) {
        destinationEditableType = settings.destinationEditableType
        amountEditableType = settings.amountEditableType
        tokenItem = settings.tokenItem
        actionType = settings.actionType

        self.interactor = interactor
        self.notificationManager = notificationManager
        self.sendAmountCompactViewModel = sendAmountCompactViewModel
        self.sendReceiveTokenCompactViewModel = sendReceiveTokenCompactViewModel
        self.sendDestinationCompactViewModel = sendDestinationCompactViewModel
        self.stakingValidatorsCompactViewModel = stakingValidatorsCompactViewModel
        self.sendFeeCompactViewModel = sendFeeCompactViewModel

        bind()
    }

    func onAppear() {
        transactionDescriptionIsVisible = true
    }

    func onDisappear() {}

    func userDidTapDestination() {
        didTapSummary()
        router?.summaryStepRequestEditDestination()
    }

    func userDidTapAmount() {
        didTapSummary()
        router?.summaryStepRequestEditAmount()
    }

    func userDidTapReceiveTokenAmount() {
        didTapSummary()
        // [REDACTED_TODO_COMMENT]
        // router?.summaryStepRequestEditAmount()
    }

    func userDidTapValidator() {
        // [REDACTED_TODO_COMMENT]
        // didTapSummary()
        // router?.summaryStepRequestEditValidators()
    }

    func userDidTapFee() {
        didTapSummary()
        router?.summaryStepRequestEditFee()
    }
}

// MARK: - Private

private extension SendNewSummaryViewModel {
    private func didTapSummary() {
        AppSettings.shared.userDidTapSendScreenSummary = true
        showHint = false
    }

    func bind() {
        interactor
            .transactionDescription
            .receive(on: DispatchQueue.main)
            .assign(to: \.transactionDescription, on: self, ownership: .weak)
            .store(in: &bag)

        interactor
            .isNotificationButtonIsLoading
            .receive(on: DispatchQueue.main)
            .assign(to: \.notificationButtonIsLoading, on: self, ownership: .weak)
            .store(in: &bag)

        notificationManager
            .notificationPublisher
            .withWeakCaptureOf(self)
            .receive(on: DispatchQueue.main)
            .sink { viewModel, notificationInputs in
                viewModel.notificationInputs = notificationInputs
            }
            .store(in: &bag)
    }
}

// MARK: - Receive token

extension SendNewSummaryViewModel {
    private func bind(input: SendReceiveTokenInput) {
        receiveTokenSubscription = input.receiveTokenPublisher
            .withWeakCaptureOf(self)
            .receiveOnMain()
            .sink { viewModel, receiveToken in
                viewModel.sendReceiveTokenCompactViewModel = receiveToken.map { .init(receiveToken: $0) }
                viewModel.sendReceiveTokenCompactViewModel?.bind(amountPublisher: input.receiveAmountPublisher)
                // [REDACTED_TODO_COMMENT]
                viewModel.sendAmountsSeparator = receiveToken == nil ? nil : .title("Send via Swap")
            }
    }
}

// MARK: - SendStepViewAnimatable

extension SendNewSummaryViewModel: SendStepViewAnimatable {
    func viewDidChangeVisibilityState(_ state: SendStepVisibilityState) {}
}

extension SendNewSummaryViewModel {
    typealias Settings = SendSummaryViewModel.Settings
    typealias EditableType = SendSummaryViewModel.EditableType
}
