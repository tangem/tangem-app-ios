//
//  SendDestinationInteractorTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import BlockchainSdk
import Combine
import Testing
import TangemTestKit
@testable import Tangem

@Suite("SendDestinationInteractor Tests")
@MainActor
final class SendDestinationInteractorTests: LeakTrackingTestSuite {
    typealias SUT = CommonSendDestinationInteractor

    @Test("Does not retain input - uses weak reference")
    func doesNotRetainInput() async {
        var input: SendDestinationInputStub? = .init()
        var sut: SUT? = makeSUT(input: input!)

        weak var weakInput = input

        input = nil
        _ = sut // Silence "never read" warning
        sut = nil

        await waitUntil { weakInput == nil }

        #expect(weakInput == nil, "Input should be deallocated - interactor should use weak reference")
        weakInput = nil // Silence "never mutated" warning
    }

    // MARK: - Memo Validation Tests

    @Test("No error when destination is nil")
    func noErrorWhenDestinationIsNil() async {
        let input = SendDestinationInputStub()
        let sut = makeSUT(input: input)

        // Don't set any destination - stays nil
        sut.update(additionalField: emptyMemo)

        var receivedError: String?
        let cancellable = sut.destinationAdditionalFieldError.sink { receivedError = $0 }
        await letPipelineSettle()
        cancellable.cancel()

        #expect(receivedError == nil, "Should not show error when destination is nil")
    }

    @Test("Shows error when memo required but empty")
    func showsErrorWhenMemoRequiredButEmpty() async throws {
        let input = SendDestinationInputStub()
        let sut = makeSUT(input: input)

        // Update with empty memo first
        sut.update(additionalField: emptyMemo)

        var receivedError: String?
        let cancellable = sut.destinationAdditionalFieldError.sink { receivedError = $0 }

        // Then change destination to memoRequired - should trigger revalidation
        input.send(destination: .memoRequired)

        await waitUntil { receivedError != nil }

        _ = try #require(receivedError, "Should show error when memo is required but empty")
        cancellable.cancel()
    }

    @Test("No error when memo required and filled")
    func noErrorWhenMemoRequiredAndFilled() async {
        let input = SendDestinationInputStub()
        let sut = makeSUT(input: input)

        // Fill memo FIRST, before setting memoRequired destination
        sut.update(additionalField: anyMemo)

        var receivedError: String?
        let cancellable = sut.destinationAdditionalFieldError.sink { receivedError = $0 }

        // Then set destination with memoRequired = true - memo is already filled
        input.send(destination: .memoRequired)

        await letPipelineSettle()
        cancellable.cancel()

        #expect(receivedError == nil, "Should not show error when memo is filled")
    }

    @Test("No error when memo not required and empty")
    func noErrorWhenMemoNotRequired() async {
        let input = SendDestinationInputStub()
        let sut = makeSUT(input: input)

        // Set destination with memoRequired = false
        input.send(destination: .memoNotRequired)

        var receivedError: String?
        let cancellable = sut.destinationAdditionalFieldError.sink { receivedError = $0 }

        // Update with empty memo
        sut.update(additionalField: emptyMemo)

        await letPipelineSettle()
        cancellable.cancel()

        #expect(receivedError == nil, "Should not show error when memo is not required")
    }

    @Test("Shows error when destination tag format is invalid (XRP)")
    func showsErrorWhenDestinationTagFormatIsInvalid() async throws {
        let input = SendDestinationInputStub()
        let sut = makeSUT(input: input, blockchain: .xrp(curve: .secp256k1))

        var receivedError: String?
        let cancellable = sut.destinationAdditionalFieldError.sink { receivedError = $0 }

        // XRP destination tag must be UInt32, "not_a_number" should fail
        sut.update(additionalField: invalidXRPDestinationTag)

        await waitUntil { receivedError != nil }

        _ = try #require(receivedError, "Should show error when destination tag is not a valid number")
        cancellable.cancel()
    }

    @Test("Format error is not cleared when destination changes to memoNotRequired")
    func formatErrorNotClearedOnDestinationChange() async throws {
        let input = SendDestinationInputStub()
        let sut = makeSUT(input: input, blockchain: .xrp(curve: .secp256k1))

        var receivedError: String?
        let cancellable = sut.destinationAdditionalFieldError.sink { receivedError = $0 }

        // 1. Enter invalid destination tag → format error appears
        sut.update(additionalField: invalidXRPDestinationTag)

        await waitUntil { receivedError != nil }
        let formatError = try #require(receivedError, "Format error should appear for invalid destination tag")

        // 2. Change destination to memoNotRequired
        input.send(destination: .memoNotRequired)
        await letPipelineSettle()

        // 3. Format error should NOT be cleared
        #expect(receivedError == formatError, "Format error should not be cleared when destination changes")
        cancellable.cancel()
    }

    // MARK: - Feature Toggle OFF (Old Behavior)

    @Test("Feature OFF: No memo required error when memo is empty")
    func featureOffNoMemoRequiredError() async {
        let input = SendDestinationInputStub()
        let sut = makeSUT(input: input, validateMemoBeforeConfirm: false)

        var receivedError: String?
        let cancellable = sut.destinationAdditionalFieldError.sink { receivedError = $0 }

        input.send(destination: .memoRequired)
        sut.update(additionalField: emptyMemo)

        await letPipelineSettle()
        cancellable.cancel()

        #expect(receivedError == nil, "Feature OFF: should not validate memo required on Destination")
    }

    @Test("Feature OFF: Next button enabled even when memo required but empty")
    func featureOffNextButtonEnabled() async throws {
        let input = SendDestinationInputStub()
        let sut = makeSUT(input: input, validateMemoBeforeConfirm: false)

        var isValid: Bool?
        let cancellable = sut.allFieldsIsValid.sink { isValid = $0 }

        try await sut.update(destination: SendDestination.validTONAddress, source: .qrCode)
        input.send(destination: .memoRequired)
        sut.update(additionalField: emptyMemo)

        await waitUntil { isValid == true }
        cancellable.cancel()

        #expect(isValid == true, "Feature OFF: Next button should be enabled - validation happens on Confirm")
    }

    @Test("Feature OFF: Format error still clears when field emptied")
    func featureOffFormatErrorClears() async throws {
        let input = SendDestinationInputStub()
        let sut = makeSUT(input: input, blockchain: .xrp(curve: .secp256k1), validateMemoBeforeConfirm: false)

        var receivedError: String?
        let cancellable = sut.destinationAdditionalFieldError.sink { receivedError = $0 }

        // Enter invalid tag → error
        sut.update(additionalField: invalidXRPDestinationTag)

        await waitUntil { receivedError != nil }
        _ = try #require(receivedError, "Format error should appear")

        // Clear field → error should clear
        sut.update(additionalField: emptyMemo)

        await waitUntil { receivedError == nil }
        cancellable.cancel()

        #expect(receivedError == nil, "Feature OFF: Format error should clear when field emptied")
    }

    // MARK: - Button State Tests (allFieldsIsValid)

    @Test("Next button disabled when memo required but empty")
    func nextButtonDisabledWhenMemoRequiredButEmpty() async throws {
        let input = SendDestinationInputStub()
        let sut = makeSUT(input: input)

        var isValid: Bool?
        let cancellable = sut.allFieldsIsValid.sink { isValid = $0 }

        // Set valid destination through interactor (sets _destinationValid = true)
        try await sut.update(destination: SendDestination.validTONAddress, source: .qrCode)

        // Set empty memo, then trigger revalidation with memoRequired
        sut.update(additionalField: emptyMemo)
        input.send(destination: .memoRequired)

        await waitUntil { isValid == false }
        cancellable.cancel()

        #expect(isValid == false, "Next button should be disabled when memo is required but empty")
    }

    @Test("Next button enabled when memo required and filled")
    func nextButtonEnabledWhenMemoFilled() async throws {
        let input = SendDestinationInputStub()
        let sut = makeSUT(input: input)

        var isValid: Bool?
        let cancellable = sut.allFieldsIsValid.sink { isValid = $0 }

        // Set valid destination through interactor (sets _destinationValid = true)
        input.send(destination: .memoRequired)
        try await sut.update(destination: SendDestination.validTONAddress, source: .qrCode)

        sut.update(additionalField: anyMemo)

        await waitUntil { isValid == true }
        cancellable.cancel()

        #expect(isValid == true, "Next button should be enabled when memo is filled")
    }
}

// MARK: - Helpers

private extension SendDestinationInteractorTests {
    var anyMemo: String { "12345" }
    var emptyMemo: String { "" }
    var invalidXRPDestinationTag: String { "invalid_XRP_destination_tag" }

    func makeSUT(
        input: SendDestinationInputStub,
        blockchain: Blockchain = .ton(curve: .ed25519, testnet: false),
        validateMemoBeforeConfirm: Bool = true
    ) -> SUT {
        let sut = SUT(
            initialSourceToken: SendSourceTokenStub(blockchain: blockchain),
            input: input,
            receiveTokenInput: nil,
            saver: SendDestinationInteractorSaverStub(input: input),
            dependenciesBuilder: SendDestinationDependenciesProviderStub(blockchain: blockchain),
            validateMemoBeforeConfirm: validateMemoBeforeConfirm
        )
        trackForMemoryLeaks(sut)
        return sut
    }
}

// MARK: - Stubs

private final class SendDestinationInputStub: SendDestinationInput {
    /// CurrentValueSubject doesn't complete - catches strong capture retain cycles
    private let destinationSubject = CurrentValueSubject<SendDestination?, Never>(nil)
    private let additionalFieldSubject = CurrentValueSubject<SendDestinationAdditionalField, Never>(.empty(type: .memo))

    var destination: SendDestination? { destinationSubject.value }
    var destinationAdditionalField: SendDestinationAdditionalField { additionalFieldSubject.value }
    var destinationPublisher: AnyPublisher<SendDestination?, Never> { destinationSubject.eraseToAnyPublisher() }
    var additionalFieldPublisher: AnyPublisher<SendDestinationAdditionalField, Never> { additionalFieldSubject.eraseToAnyPublisher() }

    func send(destination: SendDestination?) {
        destinationSubject.send(destination)
    }

    func send(additionalField: SendDestinationAdditionalField) {
        additionalFieldSubject.send(additionalField)
    }
}

private final class SendDestinationInteractorSaverStub: SendDestinationInteractorSaver {
    private weak var input: SendDestinationInputStub?

    init(input: SendDestinationInputStub? = nil) {
        self.input = input
    }

    func update(address: SendDestination?) {}
    func update(additionalField: SendDestinationAdditionalField) {
        input?.send(additionalField: additionalField)
    }

    func syncViewFromInput() {}
    func captureValue() {}
    func cancelChanges() {}
}

private final class SendDestinationDependenciesProviderStub: SendDestinationInteractorDependenciesProvider {
    init(blockchain: Blockchain = .ton(curve: .ed25519, testnet: false)) {
        super.init(
            sourceToken: SendSourceTokenStub(blockchain: blockchain),
            receivedToken: nil,
            analyticsLogger: SendDestinationAnalyticsLoggerStub(),
            destinationWalletDataProvider: SendDestinationWalletDataProviderStub()
        )
    }
}

private final class SendDestinationAnalyticsLoggerStub: SendDestinationAnalyticsLogger {
    func logSendAddressEntered(isAddressValid: Bool, addressSource: Analytics.DestinationAddressSource) {}
    func logQRScannerOpened() {}
    func logDestinationStepOpened() {}
    func logDestinationStepReopened() {}
    func setDestinationAnalyticsProvider(_ analyticsProvider: (any AccountModelAnalyticsProviding)?) {}
}

private final class SendDestinationWalletDataProviderStub: SendDestinationInteractorDependenciesProvider.SendDestinationWalletDataProvider {
    func sendWalletData() -> SendDestinationInteractorDependenciesProvider.SendingWalletData? { .empty }
    func swapWalletData(for tokenItem: TokenItem) -> SendDestinationInteractorDependenciesProvider.SendingWalletData? { .empty }
}

// MARK: - Async Test Helpers

private extension SendDestinationInteractorTests {
    /// Polls `condition` until it returns `true`, or records an issue on timeout.
    func waitUntil(
        timeout: Duration = .seconds(2),
        _ condition: @escaping @MainActor () -> Bool
    ) async {
        let deadline = ContinuousClock.now + timeout
        while !condition() {
            if ContinuousClock.now >= deadline {
                Issue.record("waitUntil timed out")
                return
            }
            try? await Task.sleep(for: .milliseconds(10))
        }
    }

    /// Allows Combine pipelines to settle before asserting.
    func letPipelineSettle() async {
        try? await Task.sleep(for: .milliseconds(50))
    }
}

// MARK: - SendDestination Test Helpers

private extension SendDestination {
    /// Valid TON address format for tests
    static let validTONAddress = "EQDtFpEwcFAEcRe5mLVh2N6C0x-_hJEM7W61_JLnSF74p4q2"

    static var memoRequired: SendDestination {
        SendDestination(value: .resolved(address: validTONAddress, resolved: validTONAddress, memoRequired: true), source: .qrCode)
    }

    static var memoNotRequired: SendDestination {
        SendDestination(value: .resolved(address: validTONAddress, resolved: validTONAddress, memoRequired: false), source: .qrCode)
    }
}
