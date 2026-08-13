//
//  CommonTronTokenFeeLoaderTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import BlockchainSdk
@testable import Tangem

@Suite("CommonTronTokenFeeLoader — request forwarding and the otherNativeFee fold")
struct CommonTronTokenFeeLoaderTests {
    @Test("a positive otherNativeFee is added to every returned fee")
    func getFee_positiveOtherNativeFee_isAddedToEveryFee() async throws {
        let provider = TronTransactionFeeProviderSpy(fees: [makeFee(Decimal(string: "1.5")!), makeFee(Decimal(string: "2.5")!)])
        let sut = CommonTronTokenFeeLoader(tokenFeeLoader: PlainTokenFeeLoaderStub(), tronTransactionFeeProvider: provider)

        let fees = try await sut.getFee(request: makeRequest(otherNativeFee: Decimal(string: "0.3")!))

        #expect(fees.map(\.amount.value) == [Decimal(string: "1.8")!, Decimal(string: "2.8")!])
    }

    @Test("a nil or zero otherNativeFee leaves the fees untouched", arguments: [nil, Decimal.zero] as [Decimal?])
    func getFee_absentOtherNativeFee_leavesFeesUntouched(otherNativeFee: Decimal?) async throws {
        let provider = TronTransactionFeeProviderSpy(fees: [makeFee(Decimal(string: "1.5")!)])
        let sut = CommonTronTokenFeeLoader(tokenFeeLoader: PlainTokenFeeLoaderStub(), tronTransactionFeeProvider: provider)

        let fees = try await sut.getFee(request: makeRequest(otherNativeFee: otherNativeFee))

        #expect(fees.map(\.amount.value) == [Decimal(string: "1.5")!])
    }

    @Test("the request fields reach the fee provider as-is")
    func getFee_forwardsRequestFields() async throws {
        let provider = TronTransactionFeeProviderSpy(fees: [makeFee(1)])
        let sut = CommonTronTokenFeeLoader(tokenFeeLoader: PlainTokenFeeLoaderStub(), tronTransactionFeeProvider: provider)
        let request = makeRequest(otherNativeFee: nil)

        _ = try await sut.getFee(request: request)

        let received = try #require(provider.receivedRequests.first)
        #expect(received.amount == request.amount)
        #expect(received.destination == request.destination)
        #expect(received.callData == request.callData)
        #expect(received.memo == request.memo)
    }
}

// MARK: - Helpers

private extension CommonTronTokenFeeLoaderTests {
    func makeRequest(otherNativeFee: Decimal?) -> TronFeeRequestData {
        TronFeeRequestData(
            amount: BSDKAmount(with: .tron(testnet: false), type: .coin, value: 50),
            destination: "TKJMd8JF5hevd2TQeSKvJzwQKgpRQVHpr6",
            callData: Data([0xAB, 0xCD]),
            memo: "=:ETH.ETH:0xd7ABce6612079A05e431752cb85Bf7010E40FdF5",
            otherNativeFee: otherNativeFee
        )
    }

    func makeFee(_ value: Decimal) -> BSDKFee {
        BSDKFee(BSDKAmount(with: .tron(testnet: false), value: value))
    }
}

// MARK: - Doubles

private final class TronTransactionFeeProviderSpy: TronTransactionFeeProvider {
    struct ReceivedRequest {
        let amount: BSDKAmount
        let destination: String
        let callData: Data?
        let memo: String?
    }

    private(set) var receivedRequests: [ReceivedRequest] = []
    private let fees: [BSDKFee]

    init(fees: [BSDKFee]) {
        self.fees = fees
    }

    func getFee(amount: Amount, destination: String, callData: Data?, memo: String?) async throws -> [Fee] {
        receivedRequests.append(ReceivedRequest(amount: amount, destination: destination, callData: callData, memo: memo))
        return fees
    }
}

private struct PlainTokenFeeLoaderStub: TokenFeeLoader {
    enum StubError: Error {
        case notNeeded
    }

    func estimatedFee(amount: Decimal) async throws -> [BSDKFee] { throw StubError.notNeeded }
    func getFee(amount: Decimal, destination: String) async throws -> [BSDKFee] { throw StubError.notNeeded }
}
