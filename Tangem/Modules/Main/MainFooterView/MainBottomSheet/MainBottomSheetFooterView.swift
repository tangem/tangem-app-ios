//
//  MainBottomSheetFooterView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct MainBottomSheetFooterView: View {
    var body: some View {
        VStack(spacing: 0.0) {
            FixedSpacer(height: Constants.spacerLength, length: Constants.spacerLength)

            // `MainBottomSheetHeaderInputView` is used here as a dummy non-interactive placeholder,
            // by setting `allowsHitTestingForTextField` property to false
            MainBottomSheetHeaderInputView(
                searchText: .constant(""),
                isTextFieldFocused: .constant(false),
                allowsHitTestingForTextField: false
            )
            .bottomScrollableSheetCornerRadius()
            .bottomScrollableSheetGrabber()
            .bottomScrollableSheetShadow()
        }
    }
}

// MARK: - Constants

private extension MainBottomSheetFooterView {
    enum Constants {
        static let spacerLength = 14.0
    }
}
