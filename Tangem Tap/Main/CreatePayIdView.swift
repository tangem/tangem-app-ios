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
    @State private var alert: AlertBinder? = nil
    @State private var isFirstResponder : Bool? = false
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var cardViewModel: CardViewModel
    
    var body: some View {
        VStack(alignment: .leading) {
            VStack(alignment: .leading, spacing: 6.0) {
                Text("create_payid_title")
                    .font(Font.system(size: 30.0, weight: .bold, design: .default))
                    .foregroundColor(Color.tangemTapGrayDark6)
                Text(String(format: NSLocalizedString("create_payid_card_format", comment: ""), CardIdFormatter(cid: cardId).formatted()))
                    .font(Font.system(size: 13.0, weight: .medium, design: .default))
                    .foregroundColor(Color.tangemTapGrayDark)
            }
            .padding(.top, 22.0)
            .padding(.bottom, 44.0)
            HStack(alignment: .firstBaselineCustom, spacing: 0.0){
                VStack(alignment: .leading) {
                    CustomTextField(
                        text: $payIdText, //First responder custom shit
                        isResponder:  $isFirstResponder,
                        actionButtonTapped: Binding.constant(true),
                        placeholder: NSLocalizedString("create_payid_placeholder", comment: ""))
                        //                        TextField("create_payid_placeholder", text: $payIdText)
                        //                            .font(Font.system(size: 16.0, weight: .regular, design: .default))
                        // .foregroundColor(Color("tangem_tap_gray_dark"))
                        .alignmentGuide(.firstBaselineCustom) { d in
                            d[.bottom] / 2 } //First responder custom shit
                        //   .disableAutocorrectiontrue)
                        .onAppear {
                            self.isFirstResponder = true
                    }
                    Color.tangemTapGrayLight5
                        .frame(width: 180, height: 1.0, alignment: .center)
                }
                
                Text("create_payid_domain")
                    .font(Font.system(size: 16.0, weight: .regular, design: .default))
                    .foregroundColor(Color.tangemTapGrayDark4)
                    .alignmentGuide(.firstBaselineCustom) { d in
                        d[.bottom] / 2 + 0.35 } //First responder custom shit
                    .padding(.trailing)
            }
            Spacer()
            HStack {
                Text("create_payid_info")
                    .font(Font.system(size: 14.0, weight: .medium, design: .default))
                    .foregroundColor(Color.tangemTapGrayDark)
                    .multilineTextAlignment(.leading)
                    .lineLimit(4)
                    .padding(.trailing)
                Spacer(minLength: 40.0)
            }
            .padding(.bottom, 32.0)
            .fixedSize(horizontal: false, vertical: true)
            TangemButton(isLoading: self.isLoading, title: "create_payid_button_title", image: "arrow.right") {
                if self.isLoading {
                    return
                }
                
                self.isLoading = true
                self.cardViewModel.createPayID(self.payIdText) { result in
                    self.isLoading = false
                    switch result {
                    case .success:
                        self.alert = AlertBinder(alert:  Alert(title: Text("common_success"),
                                                               message: Text("create_payid_success_message"),
                                                               dismissButton: Alert.Button.default(Text("common_ok"), action: {
                                                                self.presentationMode.wrappedValue.dismiss()
                                                               })))
                    case .failure(let error):
                        self.alert = error.alertBinder
                    }
                }
            }.buttonStyle(TangemButtonStyle(size: .big, colorStyle: .black, isDisabled: payIdText.isEmpty))
                .padding(.bottom)
                .disabled(payIdText.isEmpty)
        }
        .padding(.horizontal)
        .keyboardAdaptive()
        .alert(item: self.$alert) { $0.alert }
    }
}


struct CreatePayIdView_Previews: PreviewProvider {
    @State static var cardViewModel = CardViewModel(card: Card.testCard)
    static var previews: some View {
        CreatePayIdView(cardId: "CB23 4344 5455 6544")
            .environmentObject(cardViewModel)
    }
}
