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

    @Published private(set) var sendAmountFinishViewModel: SendNewAmountFinishViewModel?
    @Published private(set) var nftAssetCompactViewModel: NFTAssetCompactViewModel?
    @Published private(set) var sendDestinationCompactViewModel: SendNewDestinationCompactViewModel?
    @Published private(set) var sendFeeFinishViewModel: SendFeeFinishViewModel?

    private var sendFinishAnalyticsLogger: SendFinishAnalyticsLogger

    init(
        input: SendFinishInput,
        sendAmountFinishViewModel: SendNewAmountFinishViewModel?,
        nftAssetCompactViewModel: NFTAssetCompactViewModel?,
        sendDestinationCompactViewModel: SendNewDestinationCompactViewModel?,
        sendFeeFinishViewModel: SendFeeFinishViewModel?,
        sendFinishAnalyticsLogger: SendFinishAnalyticsLogger,
    ) {
        self.sendAmountFinishViewModel = sendAmountFinishViewModel
        self.nftAssetCompactViewModel = nftAssetCompactViewModel
        self.sendDestinationCompactViewModel = sendDestinationCompactViewModel
        self.sendFeeFinishViewModel = sendFeeFinishViewModel
        self.sendFinishAnalyticsLogger = sendFinishAnalyticsLogger

        bind(input: input)
    }

    func onAppear() {
        sendFinishAnalyticsLogger.logFinishStepOpened()

        withAnimation(SendTransitionService.Constants.newAnimation) {
            showHeader = true
        }
    }

    func bind(input: SendFinishInput) {
        input.transactionSentDate
            .map { date in
                let formatter = DateFormatter()
                formatter.dateStyle = .long
                formatter.timeStyle = .short
                return formatter.string(from: date)
            }
            .receiveOnMain()
            .assign(to: &$transactionSentTime)
    }
}

// MARK: - SendStepViewAnimatable

extension SendNewFinishViewModel: SendStepViewAnimatable {
    func viewDidChangeVisibilityState(_ state: SendStepVisibilityState) {}
}
