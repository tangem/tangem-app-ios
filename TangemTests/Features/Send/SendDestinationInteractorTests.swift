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

        weak var weakInput: SendDestinationInputStub?
        weakInput = input

        input = nil
        _ = sut // Silence "never read" warning
        sut = nil

        // Let main queue process scheduled work from .receiveOnMain()
        await Task.yield()

        #expect(weakInput == nil, "Input should be deallocated - interactor should use weak reference")
    }

    // MARK: - Memo Validation Tests

    @Test("No error when destination is nil")
    func noErrorWhenDestinationIsNil() async {
        let input = SendDestinationInputStub()
        let sut = makeSUT(input: input)

        // Don't set any destination - stays nil
        sut.update(additionalField: emptyMemo)

        let error = await sut.destinationAdditionalFieldError.awaitValue() ?? nil
        #expect(error == nil, "Should not show error when destination is nil")
    }

    @Test("No error on init even if destination requires memo - dropFirst skips initial value")
    func noErrorOnInitBecauseDropFirstSkipsInitialValue() async {
        let input = SendDestinationInputStub()
        // Set memoRequired destination BEFORE creating interactor
        input.send(destination: .memoRequired)

        let sut = makeSUT(input: input)

        // Should NOT show error immediately - dropFirst() skips initial subscription value
        let error = await sut.destinationAdditionalFieldError.awaitValue() ?? nil
        #expect(error == nil, "Should not show error on init - dropFirst skips initial value")
    }

    @Test("Shows error when memo required but empty")
    func showsErrorWhenMemoRequiredButEmpty() async throws {
        let input = SendDestinationInputStub()
        let sut = makeSUT(input: input)

        // Update with empty memo first
        sut.update(additionalField: emptyMemo)
        await Task.yield()

        var receivedError: String?
        let cancellable = sut.destinationAdditionalFieldError
            .sink { receivedError = $0 }

        // Then change destination to memoRequired - should trigger revalidation
        input.send(destination: .memoRequired)
        await Task.yield()

        _ = try #require(receivedError, "Should show error when memo is required but empty")
        cancellable.cancel()
    }

    @Test("No error when memo required and filled")
    func noErrorWhenMemoRequiredAndFilled() async {
        let input = SendDestinationInputStub()
        let sut = makeSUT(input: input)

        // Set destination with memoRequired = true
        input.send(destination: .memoRequired)
        await Task.yield()

        // Update with filled memo
        sut.update(additionalField: anyMemo)

        let error = await sut.destinationAdditionalFieldError.awaitValue() ?? nil
        #expect(error == nil, "Should not show error when memo is filled")
    }

    @Test("No error when memo not required and empty")
    func noErrorWhenMemoNotRequired() async {
        let input = SendDestinationInputStub()
        let sut = makeSUT(input: input)

        // Set destination with memoRequired = false
        input.send(destination: .memoNotRequired)
        await Task.yield()

        // Update with empty memo
        sut.update(additionalField: emptyMemo)

        let error = await sut.destinationAdditionalFieldError.awaitValue() ?? nil
        #expect(error == nil, "Should not show error when memo is not required")
    }

    @Test("Shows error when destination tag format is invalid (XRP)")
    func showsErrorWhenDestinationTagFormatIsInvalid() async throws {
        let input = SendDestinationInputStub()
        let sut = makeSUT(input: input, blockchain: .xrp(curve: .secp256k1))

        // XRP destination tag must be UInt32, "not_a_number" should fail
        sut.update(additionalField: invalidXRPDestinationTag)

        let error = await sut.destinationAdditionalFieldError.awaitValue()
        _ = try #require(error, "Should show error when destination tag is not a valid number")
    }

    @Test("Format error is not cleared when destination changes to memoNotRequired")
    func formatErrorNotClearedOnDestinationChange() async throws {
        let input = SendDestinationInputStub()
        let sut = makeSUT(input: input, blockchain: .xrp(curve: .secp256k1))

        // 1. Enter invalid destination tag → format error appears
        sut.update(additionalField: invalidXRPDestinationTag)
        await Task.yield()

        var receivedError: String?
        let cancellable = sut.destinationAdditionalFieldError
            .sink { receivedError = $0 }

        await Task.yield()
        let formatError = try #require(receivedError, "Format error should appear for invalid destination tag")

        // 2. Change destination to memoNotRequired
        input.send(destination: .memoNotRequired)
        await Task.yield()

        // 3. Format error should NOT be cleared
        #expect(receivedError == formatError, "Format error should not be cleared when destination changes")
        cancellable.cancel()
    }

    // MARK: - Feature Toggle OFF (Old Behavior)

    @Test("Feature OFF: No memo required error when memo is empty")
    func featureOffNoMemoRequiredError() async {
        let input = SendDestinationInputStub()
        let sut = makeSUT(input: input, validateMemoBeforeConfirm: false)

        input.send(destination: .memoRequired)
        sut.update(additionalField: emptyMemo)

        let error = await sut.destinationAdditionalFieldError.awaitValue() ?? nil
        #expect(error == nil, "Feature OFF: should not validate memo required on Destination")
    }

    @Test("Feature OFF: Next button enabled even when memo required but empty")
    func featureOffNextButtonEnabled() async {
        let input = SendDestinationInputStub()
        let sut = makeSUT(input: input, validateMemoBeforeConfirm: false)

        await sut.update(destination: SendDestination.validTONAddress, source: .qrCode)
        input.send(destination: .memoRequired)
        sut.update(additionalField: emptyMemo)

        let isValid = await sut.allFieldsIsValid.awaitValue()
        #expect(isValid == true, "Feature OFF: Next button should be enabled - validation happens on Confirm")
    }

    @Test("Feature OFF: Format error still clears when field emptied")
    func featureOffFormatErrorClears() async throws {
        let input = SendDestinationInputStub()
        let sut = makeSUT(input: input, blockchain: .xrp(curve: .secp256k1), validateMemoBeforeConfirm: false)

        // Enter invalid tag → error
        sut.update(additionalField: invalidXRPDestinationTag)
        await Task.yield()

        var receivedError: String?
        let cancellable = sut.destinationAdditionalFieldError
            .sink { receivedError = $0 }

        await Task.yield()
        _ = try #require(receivedError, "Format error should appear")

        // Clear field → error should clear
        sut.update(additionalField: emptyMemo)
        await Task.yield()

        #expect(receivedError == nil, "Feature OFF: Format error should clear when field emptied")
        cancellable.cancel()
    }

    // MARK: - Button State Tests (allFieldsIsValid)

    @Test("Next button disabled when memo required but empty")
    func nextButtonDisabledWhenMemoRequiredButEmpty() async {
        let input = SendDestinationInputStub()
        let sut = makeSUT(input: input)

        // Set valid destination through interactor (sets _destinationValid = true)
        await sut.update(destination: SendDestination.validTONAddress, source: .qrCode)

        // Set empty memo, then trigger revalidation with memoRequired
        sut.update(additionalField: emptyMemo)
        input.send(destination: .memoRequired)
        await Task.yield()

        let isValid = await sut.allFieldsIsValid.awaitValue()
        #expect(isValid == false, "Next button should be disabled when memo is required but empty")
    }

    @Test("Next button enabled when memo required and filled")
    func nextButtonEnabledWhenMemoFilled() async {
        let input = SendDestinationInputStub()
        let sut = makeSUT(input: input)

        // Set valid destination through interactor (sets _destinationValid = true)
        input.send(destination: .memoRequired)
        await sut.update(destination: SendDestination.validTONAddress, source: .qrCode)
        await Task.yield()

        sut.update(additionalField: anyMemo)

        let isValid = await sut.allFieldsIsValid.awaitValue()
        #expect(isValid == true, "Next button should be enabled when memo is filled")
    }
}

// MARK: - Helpers

private extension SendDestinationInteractorTests {
    var anyMemo: String { "12345" }
    var emptyMemo: String { "" }
    var invalidXRPDestinationTag: String { "invalid_XRP_destination_tag" }

    func makeSUT(
        input: SendDestinationInput,
        blockchain: Blockchain = .ton(curve: .ed25519, testnet: false),
        validateMemoBeforeConfirm: Bool = true
    ) -> SUT {
        let sut = SUT(
            initialSourceToken: SendSourceTokenStub(blockchain: blockchain),
            input: input,
            receiveTokenInput: nil,
            saver: SendDestinationInteractorSaverStub(),
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

    var destination: SendDestination? { destinationSubject.value }
    var destinationAdditionalField: SendDestinationAdditionalField { .empty(type: .memo) }
    var destinationPublisher: AnyPublisher<SendDestination?, Never> { destinationSubject.eraseToAnyPublisher() }
    var additionalFieldPublisher: AnyPublisher<SendDestinationAdditionalField, Never> { Just(.empty(type: .memo)).eraseToAnyPublisher() }

    func send(destination: SendDestination?) {
        destinationSubject.send(destination)
    }
}

private final class SendDestinationInteractorSaverStub: SendDestinationInteractorSaver {
    func update(address: SendDestination?) {}
    func update(additionalField: SendDestinationAdditionalField) {}
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

private final class SendSourceTokenStub: SendSourceToken {
    private let blockchain: Blockchain

    init(blockchain: Blockchain = .ton(curve: .ed25519, testnet: false)) {
        self.blockchain = blockchain
    }

    var tokenItem: TokenItem {
        .blockchain(.init(blockchain, derivationPath: nil))
    }

    var isCustom: Bool { false }
    var fiatItem: FiatItem { notNeeded() }
    var destination: SendReceiveTokenDestination? { nil }

    // SendSourceToken
    var userWalletInfo: UserWalletInfo { notNeeded() }
    var id: WalletModelId { notNeeded() }
    var header: TokenHeader { notNeeded() }
    var feeTokenItem: TokenItem { notNeeded() }
    var defaultAddressString: String { "" }
    var availableBalanceProvider: TokenBalanceProvider { notNeeded() }
    var fiatAvailableBalanceProvider: TokenBalanceProvider { notNeeded() }
    var allowanceService: (any AllowanceService)? { nil }
    var withdrawalNotificationProvider: WithdrawalNotificationProvider? { nil }
    var emailDataCollectorBuilder: EmailDataCollectorBuilder { notNeeded() }
    var transactionDispatcherProvider: any TransactionDispatcherProvider { notNeeded() }
    var accountModelAnalyticsProvider: (any AccountModelAnalyticsProviding)? { nil }
    var tangemIconProvider: any TangemIconProvider { notNeeded() }
    var confirmTransactionPolicy: any ConfirmTransactionPolicy { notNeeded() }

    private func notNeeded<T>(
        property: String = #function,
        file: StaticString = #file,
        line: UInt = #line
    ) -> T {
        fatalError(
            "\(Self.self).\(property) is not implemented - stub should not call this",
            file: file,
            line: line
        )
    }
}

// MARK: - Publisher Test Helper

private extension Publisher where Failure == Never {
    func awaitValue() async -> Output? {
        var value: Output?
        let cancellable = sink { value = $0 }
        await Task.yield()
        cancellable.cancel()
        return value
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
