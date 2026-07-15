//
//  TangemPayOrderStatusPollingService.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

public final class TangemPayOrderStatusPollingService {
    private let customerService: CustomerInfoManagementService

    private var orderStatusPollingTask: Task<Void, Never>?

    public init(customerService: CustomerInfoManagementService) {
        self.customerService = customerService
    }

    public func startOrderStatusPolling(
        orderId: String,
        interval: TimeInterval,
        onCompleted: @escaping () -> Void,
        onCanceled: @escaping () -> Void,
        onFailed: @escaping (Error) -> Void,
        onProgress: ((TangemPayOrderResponse) -> Void)? = nil
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
                        onProgress?(order)
                        continue
                    case .completed:
                        onCompleted()
                        return
                    case .canceled:
                        onCanceled()
                        return
                    case .failed, .undefined:
                        onFailed(TangemPayOrderStatusPollingError.terminalStatus(order.status))
                        return
                    }
                case .failure:
                    continue
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

public enum TangemPayOrderStatusPollingError: Error {
    case terminalStatus(TangemPayOrderResponse.Status)
}
