//
//  EarnCalculatorViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemFoundation

@MainActor
final class EarnCalculatorViewModel: ObservableObject {
    @Published private(set) var state: EarnCalculatorViewState
    @Published var selectedBarID: EarnCalculatorViewState.Bar.ID?

    let horizons = EarnCalculatorHorizon.allCases

    var selectedHorizon: EarnCalculatorHorizon { input.horizon }

    private var input: EarnCalculatorInput
    private let incentiveApy: Decimal?
    private let projector: EarnCalculatorProjecting
    private let stateBuilder: EarnCalculatorViewStateBuilder

    init(
        input: EarnCalculatorInput = .default,
        incentiveApy: Decimal?,
        projector: EarnCalculatorProjecting,
        currencyCode: String
    ) {
        self.input = input
        self.incentiveApy = incentiveApy
        self.projector = projector
        stateBuilder = EarnCalculatorViewStateBuilder(currencyCode: currencyCode)
        state = stateBuilder.build(input: input, projection: projector.project(input), incentiveApy: incentiveApy)
    }

    func select(horizon: EarnCalculatorHorizon) {
        guard horizon != input.horizon else {
            return
        }

        input.horizon = horizon
        rebuildState()
    }

    func increase(_ field: EarnCalculatorField) {
        update(field, to: input[field] + field.step)
    }

    func decrease(_ field: EarnCalculatorField) {
        update(field, to: input[field] - field.step)
    }
}

// MARK: - Private

private extension EarnCalculatorViewModel {
    func update(_ field: EarnCalculatorField, to value: Decimal) {
        let clamped = clamp(value, min: field.range.lowerBound, max: field.range.upperBound)

        guard clamped != input[field] else {
            return
        }

        input[field] = clamped
        rebuildState()
    }

    func rebuildState() {
        selectedBarID = nil
        state = stateBuilder.build(input: input, projection: projector.project(input), incentiveApy: incentiveApy)
    }
}
