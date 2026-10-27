//
//  CollectiblesRelinkErrorSnackbar.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct CollectiblesRelinkErrorSnackbar: View {
    @ObservedObject var viewModel: CollectiblesRelinkBannerViewModel

    var body: some View {
        if let errorMessage = viewModel.errorMessage {
            TangemSnackbar(title: errorMessage)
                .icon(DesignSystem.Icons.Error.filled20)
                .iconColor(DesignSystem.Color.iconStatusError)
                .padding(.top, 8)
                .padding(.horizontal, 16)
                .onTapGesture(perform: viewModel.dismissError)
                .transition(.move(edge: .top).combined(with: .opacity).animation(.easeInOut(duration: 0.25)))
        }
    }
}
