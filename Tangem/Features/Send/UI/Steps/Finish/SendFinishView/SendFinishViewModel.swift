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
    var headerTitle: String {
        headerTitleProvider.title
    }

    @Published private(set) var showHeader = false
    @Published private(set) var transactionSentTime: String?
    @Published private(set) var transactionURL: URL?

    // Send

    @Published private(set) var sendAmountFinishViewModel: SendAmountFinishViewModel?
    @Published private(set) var nftAssetCompactViewModel: NFTAssetCompactViewModel?
    @Published private(set) var sendDestinationCompactViewModel: SendDestinationCompactViewModel?
    @Published private(set) var addContactViewModel: SendAddContactFinishViewModel?
    @Published private(set) var stakingTargetsCompactViewModel: StakingTargetsCompactViewModel?
    @Published private(set) var sendFeeFinishViewModel: SendFeeFinishViewModel?
    @Published private(set) var jointAccountSignaturesCompactViewModel: JointAccountSignaturesCompactViewModel?

    // Staking

    @Published private(set) var onrampAmountCompactViewModel: OnrampAmountCompactViewModel?
    @Published private(set) var onrampStatusCompactViewModel: OnrampStatusCompactViewModel?

    private let headerTitleProvider: any SendFinishHeaderTitleProvider
    private let analyticsLogger: SendFinishAnalyticsLogger

    private weak var coordinator: SendRoutable?

    init(
        input: SendFinishInput,
        sendAmountFinishViewModel: SendAmountFinishViewModel?,
        nftAssetCompactViewModel: NFTAssetCompactViewModel?,
        sendDestinationCompactViewModel: SendDestinationCompactViewModel?,
        addContactViewModel: SendAddContactFinishViewModel?,
        stakingTargetsCompactViewModel: StakingTargetsCompactViewModel?,
        sendFeeFinishViewModel: SendFeeFinishViewModel?,
        onrampAmountCompactViewModel: OnrampAmountCompactViewModel?,
        onrampStatusCompactViewModel: OnrampStatusCompactViewModel?,
        jointAccountSignaturesCompactViewModel: JointAccountSignaturesCompactViewModel?,
        headerTitleProvider: any SendFinishHeaderTitleProvider,
        analyticsLogger: SendFinishAnalyticsLogger,
        coordinator: SendRoutable
    ) {
        self.sendAmountFinishViewModel = sendAmountFinishViewModel
        self.nftAssetCompactViewModel = nftAssetCompactViewModel
        self.sendDestinationCompactViewModel = sendDestinationCompactViewModel
        self.addContactViewModel = addContactViewModel
        self.stakingTargetsCompactViewModel = stakingTargetsCompactViewModel
        self.sendFeeFinishViewModel = sendFeeFinishViewModel
        self.onrampAmountCompactViewModel = onrampAmountCompactViewModel
        self.onrampStatusCompactViewModel = onrampStatusCompactViewModel
        self.jointAccountSignaturesCompactViewModel = jointAccountSignaturesCompactViewModel
        self.headerTitleProvider = headerTitleProvider
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

        input
            .transactionURL
            .receiveOnMain()
            .assign(to: &$transactionURL)
    }
}
