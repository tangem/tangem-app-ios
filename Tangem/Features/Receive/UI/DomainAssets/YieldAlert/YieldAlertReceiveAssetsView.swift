//
//  YieldAlertReceiveAssetsView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemUI
import TangemAssets

struct YieldAlertReceiveAssetsView: View {
    @ObservedObject var viewModel: TokenAlertReceiveAssetsViewModel

    var body: some View {
        YieldModuleActivationNoticeView(
            currencySymbol: viewModel.currencySymbol,
            buttonAction: viewModel.onGotItTapAction,
            tokenIconInfo: viewModel.tokenIconInfo
        )
    }
}
