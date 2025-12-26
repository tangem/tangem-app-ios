//
//  TangemPayOrderStatusPollingService.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemFoundation
import TangemVisa

final class TangemPayOrderStatusPollingService {
    private let customerInfoManagementService: CustomerInfoManagementService

    private var orderStatusPollingTask: Task<Void, Never>?

    init(customerInfoManagementService: CustomerInfoManagementService) {
        self.customerInfoManagementService = customerInfoManagementService
    }

    func startOrderStatusPolling(
        orderId: String,
        interval: TimeInterval,
        onCompleted: @escaping () -> Void,
        onCanceled: @escaping () -> Void,
        onFailed: @escaping (Error) -> Void
    ) {
        orderStatusPollingTask?.cancel()

        let polling = PollingSequence(
            interval: interval,
            request: { [customerInfoManagementService] in
                try await customerInfoManagementService.getOrder(orderId: orderId)
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

    func cancel() {
        orderStatusPollingTask?.cancel()
    }

    deinit {
        orderStatusPollingTask?.cancel()
    }
}
