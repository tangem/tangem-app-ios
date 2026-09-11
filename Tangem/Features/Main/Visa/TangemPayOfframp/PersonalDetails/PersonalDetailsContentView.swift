//
//  PersonalDetailsContentView.swift
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

struct PersonalDetailsContentView: View {
    @Binding var fields: [PersonalDetailsField]

    let focused: FocusState<PersonalDetailsField.ID?>.Binding
    let state: StateModel
    let action: (Action) -> Void

    @State private var keyboardHeight: CGFloat = .zero
    @State private var bottomSafeAreaInset: CGFloat = .zero

    var body: some View {
        form
            .offrampBottomBar { continueButton }
            .keyboardToolbar {
                PersonalDetailsKeyboardToolbar(
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

private extension PersonalDetailsContentView {
    var form: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: .zero) {
                    ForEach($fields) { $field in
                        PersonalDetailsFieldView(field: $field, focused: focused)
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

        return max(.zero, keyboardHeight - bottomSafeAreaInset) + PersonalDetailsKeyboardToolbar.height
    }

    func scroll(to id: PersonalDetailsField.ID?, using proxy: ScrollViewProxy) {
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

    func handle(_ toolbarAction: PersonalDetailsKeyboardToolbar.Action) {
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

private extension PersonalDetailsContentView {
    enum Constants {
        static let horizontalPadding: CGFloat = 24
        static let topPadding: CGFloat = 12
        static let focusedFieldClearance: CGFloat = 16
    }
}

// MARK: - State

extension PersonalDetailsContentView {
    struct StateModel {
        let isContinueEnabled: Bool
        let hasFieldBefore: Bool
        let hasFieldAfter: Bool
    }
}

// MARK: - Action

extension PersonalDetailsContentView {
    enum Action {
        case fieldChanged(PersonalDetailsField.ID)
        case focusPrevious
        case focusNext
        case dismissKeyboard
        case continueTap
    }
}

// MARK: - Previews

#if DEBUG
private struct PersonalDetailsContentPreview: View {
    @State private var fields: [PersonalDetailsField]
    @FocusState private var focused: PersonalDetailsField.ID?

    init(fields: [PersonalDetailsField]) {
        _fields = State(initialValue: fields)
    }

    var body: some View {
        PersonalDetailsContentView(
            fields: $fields,
            focused: $focused,
            state: PersonalDetailsContentView.StateModel(
                isContinueEnabled: fields.allSatisfy { $0.currentError == nil },
                hasFieldBefore: focused != nil && focused != fields.first?.id,
                hasFieldAfter: focused != nil && focused != fields.last?.id
            ),
            action: { _ in }
        )
        .background(DesignSystem.Color.bgPrimary.ignoresSafeArea())
    }
}

private extension PersonalDetailsContentPreview {
    static func personalFields(filled: Bool) -> [PersonalDetailsField] {
        make(
            names: [
                (.firstName, "First name", "John", "John"),
                (.lastName, "Last name", "Doe", "Doe"),
            ],
            filled: filled
        )
    }

    static func businessFields() -> [PersonalDetailsField] {
        make(
            names: [(.businessName, "Business name", "Eg., Night City Inc.", "Night City Inc.")],
            filled: false
        )
    }

    static func make(
        names: [(PersonalDetailsField.ID, String, String, String)],
        filled: Bool
    ) -> [PersonalDetailsField] {
        let rows: [(PersonalDetailsField.ID, String, String, String)] =
            [
                (.accountNumber, "Account number", "000000000000", "1234567890"),
                (.routingNumber, "Routing number", "000000000000", "021000021"),
            ]
            + names
            + [
                (.countryCode, "Country", "Eg., US", "US"),
                (.region, "Region / state", "Eg., CA", "NY"),
                (.city, "City", "Eg., Night City", "New York"),
                (.line1, "Address line 1", "Eg., Ebunike st., Apt. 32", "123 Main St"),
                (.line2, "Address line 2", "Eg., Ebunike st., Apt. 32", ""),
                (.postalCode, "Postal code", "0000", "10001"),
            ]

        return rows.map { id, title, placeholder, value in
            PersonalDetailsField(id: id, title: title, placeholder: placeholder, text: filled ? value : "")
        }
    }
}

#Preview("Personal — empty") {
    PersonalDetailsContentPreview(fields: PersonalDetailsContentPreview.personalFields(filled: false))
}

#Preview("Personal — filled") {
    PersonalDetailsContentPreview(fields: PersonalDetailsContentPreview.personalFields(filled: true))
}

#Preview("Business — empty") {
    PersonalDetailsContentPreview(fields: PersonalDetailsContentPreview.businessFields())
}

#Preview("Blur error") {
    PersonalDetailsContentPreview(
        fields: PersonalDetailsContentPreview.personalFields(filled: false).map { field in
            var field = field
            field.text = field.id == .accountNumber ? "000000000000000000" : field.text
            field.error = field.id == .accountNumber ? .invalidFormat : nil
            return field
        }
    )
}
#endif
