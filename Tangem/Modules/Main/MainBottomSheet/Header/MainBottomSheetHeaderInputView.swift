//
//  MainBottomSheetHeaderInputView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

/// Header UI component containing an input field.
/// - Note: Text field focus state control is supported on iOS 15 and above.
struct MainBottomSheetHeaderInputView: View {
    @Binding var searchText: String

    let isTextFieldFocused: Binding<Bool>

    let textFieldAllowsHitTesting: Bool

    var body: some View {
        if #available(iOS 15.0, *) {
            FocusableWrapperView(content: textField, isFocused: isTextFieldFocused)
        } else {
            textField
        }
    }

    @ViewBuilder
    private var textField: some View {
        TextField(Localization.commonSearch, text: $searchText)
            .allowsHitTesting(textFieldAllowsHitTesting)
            .frame(height: 46.0)
            .padding(.horizontal, 12.0)
            .background(Colors.Field.primary)
            .cornerRadius(14.0)
            .padding(.horizontal, 16.0)
            .padding(.top, Constants.verticalInset)
            .padding(.bottom, max(UIApplication.safeAreaInsets.bottom, Constants.verticalInset))
            .background(Colors.Background.primary)
    }
}

// MARK: - Auxiliary types

@available(iOS 15.0, *)
private extension MainBottomSheetHeaderInputView {
    private struct FocusableWrapperView<Content>: View where Content: View {
        private let content: Content

        @Binding private var isFocusedExternal: Bool

        @FocusState private var isFocusedInternal: Bool

        var body: some View {
            content
                .focused($isFocusedInternal)
                .onChange(of: isFocusedExternal) { newValue in
                    // External -> internal focused state sync (only if needed)
                    if isFocusedInternal != newValue {
                        isFocusedInternal = newValue
                    }
                }
                .onChange(of: isFocusedInternal) { newValue in
                    // Internal -> external focused state sync (only if needed)
                    if isFocusedExternal != newValue {
                        isFocusedExternal = newValue
                    }
                }
        }

        init(
            content: Content,
            isFocused: Binding<Bool>
        ) {
            self.content = content
            _isFocusedExternal = isFocused
        }
    }
}

// MARK: - Constants

private extension MainBottomSheetHeaderInputView {
    enum Constants {
        static let verticalInset = 20.0
    }
}
