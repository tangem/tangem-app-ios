//
//  TangemPayWithdrawNoteSheetView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUI
import TangemAssets
import TangemLocalization

struct TangemPayWithdrawNoteSheetView: View {
    var viewModel: TangemPayWithdrawNoteSheetViewModel

    var body: some View {
        VStack(spacing: 24) {
            Assets.warningIcon.image
                .resizable()
                .frame(width: 32, height: 32)
                .padding(12)
                .background(Circle().fill(Colors.Icon.attention.opacity(0.1)))
                .padding(.top, 32)

            VStack(spacing: 12) {
                Text(Localization.tangempayWithdrawalNoteTitle)
                    .style(
                        Fonts.BoldStatic.title3,
                        color: Colors.Text.primary1
                    )

                Text(Localization.tangempayWithdrawalNoteDescription)
                    .style(
                        Fonts.RegularStatic.subheadline,
                        color: Colors.Text.secondary
                    )
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 16)

            MainButton(settings: viewModel.gotItButton)
                .padding(.bottom, 8)
        }
        .overlay(alignment: .topTrailing) {
            CircleButton
                .close(action: viewModel.close)
                .size(.small)
                .padding(.top, 8)
        }
        .padding(.bottom, 12)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity)
    }
}
