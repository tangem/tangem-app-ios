//
//  TangemPayOrderStatusPollingService.swift
//  TangemPay
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

public final class TangemPayOrderStatusPollingService {
    private let customerService: TangemPayCustomerService

    private var orderStatusPollingTask: Task<Void, Never>?

    public init(customerService: TangemPayCustomerService) {
        self.customerService = customerService
    }

    public func startOrderStatusPolling(
        orderId: String,
        interval: TimeInterval,
        onCompleted: @escaping () -> Void,
        onCanceled: @escaping () -> Void,
        onFailed: @escaping (Error) -> Void
    ) {
        orderStatusPollingTask?.cancel()

        let polling = PollingSequence(
            interval: interval,
            request: { [customerService] in
                try await customerService.getOrder(orderId: orderId)
            }
        )

        orderStatusPollingTask = runTask {
            for await result in polling {
                switch result {
                case .success(let order):
                    switch order.status {
                    case .new, .processing:
                        break

                    case .completed:
                        onCompleted()
                        return

                    case .canceled:
                        onCanceled()
                        return
                    }

                case .failure(let error):
                    onFailed(error)
                    return
                }
            }
        }
    }

    public func cancel() {
        orderStatusPollingTask?.cancel()
    }

    deinit {
        orderStatusPollingTask?.cancel()
    }
}
