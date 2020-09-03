//
//  ExtractView.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import TangemSdk

struct ExtractView: View {
    @ObservedObject var viewModel: ExtractViewModel
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0.0) {
                    HStack {
                        Text("send_title")
                            .font(Font.system(size: 30.0, weight: .bold, design: .default) )
                            .foregroundColor(Color.tangemTapGrayDark6)
                        Spacer()
                    }
                    .padding(.bottom)
                    HStack {
                        VStack(alignment: .leading) {
                            Text(!self.viewModel.destination.isEmpty ? "send_destination_placeholder" : " ")
                                .font(Font.system(size: 13.0, weight: .medium, design: .default))
                                .foregroundColor(Color.tangemTapGrayDark)
                            TextField("send_destination_placeholder",
                                      text: self.$viewModel.destination,
                                      onEditingChanged: { hz in
                                        
                            }) {
                                
                            }
                            .truncationMode(.middle)
                            .font(Font.system(size: 16.0, weight: .regular, design: .default))
                        }
                        Spacer()
                        Button(action: {
                            //                            if let address = self.cardViewModel.wallet?.address {
                            //                                UIPasteboard.general.string = address
                            //                            }
                        }) {
                            ZStack {
                                Circle()
                                    .frame(width: 40.0, height: 40.0, alignment: .center)
                                    .foregroundColor(Color.tangemTapBgGray)
                                Image (self.viewModel.validatedClipboard == nil ? "doc.on.clipboard" : "doc.on.clipboard.fill")
                                    .font(Font.system(size: 17.0, weight: .regular, design: .default))
                                    .foregroundColor(Color.tangemTapGrayDark6)
                            }
                        }
                        .disabled(self.viewModel.validatedClipboard == nil)
                        Button(action: {
                            self.viewModel.showQR = true
                        }) {
                            ZStack {
                                Circle()
                                    .frame(width: 40.0, height: 40.0, alignment: .center)
                                    .foregroundColor(Color.tangemTapBgGray)
                                Image ("qrcode.viewfinder")
                                    .font(Font.system(size: 22.0, weight: .regular, design: .default))
                                    .foregroundColor(Color.tangemTapGrayDark6)
                                
                            }
                        }
                        .sheet(isPresented: self.$viewModel.showQR) {
                            QRScannerView(code: self.$viewModel.destination,
                                          codeMapper: {self.viewModel.stripBlockchainPrefix($0)})
                                .edgesIgnoringSafeArea(.all)
                        }
                    }
                    Color.tangemTapGrayLight5
                        .frame(width: nil, height: 1.0, alignment: .center)
                        .padding(.top, 8.0)
                    HStack {
                        Text(self.viewModel.destinationHint?.message ?? " " )
                            .font(Font.system(size: 13.0, weight: .medium, design: .default))
                            .foregroundColor((self.viewModel.destinationHint?.isError ?? false ) ?
                                Color.red : Color.tangemTapGrayDark)
                        Spacer()
                    }
                    HStack {
                        TextField("",
                                  text: self.$viewModel.amount,
                                  onEditingChanged: { hz in
                                    
                        }) {
                            
                        }
                        .font(Font.system(size: 38.0, weight: .light, design: .default))
                        .foregroundColor(Color.tangemTapGrayDark6)
                        Spacer()
                        Button(action: {
                            
                        }) { HStack(alignment: .center, spacing: 8.0) {
                            Text("USD") //[REDACTED_TODO_COMMENT]
                                .font(Font.system(size: 38.0, weight: .light, design: .default))
                                .foregroundColor(Color.tangemTapBlue)
                            Image("arrow.up.arrow.down")
                                .font(Font.system(size: 17.0, weight: .regular, design: .default))
                                .foregroundColor(Color.tangemTapBlue)
                            }
                        }
                    }
                    .padding(.top, 25.0)
                    Color.tangemTapGrayLight5
                        .frame(width: nil, height: 1.0, alignment: .center)
                        .padding(.vertical, 8.0)
                    HStack {
                        Text(self.viewModel.destinationHint?.message ?? " " )
                            .font(Font.system(size: 13.0, weight: .medium, design: .default))
                            .foregroundColor((self.viewModel.destinationHint?.isError ?? false ) ?
                                Color.red : Color.tangemTapGrayDark)
                        Spacer()
                        Text("Balance" )
                            .font(Font.system(size: 13.0, weight: .medium, design: .default))
                            .foregroundColor(Color.tangemTapGrayDark)
                    }
                    Spacer()
                    HStack(alignment: .center, spacing: 8.0) {
                        Spacer()
                        Button(action: {
                            
                        }) { HStack(alignment: .center, spacing: 16.0) {
                            Text("details_button_send")
                            Spacer()
                            Image("arrow.right")
                        }.padding(.horizontal)
                        }
                        .buttonStyle(TangemButtonStyle(size: .big,
                                                       colorStyle: .green,
                                                       isDisabled: !self.viewModel.isSendEnabled))
                            .disabled(!self.viewModel.isSendEnabled)
                    }
                }
                .padding()
                .frame(minWidth: geometry.size.width,
                       maxWidth: geometry.size.width,
                       minHeight: geometry.size.height,
                       maxHeight: .infinity, alignment: .top)
            }
        }
        .onAppear() {
            self.viewModel.validateClipboard()
        }
    }
}

struct ExtractView_Previews: PreviewProvider {
    @State static var sdkService: TangemSdkService = {
        let service = TangemSdkService()
        service.cards[Card.testCard.cardId!] = CardViewModel(card: Card.testCard)
        return service
    }()
    
    @State static var cardViewModel = CardViewModel(card: Card.testCard)
    
    static var previews: some View {
        ExtractView(viewModel: ExtractViewModel(cardViewModel: $cardViewModel, sdkSerice: $sdkService))
    }
}
