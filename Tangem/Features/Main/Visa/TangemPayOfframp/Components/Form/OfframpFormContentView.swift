//
//  OfframpFormContentView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAccessibilityIdentifiers
import TangemAssets
import TangemLocalization
import TangemUI

struct OfframpFormContentView: View {
    @Binding var fields: [TangemPayFormField]

    let focused: FocusState<TangemPayFormField.ID?>.Binding
    let state: StateModel
    var suggestions: Suggestions?
    let action: (Action) -> Void

    @State private var keyboardHeight: CGFloat = .zero

    var body: some View {
        form
            .offrampBottomBar(pinnedBehindKeyboard: true) { continueButton }
            .keyboardToolbar {
                OfframpFormKeyboardToolbar(
                    hasFieldBefore: state.hasFieldBefore,
                    hasFieldAfter: state.hasFieldAfter,
                    action: handle
                )
            }
            .keyboardHeight(bindTo: $keyboardHeight)
    }
}

// MARK: - Form

private extension OfframpFormContentView {
    var form: some View {
        ScrollView {
            VStack(spacing: .zero) {
                fieldRows(fields[..<suggestionsSplitIndex])

                VStack(spacing: .zero) {
                    fieldRows(fields[suggestionsSplitIndex...])
                }
                .opacity(isShowingSuggestions ? .zero : 1)
                .allowsHitTesting(!isShowingSuggestions)
                .accessibilityHidden(isShowingSuggestions)
                .overlay(alignment: .top) {
                    if isShowingSuggestions, let suggestions {
                        OfframpAccountSuggestionsView(
                            suggestions: suggestions.items,
                            onSelect: suggestions.onSelect
                        )
                        .transition(.opacity)
                    }
                }
            }
            .animation(.suggestions, value: isShowingSuggestions)
            .padding(.horizontal, Constants.horizontalPadding)
            .padding(.top, Constants.topPadding)
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .safeAreaInset(edge: .bottom, spacing: .zero) {
            Color.clear.frame(height: focusedFieldClearance)
        }
        .animation(.keyboard, value: focusedFieldClearance)
    }

    func fieldRows(_ rows: ArraySlice<TangemPayFormField>) -> some View {
        ForEach(rows) { field in
            TangemPayFormFieldView(field: binding(for: field), focused: focused)
                .onChange(of: field.text) { _ in
                    action(.fieldChanged(field.id))
                }
        }
    }

    func binding(for field: TangemPayFormField) -> Binding<TangemPayFormField> {
        Binding(
            get: { fields.first { $0.id == field.id } ?? field },
            set: { updated in
                guard let index = fields.firstIndex(where: { $0.id == field.id }) else { return }

                fields[index] = updated
            }
        )
    }

    var isShowingSuggestions: Bool {
        suggestions.map { !$0.items.isEmpty } ?? false
    }

    var suggestionsSplitIndex: Int {
        guard
            let fieldID = suggestions?.fieldID,
            let index = fields.firstIndex(where: { $0.id == fieldID })
        else {
            return fields.endIndex
        }

        return fields.index(after: index)
    }

    var focusedFieldClearance: CGFloat {
        guard keyboardHeight > .zero else {
            return .zero
        }

        return OfframpFormKeyboardToolbar.height + Constants.focusedFieldMargin
    }

    var continueButton: some View {
        TangemUI.Button(
            label: Localization.commonContinue,
            accessibilityLabel: nil,
            action: { action(.continueTap) }
        )
        .size(.x12)
        .styleType(.primary)
        .horizontalLayout(.infinity)
        .disabled(!state.isContinueEnabled)
        .accessibilityIdentifier(TangemPayOfframpAccessibilityIdentifiers.formContinueButton)
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

// MARK: - Animations

private extension Animation {
    static let suggestions = Animation.curve(.easeInOutRefined, duration: 0.2)
}

// MARK: - Constants

private extension OfframpFormContentView {
    enum Constants {
        static let horizontalPadding: CGFloat = 24
        static let topPadding: CGFloat = 12
        static let focusedFieldMargin: CGFloat = 16
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

// MARK: - Suggestions

extension OfframpFormContentView {
    struct Suggestions {
        let fieldID: TangemPayFormField.ID
        let items: [OfframpAccountSuggestion]
        let onSelect: (String) -> Void
    }
}

// MARK: - Action

extension OfframpFormContentView {
    enum Action {
        case fieldChanged(TangemPayFormField.ID)
        case focusPrevious
        case focusNext
        case dismissKeyboard
        case continueTap
    }
}

// MARK: - Previews

@available(iOS 17.0, *)
#Preview("Bank Details") {
    @Previewable @State var fields: [TangemPayFormField] = [
        TangemPayFormField(id: .bankName, title: "Bank name", placeholder: "Eg., Goldman Sachs"),
        TangemPayFormField(id: .bankRegion, title: "Bank region / state", placeholder: "Not selected"),
        TangemPayFormField(id: .bankCity, title: "Bank city", placeholder: "Eg., Night City"),
        TangemPayFormField(id: .bankLine1, title: "Bank address line 1", placeholder: "Eg., Ebunike st., Apt. 32"),
        TangemPayFormField(id: .bankPostalCode, title: "Postal code", placeholder: "0000"),
    ]

    @Previewable @FocusState var focused: TangemPayFormField.ID?

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

@available(iOS 17.0, *)
#Preview("Suggestions") {
    @Previewable @State var fields: [TangemPayFormField] = [
        TangemPayFormField(id: .accountNumber, title: "Account number", placeholder: "000000000000", text: "082"),
        TangemPayFormField(id: .routingNumber, title: "Routing number", placeholder: "000000000000"),
        TangemPayFormField(id: .firstName, title: "First name", placeholder: "John"),
        TangemPayFormField(id: .lastName, title: "Last name", placeholder: "Doe"),
        TangemPayFormField(id: .city, title: "City", placeholder: "Eg., Night City"),
    ]

    @Previewable @FocusState var focused: TangemPayFormField.ID?

    let suggestions = OfframpFormContentView.Suggestions(
        fieldID: .accountNumber,
        items: [
            OfframpAccountSuggestion(
                id: "hanako",
                matchedPrefix: "082",
                accountNumberSuffix: "5200008214",
                name: "Hanako A."
            ),
            OfframpAccountSuggestion(
                id: "saburo",
                matchedPrefix: "082",
                accountNumberSuffix: "5200008215",
                name: "Saburo A."
            ),
        ],
        onSelect: { _ in }
    )

    OfframpFormContentView(
        fields: $fields,
        focused: $focused,
        state: OfframpFormContentView.StateModel(
            isContinueEnabled: false,
            hasFieldBefore: false,
            hasFieldAfter: true
        ),
        suggestions: suggestions,
        action: { _ in }
    )
    .background(DesignSystem.Color.bgPrimary.ignoresSafeArea())
}
