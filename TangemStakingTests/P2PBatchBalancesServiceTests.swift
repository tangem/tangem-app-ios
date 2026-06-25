//
//  P2PBatchBalancesServiceTests.swift
//  TangemStakingTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import XCTest
@testable import TangemStaking

final class P2PBatchBalancesServiceTests: XCTestCase {
    private let addressA = "0x008d3cd3e349Cd3D5F7c287b3BaF9e4f3E4ba99b"
    private let addressBad = "0xBADADDRESS"
    private let vault = "0x4c09BC47db288F998b33CD63BCc1b6ddCCe13F33"

    // MARK: - Decoding

    func testDecodeSamplePayload() throws {
        let response = try JSONDecoder().decode(P2PDTO.AccountsList.Response.self, from: Self.sampleJSON)

        let list = try XCTUnwrap(response.result?.list)
        XCTAssertEqual(list.count, 2)

        let good = try XCTUnwrap(list.first { $0.account != nil })
        // String-encoded decimal — must decode exactly.
        XCTAssertEqual(good.account?.stake.assets, Decimal(string: "1.2345"))
        // Number-encoded decimals — assert they decode to a sane value (precision is Foundation-version dependent).
        let earned = try XCTUnwrap(good.account?.stake.totalEarnedAssets)
        XCTAssertGreaterThan(earned, .zero)
        let withdraw = try XCTUnwrap(good.account?.availableToWithdraw)
        XCTAssertGreaterThan(withdraw, Decimal(15049))

        let bad = try XCTUnwrap(list.first { $0.account == nil })
        XCTAssertEqual(bad.error?.code, 127108)
    }

    // MARK: - Coalescing

    func testConcurrentCallsCoalesceIntoSinglePOST() async throws {
        let info = try Self.decodedInfo()
        let service = MockP2PStakingAPIService(result: info)
        let sut = makeSUT(service: service)

        async let r1 = sut.balances()
        async let r2 = sut.balances()
        async let r3 = sut.balances()
        let results = try await [r1, r2, r3]

        let calls = await service.accountsListCalls
        XCTAssertEqual(calls.count, 1, "All concurrent callers must share a single batch POST")
        XCTAssertEqual(calls.first?.vaultAddress, vault)
        XCTAssertEqual(Set(calls.first?.delegatorAddresses ?? []), Set([addressA, addressBad]))

        for result in results {
            let active = activeAmounts(in: result[addressA.lowercased()] ?? [])
            XCTAssertEqual(active, [Decimal(string: "1.2345")!])
        }
    }

    // MARK: - Per-address handling

    func testAddressWithoutAccountResolvesToNoBalances() async throws {
        let info = try Self.decodedInfo()
        let sut = makeSUT(service: MockP2PStakingAPIService(result: info))

        let result = try await sut.balances()

        XCTAssertNil(result[addressBad.lowercased()], "An address with a per-address error must not appear in the map")
        XCTAssertFalse((result[addressA.lowercased()] ?? []).isEmpty)
    }

    // MARK: - Failure propagation

    func testWholePOSTFailurePropagates() async throws {
        let service = MockP2PStakingAPIService(result: .init(list: []))
        await service.setError(MockError.boom)
        let sut = makeSUT(service: service)

        do {
            _ = try await sut.balances()
            XCTFail("Expected the batch fetch to throw")
        } catch {
            XCTAssertTrue(error is MockError)
        }
    }

    // MARK: - Helpers

    private func makeSUT(service: MockP2PStakingAPIService) -> CommonP2PBatchBalancesService {
        CommonP2PBatchBalancesService(
            service: service,
            mapper: P2PMapper(),
            addressProvider: MockAddressProvider(addresses: [addressA, addressBad]),
            yieldInfoProvider: MockYieldInfoProvider(yield: makeYield(vaultAddress: vault))
        )
    }

    private func activeAmounts(in balances: [StakingBalanceInfo]) -> [Decimal] {
        balances.compactMap { balance in
            if case .active = balance.balanceType { return balance.amount }
            return nil
        }
    }

    private func makeYield(vaultAddress: String) -> StakingYieldInfo {
        let target = StakingTargetInfo(
            address: vaultAddress,
            name: "Vault",
            preferred: true,
            partner: false,
            image: nil,
            rewardType: .apy,
            rewardRate: .zero,
            status: .active,
            maximumStakeAmount: nil
        )

        return StakingYieldInfo(
            id: "ethereum",
            isAvailable: true,
            rewardType: .apy,
            rewardRateValues: RewardRateValues(aprs: [], rewardRate: .zero),
            enterMinimumRequirement: .zero,
            exitMinimumRequirement: .zero,
            targets: [target],
            preferredTargets: [target],
            item: .ethereum,
            unbondingPeriod: .constant(days: 0),
            warmupPeriod: .constant(days: 0),
            rewardClaimingType: .auto,
            rewardScheduleType: .daily,
            maximumStakeAmount: nil
        )
    }

    private static func decodedInfo() throws -> P2PDTO.AccountsList.AccountsListInfo {
        let response = try JSONDecoder().decode(P2PDTO.AccountsList.Response.self, from: sampleJSON)
        return try XCTUnwrap(response.result)
    }

    private static let sampleJSON = Data(
        """
        {
          "error": null,
          "result": {
            "list": [
              {
                "delegatorAddress": "0x008d3cd3e349Cd3D5F7c287b3BaF9e4f3E4ba99b",
                "account": {
                  "delegatorAddress": "0x008d3cd3e349Cd3D5F7c287b3BaF9e4f3E4ba99b",
                  "vaultAddress": "0x4c09BC47db288F998b33CD63BCc1b6ddCCe13F33",
                  "stake": { "assets": "1.234500000000000000", "totalEarnedAssets": 0.0191 },
                  "availableToUnstake": "0.000000000000000005",
                  "availableToWithdraw": 15049.547647281135,
                  "exitQueue": { "total": 0, "requests": [] }
                },
                "error": null
              },
              {
                "delegatorAddress": "0xBADADDRESS",
                "account": null,
                "error": {
                  "code": 127108,
                  "message": "The provided delegator address is invalid or not properly formatted."
                }
              }
            ]
          }
        }
        """.utf8
    )
}

// MARK: - Mocks

private enum MockError: Error {
    case boom
    case unimplemented
}

private actor MockP2PStakingAPIService: P2PStakingAPIService {
    struct Call {
        let vaultAddress: String
        let delegatorAddresses: [String]
    }

    private(set) var accountsListCalls: [Call] = []
    private var result: P2PDTO.AccountsList.AccountsListInfo
    private var errorToThrow: Error?

    init(result: P2PDTO.AccountsList.AccountsListInfo) {
        self.result = result
    }

    func setError(_ error: Error?) {
        errorToThrow = error
    }

    func getAccountsList(vaultAddress: String, delegatorAddresses: [String]) async throws -> P2PDTO.AccountsList.AccountsListInfo {
        accountsListCalls.append(Call(vaultAddress: vaultAddress, delegatorAddresses: delegatorAddresses))
        if let errorToThrow {
            throw errorToThrow
        }
        return result
    }

    func getVaultsList() async throws -> P2PDTO.Vaults.VaultsInfo {
        throw MockError.unimplemented
    }

    func getAccountSummary(delegatorAddress: String, vaultAddress: String) async throws -> P2PDTO.AccountSummary.AccountSummaryInfo {
        throw MockError.unimplemented
    }

    func prepareDepositTransaction(request: P2PDTO.PrepareTransaction.Request) async throws -> P2PDTO.PrepareTransaction.PrepareTransactionInfo {
        throw MockError.unimplemented
    }

    func prepareUnstakeTransaction(request: P2PDTO.PrepareTransaction.Request) async throws -> P2PDTO.PrepareTransaction.PrepareTransactionInfo {
        throw MockError.unimplemented
    }

    func prepareWithdrawTransaction(request: P2PDTO.PrepareTransaction.Request) async throws -> P2PDTO.PrepareTransaction.PrepareTransactionInfo {
        throw MockError.unimplemented
    }

    func broadcastTransaction(request: P2PDTO.BroadcastTransaction.Request) async throws -> P2PDTO.BroadcastTransaction.BroadcastTransactionInfo {
        throw MockError.unimplemented
    }
}

private struct MockAddressProvider: P2PDelegatorAddressProvider {
    let addresses: [String]
    func delegatorAddresses() -> [String] { addresses }
}

private struct MockYieldInfoProvider: StakingYieldInfoProvider {
    let yield: StakingYieldInfo
    func yieldInfo(for integrationId: String) async throws -> StakingYieldInfo { yield }
}
