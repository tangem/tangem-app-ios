//
//  SwapSlippageSelectorViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemFoundation
import TangemExpress
import TangemUI

final class SwapSlippageSelectorViewModel: ObservableObject, FloatingSheetContentViewModel {
    @Injected(\.floatingSheetPresenter) private var floatingSheetPresenter: any FloatingSheetPresenter

    @Published private(set) var message: Message?
    @Published private(set) var isConfirmEnabled = false

    let content: Content
    let fieldViewModel = DecimalNumberTextFieldViewModel(maximumFractionDigits: Constants.percentFractionDigits)

    private let output: SwapSlippageOutput
    private var bag: Set<AnyCancellable> = []

    init(
        provider: ExpressProvider,
        slippage: SwapSlippage,
        output: SwapSlippageOutput,
        percentFormatter: PercentFormatter = PercentFormatter()
    ) {
        self.output = output

        guard let bounds = provider.customSlippageBounds else {
            content = .notCustomizable(maxSlippage: provider.slippage.map { percentFormatter.format($0, option: .customSlippage) })
            isConfirmEnabled = true
            return
        }

        content = .customizable(bounds: bounds, presets: Self.makePresets(bounds: bounds, percentFormatter: percentFormatter))

        bind(bounds: bounds)

        switch slippage {
        case .auto:
            apply(slippage: bounds.defaultSlippage)
        case .custom(let value):
            apply(slippage: value)
        }
    }

    func select(preset: Preset) {
        apply(slippage: preset.slippage)
    }

    func confirm() {
        defer { dismiss() }

        switch content {
        case .notCustomizable:
            output.userDidSet(slippage: .auto)
        case .customizable(let bounds, _):
            guard let slippage = enteredSlippage, bounds.accepts(slippage) else {
                return
            }

            output.userDidSet(slippage: slippage == bounds.defaultSlippage ? .auto : .custom(slippage))
        }
    }

    func dismiss() {
        Task { @MainActor in floatingSheetPresenter.removeActiveSheet() }
    }
}

// MARK: - Private

private extension SwapSlippageSelectorViewModel {
    var enteredSlippage: Decimal? {
        fieldViewModel.value.map { SwapSlippageBounds.normalized($0 / Constants.percentScale) }
    }

    static func makePresets(bounds: SwapSlippageBounds, percentFormatter: PercentFormatter) -> [Preset] {
        [bounds.warningThreshold, bounds.defaultSlippage, bounds.maxSlippage].unique().filter(bounds.accepts).map { slippage in
            let formatted = percentFormatter.format(slippage, option: .customSlippage)
            // [REDACTED_TODO_COMMENT]
            let title = slippage == bounds.defaultSlippage ? "Default \(formatted)" : formatted
            return Preset(slippage: slippage, title: title)
        }
    }

    func bind(bounds: SwapSlippageBounds) {
        fieldViewModel
            .valuePublisher()
            .withWeakCaptureOf(self)
            .sink { viewModel, _ in viewModel.validate(bounds: bounds) }
            .store(in: &bag)
    }

    func apply(slippage: Decimal) {
        fieldViewModel.update(value: slippage * Constants.percentScale)

        if case .customizable(let bounds, _) = content {
            validate(bounds: bounds)
        }
    }

    func validate(bounds: SwapSlippageBounds) {
        guard let slippage = enteredSlippage else {
            message = nil
            isConfirmEnabled = false
            return
        }

        guard bounds.accepts(slippage) else {
            message = .unsupportedAmount
            isConfirmEnabled = false
            return
        }

        message = slippage < bounds.warningThreshold ? .mayFail : nil
        isConfirmEnabled = true
    }
}

// MARK: - Types

extension SwapSlippageSelectorViewModel {
    enum Content {
        case customizable(bounds: SwapSlippageBounds, presets: [Preset])
        case notCustomizable(maxSlippage: String?)
    }

    enum Message {
        case unsupportedAmount
        case mayFail
    }

    struct Preset: Identifiable {
        let slippage: Decimal
        let title: String

        var id: Decimal { slippage }
    }
}

// MARK: - Constants

private extension SwapSlippageSelectorViewModel {
    enum Constants {
        static let percentScale: Decimal = 100
        static let percentFractionDigits = 2
    }
}
