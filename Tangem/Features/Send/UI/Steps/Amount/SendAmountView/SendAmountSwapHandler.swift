//
//  SendAmountSwapHandler.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

protocol SendAmountSwapHandler: AnyObject {
    // MARK: - State queries

    var lastUpdateSource: ActiveAmountField? { get }
    var sourceRateBadge: RateBadgeConfig? { get }
    var destinationRateBadge: RateBadgeConfig? { get }
    var isReceiveAmountApproximatePublisher: AnyPublisher<Bool, Never> { get }

    // MARK: - Lifecycle

    func bind(to viewModel: SendAmountViewModel)

    // MARK: - User actions

    func userDidTapCompactField(_ field: ActiveAmountField)
    func userDidTapReceivedTokenSelection()
    func removeReceivedToken()

    // MARK: - Data updates

    func sourceTextFieldValueDidChange(amount: Decimal?)
    func handleExternalSourceAmount(_ result: LoadingResult<SendAmount, Error>)
    func updateDestinationToken(token: (any SendReceiveToken)?, amount: LoadingResult<SendAmount, Error>)

    // MARK: - Field queries

    func amountField(for field: ActiveAmountField) -> AmountInputFieldModel
    func isFiatMode(for field: ActiveAmountField) -> Bool
}
