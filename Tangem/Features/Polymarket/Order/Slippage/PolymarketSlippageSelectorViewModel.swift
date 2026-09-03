//
//  PolymarketSlippageSelectorViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation
import TangemLocalization
import TangemPolymarket

final class PolymarketSlippageSelectorViewModel: ObservableObject {
    @Published private(set) var errorText: String?
    @Published private(set) var isConfirmEnabled = false

    let fieldViewModel = DecimalNumberTextFieldViewModel(maximumFractionDigits: PolymarketSlippage.fractionDigits)

    let presets: [Preset] = PolymarketSlippage.presets.map(Preset.init)

    private let onConfirm: (Decimal) -> Void
    private var bag: Set<AnyCancellable> = []

    init(percent: Decimal = PolymarketSlippage.defaultPercent, onConfirm: @escaping (Decimal) -> Void) {
        self.onConfirm = onConfirm

        fieldViewModel.update(value: percent)
        bind()
    }

    func select(preset: Preset) {
        fieldViewModel.update(value: preset.percent)
    }

    func confirm() {
        guard let percent = fieldViewModel.value, PolymarketSlippage.accepts(percent) else { return }

        onConfirm(percent)
    }
}

// MARK: - Private implementation

private extension PolymarketSlippageSelectorViewModel {
    func bind() {
        fieldViewModel
            .valuePublisher()
            .withWeakCaptureOf(self)
            .sink { viewModel, value in viewModel.handle(value) }
            .store(in: &bag)
    }

    func handle(_ percent: Decimal?) {
        guard let percent else {
            errorText = nil
            isConfirmEnabled = false

            return
        }

        let accepted = PolymarketSlippage.accepts(percent)

        errorText = accepted ? nil : Localization.predictionPlaceSlippageError
        isConfirmEnabled = accepted
    }
}

// MARK: - Preset

extension PolymarketSlippageSelectorViewModel {
    struct Preset: Identifiable {
        let percent: Decimal
        let title: String

        var id: Decimal { percent }

        init(_ preset: PolymarketSlippage.Preset) {
            percent = preset.percent

            let formatted = PolymarketSlippageFormatter.percentText(preset.percent)

            title = switch preset.role {
            case .default: Localization.predictionPlaceSlippageDefault(formatted)
            case .plain: formatted
            case .max: Localization.predictionPlaceSlippageMax(formatted)
            }
        }
    }
}

// MARK: - Formatting

enum PolymarketSlippageFormatter {
    static func percentText(_ percent: Decimal) -> String {
        formatter.format(percent / Constants.percentScale, option: .predictionSlippage)
    }

    private static let formatter = PercentFormatter()

    private enum Constants {
        static let percentScale: Decimal = 100
    }
}
