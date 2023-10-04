//
//  ManageTokensBottomSheetHeaderView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

#if ALPHA_OR_BETA
@available(*, deprecated, message: "Test only, remove if not needed")
struct ManageTokensBottomSheetHeaderView: View {
    @Binding private var searchText: String

    init(
        searchText: Binding<String>
    ) {
        _searchText = searchText
    }

    var body: some View {
        TextField(Localization.commonSearch, text: $searchText)
            .frame(height: 46.0)
            .padding(.horizontal, 12.0)
            .background(Colors.Field.primary)
            .cornerRadius(14.0)
            .padding(.horizontal, 16.0)
            .padding(.top, 20.0)
            .frame(height: Constants.headerHeight, alignment: .top)
            .background(Colors.Background.primary)
    }
}

// MARK: - Constants

extension ManageTokensBottomSheetHeaderView {
    enum Constants {
        static let headerHeight = 100.0
    }
}
#endif // ALPHA_OR_BETA
