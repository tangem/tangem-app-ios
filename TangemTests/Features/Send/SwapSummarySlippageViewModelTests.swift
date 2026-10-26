//
//  SwapSummarySlippageViewModelTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import Testing
import TangemFoundation
import TangemExpress
@testable import Tangem

@Suite("SwapSummarySlippageViewModel")
@MainActor
struct SwapSummarySlippageViewModelTests {
    @Test("Shows the row for a selected provider")
    func visibleForSelectedProvider() async throws {
        let provider = ExpressAvailableProviderFixture.make(state: .idle)

        let isVisible = try await resolveVisibility(selected: .success(provider))

        #expect(isVisible)
    }

    @Test("Keeps the row while the provider is loading")
    func visibleWhileLoading() async throws {
        let isVisible = try await resolveVisibility(selected: .loading)

        #expect(isVisible)
    }

    @Test("Hides the row without a provider")
    func hiddenWithoutProvider() async throws {
        let isVisible = try await resolveVisibility(selected: nil)

        #expect(!isVisible)
    }

    @Test("Hides the row when the provider fails")
    func hiddenOnFailure() async throws {
        let isVisible = try await resolveVisibility(selected: .failure(StubError()))

        #expect(!isVisible)
    }

    @Test("Hides the row once the loading provider fails")
    func hidesAfterLoadingFails() async throws {
        let input = SwapProvidersInputStub(selected: .loading)
        let viewModel = SwapSummarySlippageViewModel(swapProvidersInput: input, slippageInput: SlippageInputStub())
        let recorder = ValueRecorder(publisher: viewModel.$isVisible)

        input.selectedSubject.send(.failure(StubError()))
        try await recorder.waitForValues(count: 2)

        #expect(recorder.values == [true, false])
    }

    @Test("Shows Auto until a custom slippage is set, then the formatted value")
    func showsCustomSlippage() async throws {
        let input = SwapProvidersInputStub(selected: .loading)
        let slippageInput = SlippageInputStub()
        let viewModel = SwapSummarySlippageViewModel(
            swapProvidersInput: input,
            slippageInput: slippageInput,
            percentFormatter: PercentFormatter(locale: Locale(identifier: "en_US"))
        )
        let recorder = ValueRecorder(publisher: viewModel.$value)

        slippageInput.subject.send(.custom(0.0015))
        try await recorder.waitForValues(count: 2)

        #expect(recorder.values == [.auto(isHighlighted: false), .custom("0.15%")])
    }

    @Test("Highlights Auto after the custom slippage was reset")
    func highlightsResetSlippage() async throws {
        let slippageInput = SlippageInputStub()
        slippageInput.subject.send(.custom(0.0015))
        let viewModel = SwapSummarySlippageViewModel(
            swapProvidersInput: SwapProvidersInputStub(selected: .loading),
            slippageInput: slippageInput,
            percentFormatter: PercentFormatter(locale: Locale(identifier: "en_US"))
        )
        let recorder = ValueRecorder(publisher: viewModel.$value)

        slippageInput.resetSubject.send(true)
        slippageInput.subject.send(.auto)
        try await recorder.waitForValues(count: 2)

        #expect(recorder.values == [.custom("0.15%"), .auto(isHighlighted: true)])
    }

    @Test("Allows editing exactly while the sheet has a provider to open with")
    func editableFollowsSlippageProvider() async throws {
        let providerSlippage = SwapProviderSlippage(defaultSlippage: Decimal(string: "0.003")!, isCustomSlippageSupported: true)
        let slippageInput = SlippageInputStub()
        let viewModel = SwapSummarySlippageViewModel(
            swapProvidersInput: SwapProvidersInputStub(selected: .loading),
            slippageInput: slippageInput
        )
        let recorder = ValueRecorder(publisher: viewModel.$isEditable)

        slippageInput.providerSlippageSubject.send(providerSlippage)
        slippageInput.providerSlippageSubject.send(nil)
        try await recorder.waitForValues(count: 3)

        #expect(recorder.values == [false, true, false])
    }
}

// MARK: - Helpers

private extension SwapSummarySlippageViewModelTests {
    struct StubError: Error {}

    func resolveVisibility(selected: LoadingResult<ExpressAvailableProvider, any Error>?) async throws -> Bool {
        let input = SwapProvidersInputStub(selected: selected)
        let viewModel = SwapSummarySlippageViewModel(swapProvidersInput: input, slippageInput: SlippageInputStub())
        let recorder = ValueRecorder(publisher: viewModel.$isVisible)

        try await recorder.waitForValues(count: 1)

        guard let isVisible = recorder.values.first else {
            throw StubError()
        }

        return isVisible
    }
}

@MainActor
private final class ValueRecorder<Value> {
    private(set) var values: [Value] = []
    private var cancellable: AnyCancellable?

    init(publisher: Published<Value>.Publisher) {
        cancellable = publisher
            .dropFirst()
            .sink { [weak self] in self?.values.append($0) }
    }

    func waitForValues(count: Int, timeout: Duration = .seconds(5)) async throws {
        let deadline = ContinuousClock.now + timeout

        while values.count < count {
            guard ContinuousClock.now < deadline else {
                Issue.record("Timed out waiting for \(count) values, got \(values)")
                return
            }

            try await Task.sleep(for: .milliseconds(10))
        }
    }
}

private final class SlippageInputStub: SwapSlippageInput {
    let subject = CurrentValueSubject<SwapSlippage, Never>(.auto)
    let providerSlippageSubject = CurrentValueSubject<SwapProviderSlippage?, Never>(nil)
    let resetSubject = CurrentValueSubject<Bool, Never>(false)

    var slippage: SwapSlippage { subject.value }
    var slippagePublisher: AnyPublisher<SwapSlippage, Never> { subject.eraseToAnyPublisher() }
    var providerSlippage: SwapProviderSlippage? { providerSlippageSubject.value }
    var providerSlippagePublisher: AnyPublisher<SwapProviderSlippage?, Never> { providerSlippageSubject.eraseToAnyPublisher() }
    var isCustomSlippageResetPublisher: AnyPublisher<Bool, Never> { resetSubject.eraseToAnyPublisher() }
}

private final class SwapProvidersInputStub: SendSwapProvidersInput {
    let selectedSubject: CurrentValueSubject<LoadingResult<ExpressAvailableProvider, any Error>?, Never>

    init(selected: LoadingResult<ExpressAvailableProvider, any Error>?) {
        selectedSubject = CurrentValueSubject(selected)
    }

    var expressProviders: [ExpressAvailableProvider] { [] }
    var expressProvidersPublisher: AnyPublisher<[ExpressAvailableProvider], Never> { Just([]).eraseToAnyPublisher() }
    var isDexOnlyProvidersMode: Bool { false }
    var selectedExpressProvider: LoadingResult<ExpressAvailableProvider, any Error>? { selectedSubject.value }
    var selectedExpressProviderPublisher: AnyPublisher<LoadingResult<ExpressAvailableProvider, any Error>?, Never> {
        selectedSubject.eraseToAnyPublisher()
    }

    var providerRateTypesPublisher: AnyPublisher<Set<ExpressProviderRateType>, Never> { Just([]).eraseToAnyPublisher() }
    var currentRateType: ExpressProviderRateType? { nil }
    var currentRateTypePublisher: AnyPublisher<ExpressProviderRateType?, Never> { Just(nil).eraseToAnyPublisher() }
}
