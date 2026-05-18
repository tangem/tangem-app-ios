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
        onCompleted: @MainActor @escaping () -> Void,
        onCanceled: @MainActor @escaping () -> Void,
        onFailed: @MainActor @escaping (Error) -> Void,
        onProgress: (@MainActor @escaping (TangemPayOrderResponse) -> Void)? = nil
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
                        if let onProgress {
                            await onProgress(order)
                        }
                        continue
                    case .completed:
                        await onCompleted()
                        return
                    case .canceled:
                        await onCanceled()
                        return
                    case .failed, .undefined:
                        await onFailed(TangemPayOrderStatusPollingError.terminalStatus(order.status))
                        return
                    }
                case .failure:
                    continue
                }
            }
            // End-of-loop reached only via external Task.cancel() (PollingSequence returns nil
            // when canceled). Stay silent here — fires no callback. Callers that issue cancel()
            // are responsible for any cleanup that the cancelled poll would have driven, so a
            // cancel-previous-on-start from a re-entrant `startOrderStatusPolling` doesn't fire
            // a stale `onCanceled` that the predecessor's caller didn't ask for.
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
