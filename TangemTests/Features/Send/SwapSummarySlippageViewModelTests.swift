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
        let viewModel = SwapSummarySlippageViewModel(swapProvidersInput: input, isCustomSlippageAvailable: true)
        let recorder = VisibilityRecorder(viewModel: viewModel)

        input.selectedSubject.send(.failure(StubError()))
        try await recorder.waitForValues(count: 2)

        #expect(recorder.values == [true, false])
    }

    @Test("Stays hidden while the feature is off")
    func hiddenWhenFeatureIsOff() async {
        let provider = ExpressAvailableProviderFixture.make(state: .idle)
        let input = SwapProvidersInputStub(selected: .success(provider))

        let viewModel = SwapSummarySlippageViewModel(swapProvidersInput: input, isCustomSlippageAvailable: false)
        await Task.yield()

        #expect(!viewModel.isVisible)
    }
}

// MARK: - Helpers

private extension SwapSummarySlippageViewModelTests {
    struct StubError: Error {}

    func resolveVisibility(selected: LoadingResult<ExpressAvailableProvider, any Error>?) async throws -> Bool {
        let input = SwapProvidersInputStub(selected: selected)
        let viewModel = SwapSummarySlippageViewModel(swapProvidersInput: input, isCustomSlippageAvailable: true)
        let recorder = VisibilityRecorder(viewModel: viewModel)

        try await recorder.waitForValues(count: 1)

        guard let isVisible = recorder.values.first else {
            throw StubError()
        }

        return isVisible
    }
}

@MainActor
private final class VisibilityRecorder {
    private(set) var values: [Bool] = []
    private var cancellable: AnyCancellable?

    init(viewModel: SwapSummarySlippageViewModel) {
        cancellable = viewModel.$isVisible
            .dropFirst()
            .sink { [weak self] in self?.values.append($0) }
    }

    func waitForValues(count: Int, timeout: Duration = .seconds(5)) async throws {
        let deadline = ContinuousClock.now + timeout

        while values.count < count {
            guard ContinuousClock.now < deadline else {
                Issue.record("Timed out waiting for \(count) visibility values, got \(values)")
                return
            }

            try await Task.sleep(for: .milliseconds(10))
        }
    }
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
