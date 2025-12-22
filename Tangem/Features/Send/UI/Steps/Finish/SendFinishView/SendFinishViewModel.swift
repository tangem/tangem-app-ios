//
//  SendFinishViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import Combine
import struct TangemUIUtils.AlertBinder

class SendFinishViewModel: ObservableObject, Identifiable {
    @Published private(set) var showHeader = false
    @Published private(set) var transactionSentTime: String?
    @Published private(set) var transactionURL: URL?

    // Send

    @Published private(set) var sendAmountFinishViewModel: SendAmountFinishViewModel?
    @Published private(set) var nftAssetCompactViewModel: NFTAssetCompactViewModel?
    @Published private(set) var sendDestinationCompactViewModel: SendDestinationCompactViewModel?
    @Published private(set) var stakingTargetsCompactViewModel: StakingTargetsCompactViewModel?
    @Published private(set) var sendFeeFinishViewModel: SendFeeFinishViewModel?

    // Staking

    @Published private(set) var onrampAmountCompactViewModel: OnrampAmountCompactViewModel?
    @Published private(set) var onrampStatusCompactViewModel: OnrampStatusCompactViewModel?

    private let settings: Settings
    private let analyticsLogger: SendFinishAnalyticsLogger

    private weak var coordinator: SendRoutable?

    init(
        input: SendFinishInput,
        sendAmountFinishViewModel: SendAmountFinishViewModel?,
        nftAssetCompactViewModel: NFTAssetCompactViewModel?,
        sendDestinationCompactViewModel: SendDestinationCompactViewModel?,
        stakingTargetsCompactViewModel: StakingTargetsCompactViewModel?,
        sendFeeFinishViewModel: SendFeeFinishViewModel?,
        onrampAmountCompactViewModel: OnrampAmountCompactViewModel?,
        onrampStatusCompactViewModel: OnrampStatusCompactViewModel?,
        settings: Settings,
        analyticsLogger: SendFinishAnalyticsLogger,
        coordinator: SendRoutable
    ) {
        self.sendAmountFinishViewModel = sendAmountFinishViewModel
        self.nftAssetCompactViewModel = nftAssetCompactViewModel
        self.sendDestinationCompactViewModel = sendDestinationCompactViewModel
        self.stakingTargetsCompactViewModel = stakingTargetsCompactViewModel
        self.sendFeeFinishViewModel = sendFeeFinishViewModel
        self.onrampAmountCompactViewModel = onrampAmountCompactViewModel
        self.onrampStatusCompactViewModel = onrampStatusCompactViewModel
        self.settings = settings
        self.analyticsLogger = analyticsLogger
        self.coordinator = coordinator

        bind(input: input)
    }

    func onAppear() {
        analyticsLogger.logFinishStepOpened()

        withAnimation(SendTransitions.animation) {
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

    private func bind(input: SendFinishInput) {
        input.transactionSentDate
            .removeDuplicates()
            .map { date in
                let formatter = DateFormatter()
                formatter.dateStyle = .long
                formatter.timeStyle = .short
                return formatter.string(from: date)
            }
            .receiveOnMain()
            .assign(to: &$transactionSentTime)

        guard settings.possibleToShowExploreButtons else {
            return
        }

        input
            .transactionURL
            .receiveOnMain()
            .assign(to: &$transactionURL)
    }
}

extension SendFinishViewModel {
    struct Settings {
        let title: String
        let possibleToShowExploreButtons: Bool
    }
}
