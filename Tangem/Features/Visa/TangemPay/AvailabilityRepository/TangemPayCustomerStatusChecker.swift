//
//  TangemPayCustomerStatusChecker.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemFoundation
import TangemPay

actor TangemPayCustomerStatusChecker {
    private let availabilityService: TangemPayAvailabilityService
    private var inFlightChecks: [String: Task<Bool, Never>] = [:]
    private var lastResults: [String: Bool] = [:]

    init(availabilityService: TangemPayAvailabilityService = TangemPayAvailabilityServiceBuilder().build()) {
        self.availabilityService = availabilityService
    }

    func checkIsPaeraCustomer(customerWalletId: String) async -> Bool {
        if let inFlightCheck = inFlightChecks[customerWalletId] {
            return await inFlightCheck.value
        }

        let check = Task {
            await availabilityService.isPaeraCustomer(customerWalletId: customerWalletId)
        }

        inFlightChecks[customerWalletId] = check

        let isPaeraCustomer = await check.value
        inFlightChecks[customerWalletId] = nil
        lastResults[customerWalletId] = isPaeraCustomer

        return isPaeraCustomer
    }

    func paeraCustomerStatus(customerWalletId: String) async -> Bool {
        if inFlightChecks[customerWalletId] == nil, let lastResult = lastResults[customerWalletId] {
            return lastResult
        }

        return await checkIsPaeraCustomer(customerWalletId: customerWalletId)
    }
}

// MARK: - Dependency injection

private struct TangemPayCustomerStatusCheckerKey: InjectionKey {
    static var currentValue = TangemPayCustomerStatusChecker()
}

extension InjectedValues {
    var tangemPayCustomerStatusChecker: TangemPayCustomerStatusChecker {
        get { Self[TangemPayCustomerStatusCheckerKey.self] }
        set { Self[TangemPayCustomerStatusCheckerKey.self] = newValue }
    }
}
