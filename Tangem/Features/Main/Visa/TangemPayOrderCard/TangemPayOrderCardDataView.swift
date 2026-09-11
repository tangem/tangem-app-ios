//
//  TangemPayOrderCardDataView.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUI
import TangemUIUtils

struct TangemPayOrderCardDataView: View {
    @ObservedObject var viewModel: TangemPayOrderCardDataViewModel

    @State private var focusedField: TangemPayOrderCardDataField.ID?

    var body: some View {
        content
            .background { DesignSystem.Color.bgPrimary.ignoresSafeArea() }
            .safeAreaInset(edge: .bottom, spacing: 0) { footer }
            .topNavigation(
                title: Localization.tangempayOrderTypeTitle,
                subtitle: Localization.tangempayOrderDataSubtitle,
                leading: .custom(.back(action: viewModel.back)),
                onClose: viewModel.close
            )
    }

    private var content: some View {
        ScrollView {
            VStack(spacing: Constants.sectionSpacing) {
                ForEach($viewModel.sections) { $section in
                    VStack(spacing: 0) {
                        ForEach($section.fields) { $field in
                            fieldView($field)
                        }
                    }
                }
            }
            .padding(.horizontal, Constants.horizontalPadding)
            .padding(.top, Constants.topPadding)
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
        // Shrinks what counts as visible, so bringing a focused field into view stops short of the footer
        // and leaves the field's divider on screen instead of under the fade.
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Color.clear.frame(height: Constants.focusedFieldClearance)
        }
    }

    private func placeOrder() {
        focusedField = nil
        viewModel.placeOrder()
    }

    private func fieldView(_ field: Binding<TangemPayOrderCardDataField>) -> some View {
        TangemPayOrderCardDataFieldView(
            field: field,
            focusedField: $focusedField,
            nextFieldID: viewModel.fieldAfter(field.wrappedValue.id)
        )
    }

    private var footer: some View {
        TangemUI.Button(
            label: AttributedString(Localization.tangempayOrderDataOrderButton),
            accessibilityLabel: Localization.tangempayOrderDataOrderButton,
            action: placeOrder
        )
        .size(.x12)
        .styleType(.default)
        .horizontalLayout(.infinity)
        .isLoading(viewModel.isPlacingOrder)
        .padding(.horizontal, Constants.footerHorizontalPadding)
        .padding(.vertical, Constants.footerVerticalPadding)
        .background(alignment: .bottom) {
            BottomFadeWithBlur(backgroundColor: DesignSystem.Color.bgPrimary)
        }
    }
}

private extension TangemPayOrderCardDataView {
    enum Constants {
        static let horizontalPadding: CGFloat = 24
        static let topPadding: CGFloat = 32
        static let sectionSpacing: CGFloat = 24
        static let footerHorizontalPadding: CGFloat = 16
        static let footerVerticalPadding: CGFloat = 12
        static let focusedFieldClearance: CGFloat = 16
    }
}
