//
//  TangemPayDepositAddressPollingService.swift
//  TangemModules
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

public final class TangemPayDepositAddressPollingService {
    public enum Constants {
        public static let depositAddressPollInterval: TimeInterval = 5
    }

    private let customerService: CustomerInfoManagementService

    private var pollingTask: Task<Void, Never>?

    public init(customerService: CustomerInfoManagementService) {
        self.customerService = customerService
    }

    public func startPolling(
        interval: TimeInterval = TangemPayDepositAddressPollingService.Constants.depositAddressPollInterval,
        onCompleted: @escaping (VisaCustomerInfoResponse) -> Void
    ) {
        pollingTask?.cancel()

        let polling = PollingSequence(
            interval: interval,
            request: { [customerService] in
                try await customerService.loadCustomerInfo()
            }
        )

        pollingTask = runTask {
            for await result in polling {
                switch result {
                case .success(let customerInfo):
                    guard let depositAddress = customerInfo.depositAddress, !depositAddress.isEmpty else {
                        continue
                    }

                    onCompleted(customerInfo)
                    return
                case .failure:
                    continue
                }
            }
        }
    }

    public func cancel() {
        pollingTask?.cancel()
    }

    deinit {
        pollingTask?.cancel()
    }
}
