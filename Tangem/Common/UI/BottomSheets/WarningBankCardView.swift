//
//  WarningBankCardView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct WarningBankCardView: View {
    let viewModel: WarningBankCardViewModel

    var body: some View {
        VStack(spacing: 0) {
            Assets.russiaFlag.image
                .padding(.top, 80)
                .padding(.leading, 10)

            Text(Localization.russianBankCardWarningTitle)
                .font(.system(size: 20, weight: .regular))
                .padding(30)

            Text(Localization.russianBankCardWarningSubtitle)
                .fixedSize(horizontal: false, vertical: true)
                .font(.system(size: 15, weight: .regular))
                .padding(.top, 50)
                .padding([.horizontal, .bottom], 30)

            HStack(spacing: 11) {
                MainButton(
                    title: Localization.commonYes,
                    action: viewModel.confirmCallback
                )

                MainButton(
                    title: Localization.commonNo,
                    style: .secondary,
                    action: viewModel.declineCallback
                )
            }
            .padding(.horizontal, 16)
        }
        .multilineTextAlignment(.center)
        .onAppear(perform: viewModel.onAppear)
    }
}

struct WarningBankCardView_Previews: PreviewProvider {
    static var previews: some View {
        WarningBankCardView(viewModel: WarningBankCardViewModel(confirmCallback: {}, declineCallback: {}))
    }
}
