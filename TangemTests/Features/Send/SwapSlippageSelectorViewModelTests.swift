//
//  SwapSlippageSelectorViewModelTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemExpress
@testable import Tangem

@Suite("SwapSlippageSelectorViewModel")
@MainActor
struct SwapSlippageSelectorViewModelTests {
    @Test("Starts from the provider default and offers half, default and double")
    func startsFromDefault() throws {
        let viewModel = makeViewModel(defaultSlippage: 0.003)

        let offeredPresets = try #require(presets(of: viewModel))

        #expect(viewModel.fieldViewModel.value == 0.3)
        #expect(viewModel.message == nil)
        #expect(viewModel.isConfirmEnabled)
        #expect(offeredPresets.map(\.slippage) == [0.0015, 0.003, 0.006])
        #expect(offeredPresets.map(\.title) == ["0.15%", "Default 0.3%", "0.6%"])
    }

    @Test("Starts from the custom slippage set before")
    func startsFromCustom() {
        let viewModel = makeViewModel(defaultSlippage: 0.003, slippage: .custom(0.005))

        #expect(viewModel.fieldViewModel.value == 0.5)
    }

    @Test("Rejects a slippage above double the default")
    func rejectsAboveMax() {
        let viewModel = makeViewModel(defaultSlippage: 0.003)

        type("35", into: viewModel.fieldViewModel)

        #expect(viewModel.message == .unsupportedAmount)
        #expect(!viewModel.isConfirmEnabled)
    }

    @Test("Rejects a slippage below the minimum")
    func rejectsBelowMin() {
        let viewModel = makeViewModel(defaultSlippage: 0.003)

        type("0", into: viewModel.fieldViewModel)

        #expect(viewModel.message == .unsupportedAmount)
        #expect(!viewModel.isConfirmEnabled)
    }

    @Test("Warns but allows a slippage below half the default")
    func warnsBelowThreshold() {
        let viewModel = makeViewModel(defaultSlippage: 0.003)

        type("0.11", into: viewModel.fieldViewModel)

        #expect(viewModel.message == .mayFail)
        #expect(viewModel.isConfirmEnabled)
    }

    @Test("Disables confirm for an empty field")
    func disablesForEmptyField() {
        let viewModel = makeViewModel(defaultSlippage: 0.003)

        type("", into: viewModel.fieldViewModel)

        #expect(viewModel.message == nil)
        #expect(!viewModel.isConfirmEnabled)
    }

    @Test("Confirms the entered slippage as a fraction")
    func confirmsCustom() {
        let output = SlippageOutputSpy()
        let viewModel = makeViewModel(defaultSlippage: 0.003, output: output)

        type("0.45", into: viewModel.fieldViewModel)
        viewModel.confirm()

        #expect(output.slippages == [.custom(0.0045)])
    }

    @Test("Confirms the default preset as Auto")
    func confirmsDefaultAsAuto() throws {
        let output = SlippageOutputSpy()
        let viewModel = makeViewModel(defaultSlippage: 0.003, slippage: .custom(0.005), output: output)

        let defaultPreset = try #require(presets(of: viewModel)?[1])
        viewModel.select(preset: defaultPreset)
        viewModel.confirm()

        #expect(output.slippages == [.auto])
    }

    @Test("Does not confirm an unsupported slippage")
    func doesNotConfirmUnsupported() {
        let output = SlippageOutputSpy()
        let viewModel = makeViewModel(defaultSlippage: 0.003, output: output)

        type("35", into: viewModel.fieldViewModel)
        viewModel.confirm()

        #expect(output.slippages.isEmpty)
    }

    @Test("Accepts exactly double the default and does not warn at exactly half")
    func acceptsBoundaries() {
        let viewModel = makeViewModel(defaultSlippage: 0.003)

        type("0.6", into: viewModel.fieldViewModel)
        let isMaxAccepted = viewModel.isConfirmEnabled && viewModel.message == nil

        type("0.15", into: viewModel.fieldViewModel)

        #expect(isMaxAccepted)
        #expect(viewModel.isConfirmEnabled)
        #expect(viewModel.message == nil)
    }

    @Test("Treats a default with binary noise as the rounded default")
    func normalizesInexactDefault() {
        let output = SlippageOutputSpy()
        let viewModel = makeViewModel(defaultSlippage: Decimal(0.003), slippage: .custom(0.005), output: output)

        type("0.3", into: viewModel.fieldViewModel)
        viewModel.confirm()

        #expect(output.slippages == [.auto])
    }

    @Test("Drops presets that collapse into one or fall below the minimum")
    func dropsInvalidPresets() throws {
        let viewModel = makeViewModel(defaultSlippage: 0.0001)

        let offeredPresets = try #require(presets(of: viewModel))

        #expect(offeredPresets.map(\.slippage) == [0.0001, 0.0002])
    }

    @Test("Does not offer customization for a zero or negative default", arguments: [Decimal(0), Decimal(-0.01), Decimal(0.00004)])
    func notCustomizableForInvalidDefault(defaultSlippage: Decimal) {
        let viewModel = makeViewModel(defaultSlippage: defaultSlippage)

        guard case .notCustomizable = viewModel.content else {
            Issue.record("Expected the not customizable content")
            return
        }
    }

    @Test("Explains a provider without custom slippage and leaves the slippage alone")
    func notCustomizable() {
        let output = SlippageOutputSpy()
        let viewModel = makeViewModel(defaultSlippage: 0.035, isCustomSlippageSupported: false, output: output)

        viewModel.confirm()

        guard case .notCustomizable(let maxSlippage) = viewModel.content else {
            Issue.record("Expected the not customizable content")
            return
        }

        #expect(maxSlippage == "3.5%")
        #expect(viewModel.isConfirmEnabled)
        #expect(output.slippages.isEmpty)
    }
}

// MARK: - Helpers

private extension SwapSlippageSelectorViewModelTests {
    func makeViewModel(
        defaultSlippage: Decimal?,
        slippage: SwapSlippage = .auto,
        isCustomSlippageSupported: Bool = true,
        output: SlippageOutputSpy = SlippageOutputSpy()
    ) -> SwapSlippageSelectorViewModel {
        let provider = ExpressProvider(
            id: "provider",
            name: "Provider",
            type: .dex,
            exchangeOnlyWithinSingleAddress: false,
            imageURL: nil,
            termsOfUse: nil,
            privacyPolicy: nil,
            recommended: nil,
            slippage: defaultSlippage,
            isCustomSlippageSupported: isCustomSlippageSupported
        )

        return SwapSlippageSelectorViewModel(
            provider: provider,
            slippage: slippage,
            output: output,
            percentFormatter: PercentFormatter(locale: Locale(identifier: "en_US"))
        )
    }

    func presets(of viewModel: SwapSlippageSelectorViewModel) -> [SwapSlippageSelectorViewModel.Preset]? {
        guard case .customizable(_, let presets) = viewModel.content else {
            return nil
        }

        return presets
    }

    func type(_ text: String, into field: DecimalNumberTextFieldViewModel) {
        let separator = Locale.current.decimalSeparator ?? "."

        field.textFieldTextBinding.value = text.replacingOccurrences(of: ".", with: separator)
        field.sanitize()
    }
}

private final class SlippageOutputSpy: SwapSlippageOutput {
    private(set) var slippages: [SwapSlippage] = []

    func userDidOpenSlippageSelector() {}

    func userDidSet(slippage: SwapSlippage) {
        slippages.append(slippage)
    }
}
