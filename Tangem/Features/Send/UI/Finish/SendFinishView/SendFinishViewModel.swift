//
//  SendFinishViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import Combine
import struct TangemUIUtils.AlertBinder

class SendFinishViewModel: ObservableObject, Identifiable {
    @Published var showHeader = false
    @Published var transactionURL: URL?
    @Published var transactionSentTime: String?

    @Published var sendDestinationCompactViewModel: SendDestinationCompactViewModel?
    @Published var sendAmountCompactViewModel: SendAmountCompactViewModel?
    @Published var onrampAmountCompactViewModel: OnrampAmountCompactViewModel?
    @Published var stakingValidatorsCompactViewModel: StakingValidatorsCompactViewModel?
    @Published var sendFeeCompactViewModel: SendFeeCompactViewModel?
    @Published var onrampStatusCompactViewModel: OnrampStatusCompactViewModel?

    private weak var coordinator: SendFinishRoutable?
    private let analyticsLogger: SendFinishAnalyticsLogger
    private var bag: Set<AnyCancellable> = []

    init(
        input: SendFinishInput,
        coordinator: SendFinishRoutable,
        analyticsLogger: SendFinishAnalyticsLogger,
        sendDestinationCompactViewModel: SendDestinationCompactViewModel?,
        sendAmountCompactViewModel: SendAmountCompactViewModel?,
        onrampAmountCompactViewModel: OnrampAmountCompactViewModel?,
        stakingValidatorsCompactViewModel: StakingValidatorsCompactViewModel?,
        sendFeeCompactViewModel: SendFeeCompactViewModel?,
        onrampStatusCompactViewModel: OnrampStatusCompactViewModel?
    ) {
        self.coordinator = coordinator
        self.analyticsLogger = analyticsLogger
        self.sendDestinationCompactViewModel = sendDestinationCompactViewModel
        self.sendAmountCompactViewModel = sendAmountCompactViewModel
        self.onrampAmountCompactViewModel = onrampAmountCompactViewModel
        self.stakingValidatorsCompactViewModel = stakingValidatorsCompactViewModel
        self.sendFeeCompactViewModel = sendFeeCompactViewModel
        self.onrampStatusCompactViewModel = onrampStatusCompactViewModel

        bind(input: input)
    }

    func onAppear() {
        analyticsLogger.logFinishStepOpened()

        withAnimation(SendTransitionService.Constants.defaultAnimation) {
            showHeader = true
        }
    }

    func share(url: URL) {
        analyticsLogger.logShareButton()
        coordinator?.openShareSheet(url: url)
    }

    func explore(url: URL) {
        analyticsLogger.logExploreButton()
        coordinator?.openExplorer(url: url)
    }

    func bind(input: SendFinishInput) {
        input.transactionSentDate
            .map { date in
                let formatter = DateFormatter()
                formatter.dateStyle = .long
                formatter.timeStyle = .short
                return formatter.string(from: date)
            }
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] time in
                withAnimation(SendTransitionService.Constants.defaultAnimation) {
                    self?.transactionSentTime = time
                }
            })
            .store(in: &bag)

        input.transactionExplorerURL
            .receiveOnMain()
            .assign(to: &$transactionURL)
    }
}

// MARK: - SendStepViewAnimatable

extension SendFinishViewModel: SendStepViewAnimatable {
    func viewDidChangeVisibilityState(_ state: SendStepVisibilityState) {}
}
