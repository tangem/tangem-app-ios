//
//  CreatePayIdView.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct CreatePayIdView: View {
    var cardId: String
    @State var payIdText: String
    @State private var isFirstResponder : Bool? = false
    
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
            VStack {
                Spacer()
                HStack(alignment: .firstBaselineCustom, spacing: 0.0){
                    VStack(alignment: .leading) {
                        CustomTextField(text: $payIdText, //First responder custom shit
                            isResponder:  $isFirstResponder,
                            isSecured: false,
                            keyboard: .default,
                            placeholder: NSLocalizedString("create_payid_placeholder", comment: ""))
                            .frame(width: 180, height: 20.0, alignment: .center )
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
            }
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
                              
                          }) { HStack(alignment: .center, spacing: 16.0) {
                              Text("create_payid_button_title")
                              Spacer()
                              Image("arrow.right")
                          }
                          .padding(.horizontal)
                          }
                          .buttonStyle(TangemButtonStyle(size: .big, colorStyle: .black))
                          .padding(.bottom)
        }
        .padding(.horizontal)
    .keyboardAdaptive()
    }
}


struct CreatePayIdView_Previews: PreviewProvider {
    static var previews: some View {
        CreatePayIdView(cardId: "CB23 4344 5455 6544", payIdText: "")
    }
}
