//
//  AccountTypeView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI

struct AccountTypeView: View {
    @StateObject private var viewModel: AccountTypeViewModel

    init(viewModel: @autoclosure @escaping () -> AccountTypeViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel())
    }

    var body: some View {
        AccountTypeContentView(
            state: viewModel.contentState,
            action: viewModel.handle
        )
        .background { DesignSystem.Color.bgPrimary.ignoresSafeArea() }
        .topNavigation(
            title: viewModel.title,
            subtitle: viewModel.stepSubtitle,
            onClose: viewModel.onCloseTap
        )
    }
}
