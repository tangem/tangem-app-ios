//
//  _MainFooterView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

// [REDACTED_TODO_COMMENT]
struct _MainFooterView: View {
    var body: some View {
        VStack(spacing: 0.0) {
            FixedSpacer(height: Constants.spacerLength, length: Constants.spacerLength)

            ManageTokensBottomSheetHeaderView(searchText: .constant(""))
                .cornerRadius(24.0, corners: [.topLeft, .topRight]) // Replicates corner radius in `BottomScrollableSheet`
                .bottomScrollableSheetGrabber()
                .bottomScrollableSheetShadow()
        }
    }
}

// MARK: - Constants

private extension _MainFooterView {
    enum Constants {
        static let spacerLength = 14.0
    }
}
