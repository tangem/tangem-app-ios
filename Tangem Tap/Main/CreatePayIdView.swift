//
//  CreatePayIdView.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import TangemSdk

struct CreatePayIdView: View {
    var cardId: String
    @State private var payIdText: String = ""
    @State private var isLoading: Bool = false
    @State private var isAppeared: Bool = false
    @State private var alert: AlertBinder? = nil
    @State private var isFirstResponder : Bool? = false
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var cardViewModel: CardViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
                Text("wallet_create_payid")
                    .font(Font.system(size: 30.0, weight: .bold, design: .default))
                    .foregroundColor(Color.tangemTapGrayDark6)
                    .padding(.top, 22.0)
                Text(String(format: NSLocalizedString("wallet_create_payid_card_format", comment: ""), CardIdFormatter(cid: cardId).formatted()))
                    .font(Font.system(size: 13.0, weight: .medium, design: .default))
                    .foregroundColor(Color.tangemTapGrayDark)
                    .padding(.bottom, 22.0)
            HStack(alignment: .firstBaselineCustom, spacing: 0.0) {
                VStack(alignment: .leading) {
                    CustomTextField(
                        text: $payIdText, //First responder custom shit
                        isResponder:  $isFirstResponder,
                        actionButtonTapped: Binding.constant(true),
                        placeholder: NSLocalizedString("wallet_create_payid_hint", comment: ""))
                        //                        TextField("wallet_create_payid_hint", text: $payIdText)
                        //                            .font(Font.system(size: 16.0, weight: .regular, design: .default))
                        // .foregroundColor(Color("tangem_tap_gray_dark"))
                        .alignmentGuide(.firstBaselineCustom) { d in
                            d[.bottom] / 2 } //First responder custom shit
                        //   .disableAutocorrectiontrue)
                    Color.tangemTapGrayLight5
                        .frame(height: 1.0, alignment: .center)
                }
                
                Text("wallet_create_payid_domain")
                    .font(Font.system(size: 16.0, weight: .regular, design: .default))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .foregroundColor(Color.tangemTapGrayDark4)
                    .alignmentGuide(.firstBaselineCustom) { d in
                        d[.bottom] / 2 + 0.35 } //First responder custom shit
                    .padding(.trailing)
            }
            Spacer()
            HStack {
                Text("wallet_create_payid_info")
                    .font(Font.system(size: 14.0, weight: .medium, design: .default))
                    .foregroundColor(Color.tangemTapGrayDark)
                    .multilineTextAlignment(.leading)
                    .lineLimit(4)
                    .padding(.trailing)
                Spacer(minLength: 40.0)
            }
            .padding(.bottom, 32.0)
            .fixedSize(horizontal: false, vertical: true)
            TangemLongButton(isLoading: self.isLoading,
                             title: "wallet_create_payid_button_title",
                             image: "arrow.right") {
                if self.isLoading {
                    return
                }
                
                self.isLoading = true
                self.cardViewModel.createPayID(self.payIdText) { result in
                    self.isLoading = false
                    switch result {
                    case .success:
                        self.alert = AlertBinder(alert:  Alert(title: Text("common_success"),
                                                               message: Text("wallet_create_payid_success_message"),
                                                               dismissButton: Alert.Button.default(Text("common_ok"), action: {
                                                                self.presentationMode.wrappedValue.dismiss()
                                                               })))
                    case .failure(let error):
                        self.alert = error.alertBinder
                    }
                }
            }
            .buttonStyle(TangemButtonStyle(color: .black,
                                            isDisabled: payIdText.isEmpty))
                .padding(.bottom)
                .disabled(payIdText.isEmpty)
        }
        .padding(.horizontal)
        .keyboardAdaptive(animated: $isAppeared)
        .onWillAppear {
            self.isFirstResponder = true          
        }
        .onWillDisappear {
            self.isFirstResponder = false
        }
        .onDidAppear {
            self.isAppeared = true
        }
        .alert(item: self.$alert) { $0.alert }
    }
}


struct CreatePayIdView_Previews: PreviewProvider {
    @State static var cardViewModel = CardViewModel.previewCardViewModel
    static var previews: some View {
        CreatePayIdView(cardId: "CB23 4344 5455 6544")
            .previewLayout(.fixed(width: 320.0, height: 568))
            .environmentObject(cardViewModel)
    }
}
