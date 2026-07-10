//
//  SolanaRentExemptionValidatorTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemTestKit
import BlockchainSdk
@testable import Tangem

@Suite("SolanaRentExemptionValidator")
final class SolanaRentExemptionValidatorTests: LeakTrackingTestSuite {
    private let blockchain = Blockchain.solana(curve: .ed25519_slip0010, testnet: false)

    private var tokenItem: TokenItem { .blockchain(.init(blockchain, derivationPath: nil)) }
    private var rentExemption: BSDKAmount { .init(with: blockchain, value: Decimal(string: "0.00089088")!) }
    private var estimatedFee: BSDKFee { .init(.init(with: blockchain, value: Decimal(string: "0.000005")!)) }

    @Test("Rent exemption validation error is returned together with the estimated fee")
    func rentErrorReturnsErrorAndFee() async throws {
        let sut = makeSUT(
            estimatedFeeResult: .success(estimatedFee),
            validationError: ValidationError.remainingAmountIsLessThanRentExemption(amount: rentExemption)
        )

        let result = try #require(await sut.validate())

        #expect(result.estimatedFee == estimatedFee.amount.value)

        guard case .remainingAmountIsLessThanRentExemption(let amount) = result.validationError else {
            Issue.record("Expected remainingAmountIsLessThanRentExemption, got \(result.validationError)")
            return
        }

        #expect(amount == rentExemption)
    }

    @Test("Successful validation returns nil")
    func successfulValidationReturnsNil() async {
        let sut = makeSUT(estimatedFeeResult: .success(estimatedFee), validationError: nil)

        #expect(await sut.validate() == nil)
    }

    @Test("Other validation errors fall back to the regular flow")
    func otherValidationErrorReturnsNil() async {
        let sut = makeSUT(estimatedFeeResult: .success(estimatedFee), validationError: ValidationError.totalExceedsBalance)

        #expect(await sut.validate() == nil)
    }

    @Test("Non-validation errors fall back to the regular flow")
    func nonValidationErrorReturnsNil() async {
        let sut = makeSUT(estimatedFeeResult: .success(estimatedFee), validationError: DummyError())

        #expect(await sut.validate() == nil)
    }

    @Test("Fee estimation failure falls back to the regular flow")
    func feeEstimationFailureReturnsNil() async {
        let sut = makeSUT(estimatedFeeResult: .failure(DummyError()), validationError: nil)

        #expect(await sut.validate() == nil)
    }
}

// MARK: - Helpers

private extension SolanaRentExemptionValidatorTests {
    struct DummyError: Error {}

    func makeSUT(estimatedFeeResult: Result<BSDKFee, Error>, validationError: Error?) -> SolanaRentExemptionValidator {
        let feeProvider = TokenFeeProviderStub(
            feeTokenItem: tokenItem,
            initialFee: TokenFee(option: .market, tokenItem: tokenItem, value: .loading)
        )
        let feeProvidersManager = TokenFeeProvidersManagerMock(feeProvider: feeProvider)
        feeProvidersManager.estimatedFeeResult = estimatedFeeResult

        let sut = SolanaRentExemptionValidator(
            tokenItem: tokenItem,
            transactionValidator: TransactionValidatorMock(validateError: validationError),
            tokenFeeProvidersManager: feeProvidersManager
        )

        return trackForMemoryLeaks(sut)
    }
}

private final class TransactionValidatorMock: SendTransactionValidator {
    private let validateError: Error?

    init(validateError: Error?) {
        self.validateError = validateError
    }

    func validate(amount: BSDKAmount) throws {}

    func validate(amount: BSDKAmount, fee: BSDKFee) throws {
        if let validateError {
            throw validateError
        }
    }

    func validate(amount: BSDKAmount, fee: BSDKFee, destination: DestinationType) async throws {}
}
