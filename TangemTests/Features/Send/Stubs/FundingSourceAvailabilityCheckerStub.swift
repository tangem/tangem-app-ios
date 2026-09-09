//
//  FundingSourceAvailabilityCheckerStub.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

@testable import Tangem

struct FundingSourceAvailabilityCheckerStub: FundingSourceAvailabilityChecker {
    var transferAvailable: Set<WalletModelId> = []
    var swapAvailable: Set<WalletModelId> = []

    func isTransferAvailable(walletModel: any WalletModel) -> Bool {
        transferAvailable.contains(walletModel.id)
    }

    func isSwapAvailable(walletModel: any WalletModel) -> Bool {
        swapAvailable.contains(walletModel.id)
    }
}
