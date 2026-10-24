//
//  StakeKitUnknownActionTypeTests.swift
//  TangemStakingTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import TangemStaking

@Suite("StakeKit unknown action types")
struct StakeKitUnknownActionTypeTests {
    typealias SUT = StakeKitMapper

    @Test(
        "A raw action type the app does not know decodes to .unknown instead of failing",
        arguments: ["MERGE_V2", "SOME_FUTURE_ACTION", "", "withdraw"]
    )
    func unknownRawValueDecodesToUnknown(raw: String) throws {
        let decoded: StakeKitDTO.Actions.ActionType = try decodeActionType(from: raw)

        #expect(decoded == StakeKitDTO.Actions.ActionType.unknown)
    }

    @Test("Known raw action types still decode to their own case")
    func knownRawValuesKeepDecoding() throws {
        let withdraw: StakeKitDTO.Actions.ActionType = try decodeActionType(from: "WITHDRAW")
        let merge: StakeKitDTO.Actions.ActionType = try decodeActionType(from: "MERGE")

        #expect(withdraw == StakeKitDTO.Actions.ActionType.withdraw)
        #expect(merge == StakeKitDTO.Actions.ActionType.merge)
    }

    @Test("A balance keeps its supported action when MERGE and an unknown type sit next to it")
    func balanceKeepsSupportedActionAmongUnsupportedOnes() throws {
        let balances = try SUT().mapToBalanceInfo(from: decodeBalances(Self.balanceWithMixedActionsJSON))

        let balance = try #require(balances.first)
        #expect(balances.count == 1)
        #expect(balance.amount == Decimal(string: "7.473894246"))
        #expect(balance.actions == [StakingPendingActionInfo(type: .withdraw, passthrough: "passthrough-withdraw")])
    }

    @Test("A balance constraint list drops unsupported types and keeps the rest")
    func balanceConstraintsDropUnsupportedTypes() throws {
        let balances = try SUT().mapToBalanceInfo(from: decodeBalances(Self.balanceWithMixedActionsJSON))

        let balance = try #require(balances.first)
        #expect(
            balance.actionConstraints == [
                StakingPendingActionConstraint(type: .unstake, amount: .init(minimum: 1, maximum: 10)),
            ]
        )
    }

    @Test("A balance offering nothing but unsupported actions is still reported")
    func balanceWithOnlyUnsupportedActionsSurvives() throws {
        let balances = try SUT().mapToBalanceInfo(from: decodeBalances(Self.balanceWithOnlyMergeJSON))

        let balance = try #require(balances.first)
        #expect(balance.amount == Decimal(string: "7.473894246"))
        #expect(balance.actions.isEmpty)
    }

    @Test("A balance of a type the app does not know is dropped and the rest are kept")
    func balanceOfUnknownTypeIsDropped() throws {
        let response = try decodeBalances(Self.balancesWithUnknownTypeJSON)

        let balances = try SUT().mapToBalanceInfo(from: response)

        #expect(response.first?.balances.map(\.type) == [.staked, .unknown])
        #expect(balances.count == 1)
        #expect(balances.first?.balanceType == .active)
        #expect(balances.first?.amount == Decimal(string: "7.473894246"))
    }

    @Test("The pending actions list drops unsupported types and keeps the rest")
    func pendingActionsListDropsUnsupportedTypes() throws {
        let response = try JSONDecoder().decode(
            StakeKitDTO.Actions.List.Response.self,
            from: Data(Self.actionsListJSON.utf8)
        )

        let actions = try SUT().mapToPendingActions(from: response)

        #expect(actions.map(\.type) == [.withdraw])
        #expect(actions.map(\.id) == ["action-withdraw"])
    }

    @Test("A single action response we asked for ourselves still fails on an unsupported type")
    func singleUnsupportedPendingActionStillThrows() throws {
        let response = try JSONDecoder().decode(
            StakeKitDTO.Actions.Pending.Response.self,
            from: Data(Self.singleMergeActionJSON.utf8)
        )

        #expect(throws: StakeKitMapperError.self) {
            try SUT().mapToPendingAction(from: response)
        }
    }
}

// MARK: - Private helpers

private extension StakeKitUnknownActionTypeTests {
    typealias BalancePendingAction = StakeKitDTO.Balances.Response.Balance.PendingAction

    func decodeActionType(from raw: String) throws -> StakeKitDTO.Actions.ActionType {
        let json = #"{"type": "\#(raw)", "passthrough": "passthrough"}"#
        return try JSONDecoder().decode(BalancePendingAction.self, from: Data(json.utf8)).type
    }

    func decodeBalances(_ json: String) throws -> [StakeKitDTO.Balances.Response] {
        try JSONDecoder().decode([StakeKitDTO.Balances.Response].self, from: Data(json.utf8))
    }
}

// MARK: - Fixtures

private extension StakeKitUnknownActionTypeTests {
    static let solanaToken = #"{"network": "solana", "name": "Solana", "decimals": 9, "symbol": "SOL"}"#

    static let balanceWithMixedActionsJSON = #"""
    [{
        "integrationId": "solana-sol-native-multivalidator-staking",
        "balances": [{
            "groupId": "group-1",
            "type": "staked",
            "amount": "7.473894246",
            "pricePerShare": "1",
            "token": \#(solanaToken),
            "validatorAddress": "BbM5kJgrwEj3tYFfBPnjcARB54wDUHkXmLUTkazUmt2x",
            "pendingActions": [
                {"type": "WITHDRAW", "passthrough": "passthrough-withdraw"},
                {"type": "MERGE", "passthrough": "passthrough-merge"},
                {"type": "SOME_FUTURE_ACTION", "passthrough": "passthrough-future"}
            ],
            "pendingActionConstraints": [
                {"type": "UNSTAKE", "amount": {"minimum": 1, "maximum": 10}},
                {"type": "MERGE", "amount": {"minimum": 0}},
                {"type": "SOME_FUTURE_ACTION", "amount": {"minimum": 0}}
            ]
        }]
    }]
    """#

    static let balanceWithOnlyMergeJSON = #"""
    [{
        "integrationId": "solana-sol-native-multivalidator-staking",
        "balances": [{
            "groupId": "group-1",
            "type": "staked",
            "amount": "7.473894246",
            "pricePerShare": "1",
            "token": \#(solanaToken),
            "validatorAddress": "BbM5kJgrwEj3tYFfBPnjcARB54wDUHkXmLUTkazUmt2x",
            "pendingActions": [
                {"type": "MERGE", "passthrough": "passthrough-merge"}
            ]
        }]
    }]
    """#

    static let balancesWithUnknownTypeJSON = #"""
    [{
        "integrationId": "solana-sol-native-multivalidator-staking",
        "balances": [
            {
                "groupId": "group-1",
                "type": "staked",
                "amount": "7.473894246",
                "pricePerShare": "1",
                "token": \#(solanaToken),
                "validatorAddress": "BbM5kJgrwEj3tYFfBPnjcARB54wDUHkXmLUTkazUmt2x",
                "pendingActions": []
            },
            {
                "groupId": "group-2",
                "type": "some_future_balance",
                "amount": "1.5",
                "pricePerShare": "1",
                "token": \#(solanaToken),
                "pendingActions": []
            }
        ]
    }]
    """#

    static let actionsListJSON = #"""
    {
        "page": 1,
        "hasNextPage": false,
        "limit": 50,
        "data": [
            \#(action(id: "action-withdraw", type: "WITHDRAW")),
            \#(action(id: "action-merge", type: "MERGE")),
            \#(action(id: "action-future", type: "SOME_FUTURE_ACTION"))
        ]
    }
    """#

    static let singleMergeActionJSON = #"""
    {
        "id": "action-merge",
        "integrationId": "solana-sol-native-multivalidator-staking",
        "status": "CREATED",
        "type": "MERGE",
        "currentStepIndex": 0,
        "amount": "7.473894246",
        "transactions": [\#(transaction)]
    }
    """#

    static let transaction = #"""
    {
        "id": "transaction-1",
        "network": "solana",
        "status": "CREATED",
        "type": "WITHDRAW",
        "stepIndex": 0,
        "isMessage": false
    }
    """#

    static func action(id: String, type: String) -> String {
        #"""
        {
            "id": "\#(id)",
            "integrationId": "solana-sol-native-multivalidator-staking",
            "status": "CREATED",
            "type": "\#(type)",
            "currentStepIndex": 0,
            "amount": "7.473894246",
            "addresses": {"address": "AjzxZi3VhimjsA4MbB1p1cs36YTyPJcuok7EdT5RRUJB"},
            "transactions": [\#(transaction)]
        }
        """#
    }
}
