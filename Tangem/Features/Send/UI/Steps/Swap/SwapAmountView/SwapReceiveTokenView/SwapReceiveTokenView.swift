//
//  SwapReceiveTokenView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemAssets
import TangemUIUtils
import TangemUI

struct SwapReceiveTokenView: View {
    @ObservedObject private var viewModel: SwapReceiveTokenViewModel
    private var didTapChangeCurrency: () -> Void = {}
    private var didTapNetworkFeeInfoButton: ((_ message: String) -> Void)?

    init(viewModel: SwapReceiveTokenViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ExpressCurrencyView(viewModel: viewModel.expressCurrencyViewModel) {
            LoadableTextView(
                state: viewModel.cryptoAmountState,
                font: Fonts.Regular.title1,
                textColor: Colors.Text.primary1,
                loaderSize: CGSize(width: 102, height: 24),
                prefix: "~"
            )
        }
        .didTapChangeCurrency(didTapChangeCurrency)
        .didTapNetworkFeeInfoButton { type in
            didTapNetworkFeeInfoButton?(type.message)
        }
    }
}

// MARK: - Setupable

extension SwapReceiveTokenView: Setupable {
    func didTapChangeCurrency(_ block: @escaping () -> Void) -> Self {
        map { $0.didTapChangeCurrency = block }
    }

    func didTapNetworkFeeInfoButton(_ block: @escaping (_ message: String) -> Void) -> Self {
        map { $0.didTapNetworkFeeInfoButton = block }
    }
}
