//
//  SendNewAmountCompactView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import Combine
import TangemUI
import TangemAssets
import TangemLocalization

struct SendNewAmountCompactView: View {
    @ObservedObject var viewModel: SendNewAmountCompactViewModel

    var body: some View {
        ZStack(alignment: .center) {
            VStack(spacing: .zero) {
                Button(action: viewModel.userDidTapAmount) {
                    SendTokenAmountCompactView(viewModel: viewModel.sendAmountCompactViewModel)
                }

                if let receiveTokenViewModel = viewModel.sendReceiveTokenCompactViewModel {
                    Button(action: viewModel.userDidTapReceiveTokenAmount) {
                        SendTokenAmountCompactView(viewModel: receiveTokenViewModel)
                    }
                }
            }

            if let separatorStyle = viewModel.sendAmountsSeparator {
                SendNewAmountCompactViewSeparator(style: separatorStyle)
            }
        }
    }
}
