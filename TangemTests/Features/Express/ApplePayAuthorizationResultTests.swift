//
//  ApplePayAuthorizationResultTests.swift
//  TangemTests
//
//  Created on 28.04.2026.
//

import Foundation
import PassKit
import Testing
@testable import Tangem
@testable import TangemExpress

@Suite("ApplePayAuthorizationResult")
struct ApplePayAuthorizationResultTests {
    @Test("succeed forwards .success status with no errors")
    func succeedForwardsSuccess() {
        var captured: PKPaymentAuthorizationResult?
        let result = makeResult { captured = $0 }

        result.succeed()

        #expect(captured?.status == .success)
        #expect(captured?.errors.isEmpty == true)
    }

    @Test("fail with non-PassKit error forwards .failure status and scrubs the error")
    func failWithNonPassKitErrorScrubsErrors() {
        let stubError = NSError(domain: "TestDomain", code: 42, userInfo: nil)
        var captured: PKPaymentAuthorizationResult?
        let result = makeResult { captured = $0 }

        result.fail(stubError)

        #expect(captured?.status == .failure)
        // Non-PKPaymentErrorDomain errors are dropped — see ApplePayAuthorizationResult.fail.
        #expect(captured?.errors.isEmpty == true)
    }

    @Test("fail with PassKit error forwards .failure status and the wrapped error")
    func failWithPassKitErrorForwardsError() {
        let passKitError = NSError(
            domain: PKPaymentErrorDomain,
            code: PKPaymentError.Code.billingContactInvalidError.rawValue,
            userInfo: nil
        )
        var captured: PKPaymentAuthorizationResult?
        let result = makeResult { captured = $0 }

        result.fail(passKitError)

        #expect(captured?.status == .failure)
        #expect(captured?.errors.count == 1)
        #expect((captured?.errors.first as NSError?)?.domain == PKPaymentErrorDomain)
        #expect((captured?.errors.first as NSError?)?.code == PKPaymentError.Code.billingContactInvalidError.rawValue)
    }

    @Test("fail with no error forwards .failure status and no errors")
    func failWithoutErrorForwardsFailure() {
        var captured: PKPaymentAuthorizationResult?
        let result = makeResult { captured = $0 }

        result.fail()

        #expect(captured?.status == .failure)
        #expect(captured?.errors.isEmpty == true)
    }

    @Test("Provider and applePayResult are exposed as-is")
    func bundledFieldsAreExposed() {
        let provider = OnrampTestFixtures.makeProvider(providerId: "test-id")
        let applePayResult = OnrampApplePayResult(
            paymentToken: "token",
            userData: OnrampNativePaymentRequestItem.UserData(
                email: "user@example.com", firstName: nil, lastName: nil, billingAddress: nil
            )
        )
        let result = ApplePayAuthorizationResult(
            provider: provider,
            applePayResult: applePayResult,
            resultHandler: { _ in }
        )

        #expect(result.provider === provider)
        #expect(result.applePayResult.paymentToken == "token")
    }

    // MARK: - Helpers

    private func makeResult(
        resultHandler: @escaping (PKPaymentAuthorizationResult) -> Void
    ) -> ApplePayAuthorizationResult {
        ApplePayAuthorizationResult(
            provider: OnrampTestFixtures.makeProvider(),
            applePayResult: OnrampApplePayResult(
                paymentToken: "",
                userData: OnrampNativePaymentRequestItem.UserData(
                    email: "user@example.com", firstName: nil, lastName: nil, billingAddress: nil
                )
            ),
            resultHandler: resultHandler
        )
    }
}
