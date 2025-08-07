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

    @Published var transactionDescription: AttributedString?
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

    private let interactor: SendNewSummaryInteractor
    private let destinationEditableType: EditableType
    private let amountEditableType: EditableType
    private let notificationManager: NotificationManager

    weak var router: SendSummaryStepsRoutable?

    private var bag: Set<AnyCancellable> = []

    init(
        interactor: SendNewSummaryInteractor,
        destinationEditableType: EditableType,
        amountEditableType: EditableType,
        notificationManager: NotificationManager,
        sendAmountCompactViewModel: SendNewAmountCompactViewModel?,
        sendDestinationCompactViewModel: SendNewDestinationCompactViewModel?,
        stakingValidatorsCompactViewModel: StakingValidatorsCompactViewModel?,
        sendFeeCompactViewModel: SendNewFeeCompactViewModel?
    ) {
        self.interactor = interactor
        self.destinationEditableType = destinationEditableType
        self.amountEditableType = amountEditableType
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
            .receiveOnMain()
            .assign(to: &$transactionDescription)

        interactor
            .isNotificationButtonIsLoading
            .receiveOnMain()
            .assign(to: &$notificationButtonIsLoading)

        notificationManager
            .notificationPublisher
            .receiveOnMain()
            .assign(to: &$notificationInputs)
    }
}

// MARK: - SendStepViewAnimatable

extension SendNewSummaryViewModel: SendStepViewAnimatable {
    func viewDidChangeVisibilityState(_ state: SendStepVisibilityState) {}
}

extension SendNewSummaryViewModel {
    typealias EditableType = SendSummaryViewModel.EditableType
}
