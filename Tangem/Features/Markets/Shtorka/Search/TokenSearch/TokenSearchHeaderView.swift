//
//  TokenSearchHeaderView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

// [STUB] Delete this comment when implemented.
//
// TokenSearchHeaderView is the search field wrapper for the global search screen.
// It is the designated SWAP POINT for the future Design System search field component.
//
// Current implementation: thin wrapper around MainBottomSheetHeaderView, which uses
// CustomSearchBar (Modules/TangemUI/Components/CustomSearchBar.swift) with legacy styling.
//
// When the DS search field is ready (from Figma):
//   1. Replace the body of this view with the new DS component
//   2. Keep binding to MainBottomSheetHeaderViewModel (same SearchInput event model)
//   3. No other files need to change — this is the only place the search field is referenced
//      in the global search flow
//
// The DS search field should use:
//   - Color.Tangem.Field.* for background
//   - Font.Tangem.Body16.regular for input text
//   - Color.Tangem.Text.Neutral.* for text colors
//   - Color.Tangem.Graphic.Neutral.* for icons
//   - SizeUnit spacing
//   - Placeholder: "Search assets and more" (per BF-01 spec)
//   - Return key type: .search (iOS)
//
// See: Modules/TangemUI/DesignSystem/ for existing DS components patterns
// See: MainBottomSheetHeaderInputView for current integration with FocusState
struct TokenSearchHeaderView: View {
    @ObservedObject var viewModel: MainBottomSheetHeaderViewModel

    var body: some View {
        // [STUB] Delete this body when implemented — replace with DS search field.
        MainBottomSheetHeaderView(viewModel: viewModel)
    }
}
