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
    @Published var transactionSentTime: String?
    @Published var transactionURL: URL?

    @Published var sendAmountCompactViewModel: SendAmountCompactViewModel?
    @Published var onrampAmountCompactViewModel: OnrampAmountCompactViewModel?
    @Published var stakingValidatorsCompactViewModel: StakingValidatorsCompactViewModel?
    @Published var sendFeeCompactViewModel: SendFeeCompactViewModel?
    @Published var onrampStatusCompactViewModel: OnrampStatusCompactViewModel?

    private let tokenItem: TokenItem
    private let sendFinishAnalyticsLogger: SendFinishAnalyticsLogger
    private weak var coordinator: SendRoutable?

    private var bag: Set<AnyCancellable> = []

    init(
        input: SendFinishInput,
        tokenItem: TokenItem,
        sendFinishAnalyticsLogger: SendFinishAnalyticsLogger,
        sendAmountCompactViewModel: SendAmountCompactViewModel?,
        onrampAmountCompactViewModel: OnrampAmountCompactViewModel?,
        stakingValidatorsCompactViewModel: StakingValidatorsCompactViewModel?,
        sendFeeCompactViewModel: SendFeeCompactViewModel?,
        onrampStatusCompactViewModel: OnrampStatusCompactViewModel?,
        coordinator: SendRoutable
    ) {
        self.tokenItem = tokenItem
        self.sendFinishAnalyticsLogger = sendFinishAnalyticsLogger
        self.sendAmountCompactViewModel = sendAmountCompactViewModel
        self.onrampAmountCompactViewModel = onrampAmountCompactViewModel
        self.stakingValidatorsCompactViewModel = stakingValidatorsCompactViewModel
        self.sendFeeCompactViewModel = sendFeeCompactViewModel
        self.onrampStatusCompactViewModel = onrampStatusCompactViewModel
        self.coordinator = coordinator

        bind(input: input)
    }

    func onAppear() {
        sendFinishAnalyticsLogger.logFinishStepOpened()

        withAnimation(SendTransitions.animation) {
            showHeader = true
        }
    }

    func share(url: URL) {
        sendFinishAnalyticsLogger.logShareButton()
        coordinator?.openShareSheet(url: url)
    }

    func explore(url: URL) {
        sendFinishAnalyticsLogger.logExploreButton()
        coordinator?.openExplorer(url: url)
    }

    private func bind(input: SendFinishInput) {
        input.transactionSentDate
            .map { date in
                let formatter = DateFormatter()
                formatter.dateStyle = .long
                formatter.timeStyle = .short
                return formatter.string(from: date)
            }
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] time in
                withAnimation(SendTransitions.animation) {
                    self?.transactionSentTime = time
                }
            })
            .store(in: &bag)

        guard !tokenItem.blockchain.isTransactionAsync else {
            return
        }

        input
            .transactionURL
            .receiveOnMain()
            .assign(to: &$transactionURL)
    }
}

// MARK: - SendStepViewAnimatable

extension SendFinishViewModel: SendStepViewAnimatable {
    func viewDidChangeVisibilityState(_ state: SendStepVisibilityState) {}
}
