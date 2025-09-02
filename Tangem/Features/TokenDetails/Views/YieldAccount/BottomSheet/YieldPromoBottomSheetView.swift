//
//  YieldPromoBottomSheetView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI

struct YieldPromoBottomSheetView: View {
    @ObservedObject var viewModel: YieldPromoBottomSheetViewModel

    var body: some View {
        contentView.animation(.contentFrameUpdate, value: viewModel.state)
    }

    @ViewBuilder
    private var contentView: some View {
        ZStack {
            switch viewModel.state {
            case .feePolicy:
                FeePolicyView(currentFee: viewModel.networkFee, maximumFee: viewModel.maximumFee, backAction: viewModel.onShowStartEarning)
                    .transition(.content)

            case .startYearing:
                StartEarningView(
                    tokenImage: viewModel.tokenImage,
                    fee: viewModel.networkFee,
                    buttonAction: {},
                    closeAction: viewModel.onCloseTapAction,
                    showFeePolicyAction: viewModel.onShowFeePolicy
                )
                .transition(.content)
            }
        }
        .floatingSheetConfiguration { configuration in
            configuration.sheetFrameUpdateAnimation = .contentFrameUpdate
        }
    }
}

private extension AnyTransition {
    static let content = AnyTransition.asymmetric(
        insertion: .opacity.animation(.curve(.easeInOutRefined, duration: 0.3).delay(0.2)),
        removal: .opacity.animation(.curve(.easeInOutRefined, duration: 0.3))
    )
}

private extension Animation {
    static let headerOpacity = Animation.curve(.easeOutStandard, duration: 0.2)
    static let contentFrameUpdate = Animation.curve(.easeInOutRefined, duration: 0.5)
}
