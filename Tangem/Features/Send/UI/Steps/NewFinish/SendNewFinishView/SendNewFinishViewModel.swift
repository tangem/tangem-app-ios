//
//  SendNewFinishViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import Combine
import struct TangemUIUtils.AlertBinder

class SendNewFinishViewModel: ObservableObject, Identifiable {
    @Published var showHeader = false
    @Published var transactionSentTime: String?
    @Published private(set) var transactionURL: URL?

    @Published private(set) var sendAmountFinishViewModel: SendNewAmountFinishViewModel?
    @Published private(set) var nftAssetCompactViewModel: NFTAssetCompactViewModel?
    @Published private(set) var sendDestinationCompactViewModel: SendDestinationCompactViewModel?
    @Published private(set) var sendFeeFinishViewModel: SendFeeFinishViewModel?

    private let sendFinishAnalyticsLogger: SendFinishAnalyticsLogger
    private let tokenItem: TokenItem

    private weak var coordinator: SendRoutable?

    init(
        input: SendFinishInput,
        sendAmountFinishViewModel: SendNewAmountFinishViewModel?,
        nftAssetCompactViewModel: NFTAssetCompactViewModel?,
        sendDestinationCompactViewModel: SendDestinationCompactViewModel?,
        sendFeeFinishViewModel: SendFeeFinishViewModel?,
        sendFinishAnalyticsLogger: SendFinishAnalyticsLogger,
        tokenItem: TokenItem,
        coordinator: SendRoutable
    ) {
        self.sendAmountFinishViewModel = sendAmountFinishViewModel
        self.nftAssetCompactViewModel = nftAssetCompactViewModel
        self.sendDestinationCompactViewModel = sendDestinationCompactViewModel
        self.sendFeeFinishViewModel = sendFeeFinishViewModel
        self.sendFinishAnalyticsLogger = sendFinishAnalyticsLogger
        self.tokenItem = tokenItem
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
            .receiveOnMain()
            .assign(to: &$transactionSentTime)

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

extension SendNewFinishViewModel: SendStepViewAnimatable {
    func viewDidChangeVisibilityState(_ state: SendStepVisibilityState) {}
}
