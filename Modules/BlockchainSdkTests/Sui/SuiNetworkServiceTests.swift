//
//  SuiNetworkServiceTests.swift
//  BlockchainSdkTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import GRPC
import Testing
@testable import BlockchainSdk

@Suite("SuiNetworkService")
struct SuiNetworkServiceTests {
    private let service = SuiNetworkService(providers: [])

    @Test(arguments: [
        GRPCStatus.Code.unavailable,
        .deadlineExceeded,
        .unauthenticated,
        .internalError,
    ])
    func switchesProviderOnRetryableStatus(code: GRPCStatus.Code) {
        #expect(!service.shouldStopSwitching(error: GRPCStatus(code: code, message: nil)))
    }

    @Test(arguments: [
        GRPCStatus.Code.invalidArgument,
        .notFound,
        .failedPrecondition,
        .alreadyExists,
    ])
    func stopsSwitchingOnRequestStatus(code: GRPCStatus.Code) {
        #expect(service.shouldStopSwitching(error: GRPCStatus(code: code, message: nil)))
    }

    @Test
    func switchesProviderOnNonGRPCError() {
        #expect(!service.shouldStopSwitching(error: BlockchainSdkError.failedToParseNetworkResponse()))
    }
}
