//
//  PolymarketAmountFractionChips.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI
import TangemUIUtils

struct PolymarketAmountFractionChips: View {
    private let fractions: [PolymarketAmountFraction]
    private let focused: FocusState<Bool>.Binding
    private let onSelect: (PolymarketAmountFraction) -> Void

    init(
        fractions: [PolymarketAmountFraction],
        focused: FocusState<Bool>.Binding,
        onSelect: @escaping (PolymarketAmountFraction) -> Void
    ) {
        self.fractions = fractions
        self.focused = focused
        self.onSelect = onSelect
    }

    var body: some View {
        HStack(spacing: Constants.spacing) {
            ForEach(fractions, id: \.self) { fraction in
                chip(fraction)
            }

            if fractions.isEmpty {
                Spacer(minLength: 0)
            }

            dismissButton
        }
        .padding(.horizontal, Constants.horizontalPadding)
        .frame(height: Constants.height)
    }

    // MARK: - Controls

    private func chip(_ fraction: PolymarketAmountFraction) -> some View {
        TangemUI.Button(
            label: fraction.title,
            accessibilityLabel: nil,
            action: { onSelect(fraction) }
        )
        .size(Constants.controlSize)
        .styleType(controlStyleType)
        .horizontalLayout(.infinity)
    }

    private var dismissButton: some View {
        TangemUI.Button(
            icon: Assets.hideKeyboard,
            accessibilityLabel: Localization.commonHide,
            action: { focused.wrappedValue = false }
        )
        .size(Constants.controlSize)
        .styleType(controlStyleType)
    }

    private var controlStyleType: TangemUI.Button.StyleType {
        if #available(iOS 26.0, *) {
            return .material(.glass)
        }

        return .secondary(.default)
    }
}

// MARK: - Fraction

enum PolymarketAmountFraction: Hashable, CaseIterable {
    case quarter
    case half
    case threeQuarters
    case max

    var percent: Int {
        switch self {
        case .quarter: 25
        case .half: 50
        case .threeQuarters: 75
        case .max: 100
        }
    }

    var multiplier: Decimal {
        Decimal(percent) / 100
    }

    var title: String {
        switch self {
        case .max: Localization.sendMaxAmount
        case .quarter, .half, .threeQuarters: "\(percent)%"
        }
    }
}

// MARK: - Constants

private extension PolymarketAmountFractionChips {
    enum Constants {
        static let spacing: CGFloat = 8
        static let horizontalPadding: CGFloat = 12
        static let height: CGFloat = 52
        static let controlSize: TangemUI.Button.Size = .x9
    }
}

// MARK: - Previews

private struct PolymarketAmountFractionChipsShowcase: View {
    @FocusState private var focused: Bool

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                row(PolymarketAmountFraction.allCases, surface: DesignSystem.Color.bgPrimary)
                row(PolymarketAmountFraction.allCases, surface: DesignSystem.Color.bgSecondary)
                row([.quarter, .half, .threeQuarters], surface: DesignSystem.Color.bgSecondary)
                row([], surface: DesignSystem.Color.bgSecondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 24)
        }
        .background(DesignSystem.Color.bgPrimary.ignoresSafeArea())
    }

    private func row(_ fractions: [PolymarketAmountFraction], surface: Color) -> some View {
        PolymarketAmountFractionChips(fractions: fractions, focused: $focused, onSelect: { _ in })
            .frame(maxWidth: .infinity)
            .background(surface)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

private struct PolymarketAmountFractionChipsKeyboardShowcase: View {
    @FocusState private var focused: Bool
    @State private var amount = ""

    var body: some View {
        TextField("0", text: $amount)
            .keyboardType(.decimalPad)
            .focused($focused)
            .multilineTextAlignment(.center)
            .style(DesignSystem.Font.displayMediumToken, color: DesignSystem.Color.textPrimary)
            .padding(24)
            .frame(maxWidth: .infinity)
            .background(DesignSystem.Color.bgSecondary)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(DesignSystem.Color.bgPrimary.ignoresSafeArea())
            .keyboardToolbar {
                PolymarketAmountFractionChips(
                    fractions: PolymarketAmountFraction.allCases,
                    focused: $focused,
                    onSelect: { _ in }
                )
            }
            .ignoresSafeArea(.keyboard)
            .onAppear { focused = true }
    }
}

#Preview("Showcase") {
    PolymarketAmountFractionChipsShowcase()
}

#Preview("Showcase — Dark") {
    PolymarketAmountFractionChipsShowcase()
        .preferredColorScheme(.dark)
}

#Preview("Keyboard toolbar") {
    PolymarketAmountFractionChipsKeyboardShowcase()
}
