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
    @Published private(set) var sendDestinationCompactViewModel: SendNewDestinationCompactViewModel?
    @Published private(set) var stakingValidatorsCompactViewModel: StakingValidatorsCompactViewModel?
    @Published private(set) var sendFeeCompactViewModel: SendNewFeeCompactViewModel?

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

    private var bag: Set<AnyCancellable> = []

    init(
        settings: Settings,
        interactor: SendSummaryInteractor,
        notificationManager: NotificationManager,
        sendAmountCompactViewModel: SendNewAmountCompactViewModel?,
        sendDestinationCompactViewModel: SendNewDestinationCompactViewModel?,
        stakingValidatorsCompactViewModel: StakingValidatorsCompactViewModel?,
        sendFeeCompactViewModel: SendNewFeeCompactViewModel?
    ) {
        destinationEditableType = settings.destinationEditableType
        amountEditableType = settings.amountEditableType
        tokenItem = settings.tokenItem
        actionType = settings.actionType

        self.interactor = interactor
        self.notificationManager = notificationManager
        self.sendAmountCompactViewModel = sendAmountCompactViewModel
        self.sendDestinationCompactViewModel = sendDestinationCompactViewModel
        self.stakingValidatorsCompactViewModel = stakingValidatorsCompactViewModel
        self.sendFeeCompactViewModel = sendFeeCompactViewModel

        sendAmountCompactViewModel?.router = self

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

    func userDidTapValidator() {
        didTapSummary()
        router?.summaryStepRequestEditValidators()
    }

    func userDidTapFee() {
        didTapSummary()
        router?.summaryStepRequestEditFee()
    }
}

// MARK: - SendNewAmountCompactRoutable

extension SendNewSummaryViewModel: SendNewAmountCompactRoutable {
    func userDidTapAmount() {
        didTapSummary()
        router?.summaryStepRequestEditAmount()
    }

    func userDidTapReceiveTokenAmount() {
        didTapSummary()
        router?.summaryStepRequestEditAmount()
    }

    func userDidTapSwapProvider() {
        didTapSummary()
        router?.summaryStepRequestEditProviders()
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

// MARK: - SendStepViewAnimatable

extension SendNewSummaryViewModel: SendStepViewAnimatable {
    func viewDidChangeVisibilityState(_ state: SendStepVisibilityState) {}
}

extension SendNewSummaryViewModel {
    typealias Settings = SendSummaryViewModel.Settings
    typealias EditableType = SendSummaryViewModel.EditableType
}
