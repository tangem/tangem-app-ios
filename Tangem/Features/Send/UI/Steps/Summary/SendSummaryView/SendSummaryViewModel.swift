//
//  SendSummaryViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import Combine

class SendSummaryViewModel: ObservableObject, Identifiable {
    @Published private(set) var sendAmountCompactViewModel: SendAmountCompactViewModel?
    @Published private(set) var nftAssetCompactViewModel: NFTAssetCompactViewModel?
    @Published private(set) var sendDestinationCompactViewModel: SendDestinationCompactViewModel?
    @Published private(set) var stakingTargetsCompactViewModel: StakingTargetsCompactViewModel?
    @Published private(set) var sendFeeCompactViewModel: SendNewFeeCompactViewModel?

    let destinationEditableType: Settings.EditableType
    let amountEditableType: Settings.EditableType

    @Published var notificationInputs: [NotificationViewInput] = []
    @Published var notificationButtonIsLoading = false

    @Published var transactionDescription: AttributedString?
    @Published var transactionDescriptionIsVisible: Bool = false

    private let interactor: SendSummaryInteractor
    private let notificationManager: NotificationManager
    private let analyticsLogger: SendSummaryAnalyticsLogger

    weak var router: SendSummaryStepsRoutable?

    private var bag: Set<AnyCancellable> = []

    init(
        interactor: SendSummaryInteractor,
        settings: Settings,
        notificationManager: NotificationManager,
        analyticsLogger: SendSummaryAnalyticsLogger,
        sendAmountCompactViewModel: SendAmountCompactViewModel?,
        nftAssetCompactViewModel: NFTAssetCompactViewModel?,
        sendDestinationCompactViewModel: SendDestinationCompactViewModel?,
        stakingTargetsCompactViewModel: StakingTargetsCompactViewModel?,
        sendFeeCompactViewModel: SendNewFeeCompactViewModel?
    ) {
        self.interactor = interactor
        destinationEditableType = settings.destinationEditableType
        amountEditableType = settings.amountEditableType
        self.notificationManager = notificationManager
        self.analyticsLogger = analyticsLogger
        self.sendAmountCompactViewModel = sendAmountCompactViewModel
        self.nftAssetCompactViewModel = nftAssetCompactViewModel
        self.sendDestinationCompactViewModel = sendDestinationCompactViewModel
        self.stakingTargetsCompactViewModel = stakingTargetsCompactViewModel
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
        analyticsLogger.logUserDidTapOnValidator()
        router?.summaryStepRequestEditValidators()
    }

    func userDidTapFee() {
        didTapSummary()
        router?.summaryStepRequestEditFee()
    }
}

// MARK: - SendAmountCompactRoutable

extension SendSummaryViewModel: SendAmountCompactRoutable {
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
        analyticsLogger.logUserDidTapOnProvider()
        router?.summaryStepRequestEditProviders()
    }
}

// MARK: - Private

private extension SendSummaryViewModel {
    func didTapSummary() {
        AppSettings.shared.userDidTapSendScreenSummary = true
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

extension SendSummaryViewModel {
    struct Settings {
        let destinationEditableType: EditableType
        let amountEditableType: EditableType

        enum EditableType: Hashable {
            case editable
            case noEditable

            var isEditable: Bool {
                switch self {
                case .editable: true
                case .noEditable: false
                }
            }
        }
    }
}
