//
//  SwapConfirmTransactionPolicy.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import TangemFoundation

final class SwapConfirmTransactionPolicy: ConfirmTransactionPolicy {
    private(set) var needsHoldToConfirm: Bool = false

    private var bag: Set<AnyCancellable> = []

    init(sourceTokenInput: any SendSourceTokenInput) {
        sourceTokenInput.sourceTokenPublisher
            .compactMap { $0.value }
            .map { $0.confirmTransactionPolicy.needsHoldToConfirm }
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { $0.needsHoldToConfirm = $1 }
            .store(in: &bag)
    }
}
