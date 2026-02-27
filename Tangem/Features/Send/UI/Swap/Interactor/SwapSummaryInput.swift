//
//  SwapSummaryInput.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine

protocol SwapSummaryInput: AnyObject {
    var isMaxAmountButtonHiddenPublisher: AnyPublisher<Bool, Never> { get }
    var isUpdatingPublisher: AnyPublisher<Bool, Never> { get }
    var isReadyToSendPublisher: AnyPublisher<Bool, Never> { get }
    var isNotificationButtonIsLoading: AnyPublisher<Bool, Never> { get }

    var summaryTransactionDataPublisher: AnyPublisher<SendSummaryTransactionData?, Never> { get }
}

protocol SwapSummaryOutput: AnyObject {
    func userDidRequestSwapSourceAndReceiveToken()
    func userDidRequestMaxAmount()
    func userDidRequestSwap()
}
