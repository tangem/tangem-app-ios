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

    @Published private(set) var sendAmountCompactViewModel: SendTokenAmountCompactViewModel?
    @Published private(set) var sendDestinationCompactViewModel: SendNewDestinationCompactViewModel?
    @Published private(set) var sendSwapProviderFinishViewModel: SendSwapProviderFinishViewModel?
    @Published private(set) var sendFeeCompactViewModel: SendFeeCompactViewModel?

    private var sendFinishAnalyticsLogger: SendFinishAnalyticsLogger

    init(
        input: SendFinishInput,
        sendFinishAnalyticsLogger: SendFinishAnalyticsLogger,
        sendAmountCompactViewModel: SendTokenAmountCompactViewModel?,
        sendDestinationCompactViewModel: SendNewDestinationCompactViewModel?,
        sendSwapProviderFinishViewModel: SendSwapProviderFinishViewModel?,
        sendFeeCompactViewModel: SendFeeCompactViewModel?
    ) {
        self.sendFinishAnalyticsLogger = sendFinishAnalyticsLogger
        self.sendAmountCompactViewModel = sendAmountCompactViewModel
        self.sendDestinationCompactViewModel = sendDestinationCompactViewModel
        self.sendSwapProviderFinishViewModel = sendSwapProviderFinishViewModel
        self.sendFeeCompactViewModel = sendFeeCompactViewModel

        bind(input: input)
    }

    func onAppear() {
        sendFinishAnalyticsLogger.onAppear()

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
