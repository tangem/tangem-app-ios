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
            Image("russia_flag")
                .padding(.top, 80)
                .padding(.leading, 10)

            Text("russian_bank_card_warning_title".localized)
                .font(.system(size: 20, weight: .regular))
                .padding(30)

            Text("russian_bank_card_warning_subtitle".localized)
                .fixedSize(horizontal: false, vertical: true)
                .font(.system(size: 15, weight: .regular))
                .padding(.top, 50)
                .padding([.horizontal, .bottom], 30)

            HStack(spacing: 11) {
                Button(action: {
                    viewModel.confirmCallback()
                }, label: {
                    Text("common_yes".localized)
                        .font(.system(size: 15, weight: .medium))
                })
                .buttonStyle(TangemButtonStyle(colorStyle: .black, layout: .flexibleWidth))

                Button(action: {
                    viewModel.declineCallback()
                }, label: {
                    Text("common_no".localized)
                        .foregroundColor(.black)
                        .font(.system(size: 15, weight: .medium))
                })
                .buttonStyle(TangemButtonStyle(colorStyle: .gray, layout: .flexibleWidth))
            }
            .padding(.horizontal, 16)
        }
        .multilineTextAlignment(.center)
        .onAppear(perform: viewModel.onAppear)
    }
}

struct WarningBankCardView_Previews: PreviewProvider {
    static var previews: some View {
        WarningBankCardView(viewModel: WarningBankCardViewModel(confirmCallback: { }, declineCallback: { }))
    }
}
