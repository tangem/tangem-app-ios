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

class SendFinishViewModel: ObservableObject, Identifiable {
    @Published var showHeader = false
    @Published var transactionSentTime: String?
    @Published var alert: AlertBinder?

    @Published var sendDestinationCompactViewModel: SendDestinationCompactViewModel?
    @Published var sendAmountCompactViewModel: SendAmountCompactViewModel?
    @Published var stakingValidatorsCompactViewModel: StakingValidatorsCompactViewModel?
    @Published var sendFeeCompactViewModel: SendFeeCompactViewModel?

    private let actionType: SendFlowActionType
    private let tokenItem: TokenItem
    private var feeTypeAnalyticsParameter: Analytics.ParameterValue = .null
    private var bag: Set<AnyCancellable> = []

    init(
        settings: Settings,
        input: SendFinishInput,
        sendDestinationCompactViewModel: SendDestinationCompactViewModel?,
        sendAmountCompactViewModel: SendAmountCompactViewModel?,
        stakingValidatorsCompactViewModel: StakingValidatorsCompactViewModel?,
        sendFeeCompactViewModel: SendFeeCompactViewModel?
    ) {
        tokenItem = settings.tokenItem
        actionType = settings.actionType
        self.sendDestinationCompactViewModel = sendDestinationCompactViewModel
        self.sendAmountCompactViewModel = sendAmountCompactViewModel
        self.stakingValidatorsCompactViewModel = stakingValidatorsCompactViewModel
        self.sendFeeCompactViewModel = sendFeeCompactViewModel

        bind(input: input)
    }

    func onAppear() {
        if let stakingAnalyticsAction = actionType.stakingAnalyticsAction {
            Analytics.log(event: .stakingStakeInProgressScreenOpened, params: [
                .validator: stakingValidatorsCompactViewModel?.selectedValidator?.name ?? "",
                .token: tokenItem.currencySymbol,
                .action: stakingAnalyticsAction.rawValue,
            ])
        } else {
            Analytics.log(event: .sendTransactionSentScreenOpened, params: [
                .token: tokenItem.currencySymbol,
                .feeType: feeTypeAnalyticsParameter.rawValue,
            ])
        }

        withAnimation(SendTransitionService.Constants.defaultAnimation) {
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
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] time in
                withAnimation(SendTransitionService.Constants.defaultAnimation) {
                    self?.transactionSentTime = time
                }
            })
            .store(in: &bag)
    }
}

// MARK: - SendStepViewAnimatable

extension SendFinishViewModel: SendStepViewAnimatable {
    func viewDidChangeVisibilityState(_ state: SendStepVisibilityState) {}
}

extension SendFinishViewModel {
    struct Settings {
        let tokenItem: TokenItem
        let actionType: SendFlowActionType
    }
}
