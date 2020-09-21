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
    @State var payIdText: String = ""
    @State var isLoading: Bool = false
    @State var showAlert: Bool = false
    @State var payIdError: Error? = nil
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
            Spacer()
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
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                    self.showAlert = true
                                }                        }
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
                    .lineLimit(2)
                    .padding(.trailing)
                Spacer(minLength: 100.0)
            }
            .padding(.bottom, 32.0)
            .fixedSize(horizontal: false, vertical: true)
            Button(action: {
                if self.isLoading {
                    return
                }
                
                self.isLoading = true
                self.cardViewModel.createPayID(self.payIdText) { result in
                    self.isLoading = false
                    switch result {
                    case .success:
                        self.showAlert = true
                    case .failure(let error):
                        self.payIdError = error
                        self.showAlert = true
                    }
                }
                
                }
            ) {
                if self.isLoading {
                    ActivityIndicatorView(isAnimating: true, style: .large)
                } else {
                    HStack(alignment: .center, spacing: 16.0) {
                        Text("create_payid_button_title")
                        Spacer()
                        Image("arrow.right")
                    }
                        .padding(.horizontal)
                    }
            }
            .buttonStyle(TangemButtonStyle(size: .big, colorStyle: .black, isDisabled: payIdText.isEmpty))
            .padding(.bottom)
            .disabled(payIdText.isEmpty)
            .alert(isPresented: $showAlert) { () -> Alert in
                if let error = self.payIdError {
                    return Alert(title: Text("common_error"),
                          message: Text(error.localizedDescription),
                          dismissButton: Alert.Button.default(Text("common_ok"), action: {
                          }))
                } else {
                    return Alert(title: Text("common_success"),
                          message: Text("create_payid_success_message"),
                          dismissButton: Alert.Button.default(Text("common_ok"), action: {
                           // self.presentationMode.wrappedValue.dismiss()
                          }))
                }
            }
        }
        .padding(.horizontal)
        .keyboardAdaptive()
    }
}


struct CreatePayIdView_Previews: PreviewProvider {
    @State static var cardViewModel = CardViewModel(card: Card.testCard)
    static var previews: some View {
        CreatePayIdView(cardId: "CB23 4344 5455 6544")
        .environmentObject(cardViewModel)
    }
}
