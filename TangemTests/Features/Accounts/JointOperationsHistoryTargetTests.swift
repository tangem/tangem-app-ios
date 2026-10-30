//
//  JointOperationsHistoryTargetTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import Testing
@testable import Tangem

@Suite("Joint operations history targets")
struct JointOperationsHistoryTargetTests {
    @Test("The first page of the history asks for nothing but the page size")
    func firstHistoryPageSendsNoCursor() throws {
        let target = TangemApiTarget(type: .getJointOperationsHistory(walletId: "wallet", request: .init(afterCursor: nil, limit: 100)))

        let parameters = try queryParameters(target.task)

        #expect(parameters.keys.sorted() == ["limit"])
        #expect(parameters["limit"] as? Int == 100)
        #expect(target.path == "/wallets/wallet/joint-accounts/operations/history")
        #expect(target.method == .get)
    }

    @Test("A later page of the history carries the cursor it continues from")
    func laterHistoryPageSendsItsCursor() throws {
        let target = TangemApiTarget(type: .getJointOperationsHistory(walletId: "wallet", request: .init(afterCursor: "cursor", limit: 100)))

        let parameters = try queryParameters(target.task)

        #expect(parameters.keys.sorted() == ["afterCursor", "limit"])
        #expect(parameters["afterCursor"] as? String == "cursor")
    }

    @Test("The delta is read from its own cursor")
    func deltaSendsItsCursor() throws {
        let target = TangemApiTarget(type: .getJointOperationsHistoryDelta(walletId: "wallet", request: .init(beforeCursor: "cursor", limit: 100)))

        let parameters = try queryParameters(target.task)

        #expect(parameters.keys.sorted() == ["beforeCursor", "limit"])
        #expect(parameters["beforeCursor"] as? String == "cursor")
        #expect(target.path == "/wallets/wallet/joint-accounts/operations/history/delta")
        #expect(target.method == .get)
    }

    @Test(
        "A single operation is asked for with the tag it was last seen under, and without one the first time",
        arguments: [nil, "tag"] as [String?]
    )
    func singleOperationSendsIfNoneMatch(knownETag: String?) {
        let target = TangemApiTarget(type: .getJointOperation(walletId: "wallet", operationId: "operation", knownETag: knownETag))

        #expect(target.headers == knownETag.map { ["If-None-Match": $0] })
        #expect(target.path == "/wallets/wallet/joint-accounts/operations/operation")
        #expect(target.method == .get)

        guard case .requestPlain = target.task else {
            Issue.record("Expected a plain request, got \(target.task)")
            return
        }
    }

    @Test("None of the three reads is answered from the URL cache")
    func readsBypassTheCache() {
        let targets = [
            TangemApiTarget(type: .getJointOperationsHistory(walletId: "wallet", request: .init(afterCursor: nil, limit: 100))),
            TangemApiTarget(type: .getJointOperationsHistoryDelta(walletId: "wallet", request: .init(beforeCursor: nil, limit: 100))),
            TangemApiTarget(type: .getJointOperation(walletId: "wallet", operationId: "operation", knownETag: nil)),
        ]

        #expect(targets.allSatisfy { $0.cachePolicy == .reloadIgnoringLocalAndRemoteCacheData })
        #expect(targets.allSatisfy { !$0.shouldLogResponseBody })
    }

    @Test("None of the three reads puts the wallet id into what is logged and reported about the request")
    func requestDescriptionsHideTheWalletId() {
        let walletId = "0123456789abcdef"
        let targets = [
            TangemApiTarget(type: .getJointOperationsHistory(walletId: walletId, request: .init(afterCursor: nil, limit: 100))),
            TangemApiTarget(type: .getJointOperationsHistoryDelta(walletId: walletId, request: .init(beforeCursor: nil, limit: 100))),
            TangemApiTarget(type: .getJointOperation(walletId: walletId, operationId: "operation", knownETag: nil)),
        ]

        #expect(targets.map(\.requestDescription) == [
            "/wallets/{walletId}/joint-accounts/operations/history",
            "/wallets/{walletId}/joint-accounts/operations/history/delta",
            "/wallets/{walletId}/joint-accounts/operations/operation",
        ])
        #expect(targets.allSatisfy { $0.path.contains(walletId) })
    }
}

// MARK: - Private

private extension JointOperationsHistoryTargetTests {
    enum TestError: Error {
        case notRequestParameters
    }

    func queryParameters(_ task: Moya.Task) throws -> [String: Any] {
        guard case .requestParameters(let parameters, _) = task else {
            throw TestError.notRequestParameters
        }

        return parameters
    }
}
