//
//  WarningBankCardView.swift
//  Tangem
//
//  Created by Pavel Grechikhin on 07.07.2022.
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct WarningBankCardView: View {
    let confirm: () -> ()
    let decline: () -> ()

    var body: some View {
        VStack(spacing: 0) {
            Image("russia_flag")
                .padding(.top, 80)
                .padding(.leading, 10)
            
            Text("russian_bank_card_warning_title".localized)
                .font(.system(size: 20, weight: .regular))
                .padding(30)
            
            Text("russian_bank_card_warning_subtitle".localized)
                .font(.system(size: 15, weight: .regular))
                .padding(.top, 50)
                .padding(.horizontal, 30)

            HStack(spacing: 11) {
                Button(action: {
                    confirm()
                }, label: {
                    Text("common_yes".localized)
                        .font(.system(size: 15, weight: .medium))
                })
                .buttonStyle(TangemButtonStyle(colorStyle: .black, layout: .flexibleWidth))

                Button(action: {
                    decline()
                }, label: {
                    Text("common_no".localized)
                        .foregroundColor(.black)
                        .font(.system(size: 15, weight: .medium))
                })
                .buttonStyle(TangemButtonStyle(colorStyle: .gray, layout: .flexibleWidth))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 40)
        }
        .multilineTextAlignment(.center)
    }
}

struct WarningBankCardView_Previews: PreviewProvider {
    private class _PopUpModel: ObservableObject {
        @Published var show: Bool = true
    }

    static var previews: some View {
        BottomSheetView(isPresented: _PopUpModel().$show, showClosedButton: false) {
        } content: {
            WarningBankCardView {

            } decline: {

            }

        }
    }
}
