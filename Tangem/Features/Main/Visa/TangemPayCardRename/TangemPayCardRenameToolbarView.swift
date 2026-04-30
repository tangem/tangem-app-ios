//
//  TangemPayCardRenameToolbarView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemUI

struct TangemPayCardRenameToolbarView: View {
    @ObservedObject var renameViewModel: TangemPayCardRenameViewModel

    var body: some View {
        MainButton(
            title: Localization.commonDone,
            isLoading: renameViewModel.isLoading,
            isDisabled: renameViewModel.isSaveDisabled,
            action: renameViewModel.save
        )
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}
