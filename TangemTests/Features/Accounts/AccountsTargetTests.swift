//
//  AccountsTargetTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import Testing
@testable import Tangem

@Suite("Accounts targets")
struct AccountsTargetTests {
    @Test("The supported kinds of account are sent as one comma-separated parameter named by their wire values")
    func supportedAccountTypesAreJoinedWithCommas() throws {
        let urlParameters = AccountsDTO.Request.URLParameters(supportedAccountTypes: [.crypto, .joint, .collectibles])

        let encoded = try JSONSerialization.jsonObject(with: JSONEncoder().encode(urlParameters)) as? [String: String]

        #expect(encoded == ["supportedAccountTypes": "crypto,joint,collectibles"])
    }

    @Test(
        "While only the wallet's own accounts are supported, the accounts endpoints are asked as v1 and name no kinds",
        .enabled(if: !AccountsDTO.isV2Available)
    )
    func legacyEndpointsNameNoKinds() {
        #expect(supportedAccountTypes(in: Fixtures.getTarget.task) == nil)
        #expect(supportedAccountTypes(in: Fixtures.getArchivedTarget.task) == nil)
        #expect(supportedAccountTypes(in: Fixtures.saveTarget.task) == nil)
        #expect(hasBody(Fixtures.saveTarget.task))
    }

    @Test(
        "Once another kind of account is supported, the three accounts endpoints are asked with the kinds they were given",
        .enabled(if: AccountsDTO.isV2Available)
    )
    func typedEndpointsCarryTheGivenKinds() {
        #expect(supportedAccountTypes(in: Fixtures.getTarget.task) == "crypto,joint")
        #expect(supportedAccountTypes(in: Fixtures.getArchivedTarget.task) == "crypto,joint")
        #expect(supportedAccountTypes(in: Fixtures.saveTarget.task) == "crypto,joint")
        #expect(hasBody(Fixtures.saveTarget.task))
    }
}

// MARK: - Helpers

private extension AccountsTargetTests {
    func supportedAccountTypes(in task: Moya.Task) -> String? {
        switch task {
        case .requestParameters(let parameters, _):
            return parameters["supportedAccountTypes"] as? String
        case .requestCompositeParameters(_, _, let urlParameters):
            return urlParameters["supportedAccountTypes"] as? String
        default:
            return nil
        }
    }

    func hasBody(_ task: Moya.Task) -> Bool {
        switch task {
        case .requestJSONEncodable, .requestCompositeParameters:
            return true
        default:
            return false
        }
    }
}

// MARK: - Fixtures

private extension AccountsTargetTests {
    enum Fixtures {
        static let urlParameters = AccountsDTO.Request.URLParameters(supportedAccountTypes: [.crypto, .joint])
        static let getTarget = TangemApiTarget(type: .getUserAccounts(userWalletId: "wallet", urlParameters: urlParameters))
        static let getArchivedTarget = TangemApiTarget(type: .getArchivedUserAccounts(userWalletId: "wallet", urlParameters: urlParameters))
        static let saveTarget = TangemApiTarget(
            type: .saveUserAccounts(
                userWalletId: "wallet",
                urlParameters: urlParameters,
                revision: "etag",
                accounts: AccountsDTO.Request.Accounts(accounts: [])
            )
        )
    }
}
