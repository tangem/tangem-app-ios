//
//  OfframpFormContentView.swift
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

struct OfframpFormContentView: View {
    @Binding var fields: [OfframpFormField]

    let focused: FocusState<OfframpFormField.ID?>.Binding
    let state: StateModel
    let action: (Action) -> Void

    @State private var keyboardHeight: CGFloat = .zero
    @State private var bottomSafeAreaInset: CGFloat = .zero

    var body: some View {
        form
            .offrampBottomBar { continueButton }
            .keyboardToolbar {
                OfframpFormKeyboardToolbar(
                    hasFieldBefore: state.hasFieldBefore,
                    hasFieldAfter: state.hasFieldAfter,
                    action: handle
                )
            }
            .ignoresSafeArea(.keyboard)
            .keyboardHeight(bindTo: $keyboardHeight)
            .readGeometry(\.safeAreaInsets.bottom, bindTo: $bottomSafeAreaInset)
    }
}

// MARK: - Form

private extension OfframpFormContentView {
    var form: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: .zero) {
                    ForEach($fields) { $field in
                        OfframpFormFieldView(field: $field, focused: focused)
                            .id(field.id)
                            .onChange(of: field.text) { _ in
                                action(.fieldChanged(field.id))
                            }
                    }
                }
                .padding(.horizontal, Constants.horizontalPadding)
                .padding(.top, Constants.topPadding)
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.interactively)
            .safeAreaInset(edge: .bottom, spacing: .zero) {
                Color.clear.frame(height: bottomClearance)
            }
            .onChange(of: focused.wrappedValue) { id in
                scroll(to: id, using: proxy)
            }
            .onChange(of: bottomClearance) { _ in
                scroll(to: focused.wrappedValue, using: proxy)
            }
        }
    }

    var bottomClearance: CGFloat {
        guard keyboardHeight > .zero else {
            return Constants.focusedFieldClearance
        }

        return max(.zero, keyboardHeight - bottomSafeAreaInset) + OfframpFormKeyboardToolbar.height
    }

    func scroll(to id: OfframpFormField.ID?, using proxy: ScrollViewProxy) {
        guard let id else { return }

        withAnimation(.easeInOut) {
            proxy.scrollTo(id, anchor: .center)
        }
    }

    var continueButton: some View {
        TangemUI.Button(
            label: Localization.commonContinue,
            accessibilityLabel: nil,
            action: { action(.continueTap) }
        )
        .size(.x12)
        .styleType(.default)
        .horizontalLayout(.infinity)
        .disabled(!state.isContinueEnabled)
    }

    func handle(_ toolbarAction: OfframpFormKeyboardToolbar.Action) {
        switch toolbarAction {
        case .focusPrevious:
            action(.focusPrevious)
        case .focusNext:
            action(.focusNext)
        case .dismissKeyboard:
            action(.dismissKeyboard)
        }
    }
}

// MARK: - Constants

private extension OfframpFormContentView {
    enum Constants {
        static let horizontalPadding: CGFloat = 24
        static let topPadding: CGFloat = 12
        static let focusedFieldClearance: CGFloat = 16
    }
}

// MARK: - State

extension OfframpFormContentView {
    struct StateModel {
        let isContinueEnabled: Bool
        let hasFieldBefore: Bool
        let hasFieldAfter: Bool
    }
}

// MARK: - Action

extension OfframpFormContentView {
    enum Action {
        case fieldChanged(OfframpFormField.ID)
        case focusPrevious
        case focusNext
        case dismissKeyboard
        case continueTap
    }
}

// MARK: - Previews

@available(iOS 17.0, *)
#Preview {
    @Previewable @State var fields: [OfframpFormField] = [
        OfframpFormField(id: .bankName, title: "Bank name", placeholder: "Eg., Goldman Sachs"),
        OfframpFormField(id: .bankRegion, title: "Bank region / state", placeholder: "Not selected"),
        OfframpFormField(id: .bankCity, title: "Bank city", placeholder: "Eg., Night City"),
        OfframpFormField(id: .bankLine1, title: "Bank address line 1", placeholder: "Eg., Ebunike st., Apt. 32"),
        OfframpFormField(id: .bankPostalCode, title: "Postal code", placeholder: "0000"),
    ]

    @Previewable @FocusState var focused: OfframpFormField.ID?

    OfframpFormContentView(
        fields: $fields,
        focused: $focused,
        state: OfframpFormContentView.StateModel(
            isContinueEnabled: fields.allSatisfy { $0.currentError == nil },
            hasFieldBefore: focused != nil && focused != fields.first?.id,
            hasFieldAfter: focused != nil && focused != fields.last?.id
        ),
        action: { _ in }
    )
    .background(DesignSystem.Color.bgPrimary.ignoresSafeArea())
}
