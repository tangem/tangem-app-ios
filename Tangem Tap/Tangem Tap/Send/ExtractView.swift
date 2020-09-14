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
import BlockchainSdk

struct ExtractView: View {
    @ObservedObject var viewModel: ExtractViewModel
    @Environment(\.presentationMode) var presentationMode
    
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
                    Group {
                        HStack(alignment: .center) {
                            VStack(alignment: .leading, spacing: 0.0) {
                                Text(!self.viewModel.destination.isEmpty ? "send_destination_placeholder" : " ")
                                    .font(Font.system(size: 13.0, weight: .medium, design: .default))
                                    .foregroundColor(Color.tangemTapGrayDark)
                                TextField("send_destination_placeholder",
                                          text: self.$viewModel.destination,
                                          onEditingChanged: { hz in
                                            
                                }) {
                                    
                                }
                                .truncationMode(.middle)
                                .disableAutocorrection(true)
                                .font(Font.system(size: 16.0, weight: .regular, design: .default))
                                //.alignmentGuide(.textAndImage) { d in d[.bottom] / 2 }
                            }
                            Spacer()
                            Button(action: {
                                self.viewModel.pasteClipboardTapped()
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
                            //.alignmentGuide(.textAndImage) { d in d[.bottom] / 2 }
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
                            .padding(.bottom, 4.0)
                        
                        HStack {
                            Text(self.viewModel.destinationHint?.message ?? " " )
                                .font(Font.system(size: 13.0, weight: .medium, design: .default))
                                .foregroundColor((self.viewModel.destinationHint?.isError ?? false ) ?
                                    Color.red : Color.tangemTapGrayDark)
                            Spacer()
                        }
                    }
                    Group {
                        HStack {
                            CustomTextField(text: self.$viewModel.amountText,
                                            isResponder:  Binding.constant(nil),
                                            actionButtonTapped: self.$viewModel.maxAmountTapped,
                                            handleKeyboard: true,
                                            actionButton: "send_max_amount_label".localized,
                                            keyboard: UIKeyboardType.decimalPad,
                                            textColor: UIColor.tangemTapGrayDark6,
                                            font: UIFont.systemFont(ofSize: 38.0, weight: .light),
                                            placeholder: "")
                            Button(action: {
                                self.viewModel.isFiatCalculation.toggle()
                            }) { HStack(alignment: .center, spacing: 8.0) {
                                Text(self.viewModel.currencyUnit)
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
                            Text(self.viewModel.amountHint?.message ?? " " )
                                .font(Font.system(size: 13.0, weight: .medium, design: .default))
                                .foregroundColor((self.viewModel.amountHint?.isError ?? false ) ?
                                    Color.red : Color.tangemTapGrayDark)
                            Spacer()
                            Text(self.viewModel.walletTotalBalanceFormatted)
                                .font(Font.system(size: 13.0, weight: .medium, design: .default))
                                .foregroundColor(Color.tangemTapGrayDark)
                        }
                    }
                    if self.viewModel.shouldShowNetworkBlock {
                        Group {
                            HStack {
                                Text("send_network_fee_title")
                                    .font(Font.system(size: 14.0, weight: .medium, design: .default))
                                    .foregroundColor(Color.tangemTapGrayDark6)
                                Spacer()
                                Button(action: {
                                    withAnimation {
                                        self.viewModel.isNetworkFeeBlockOpen.toggle()
                                    }
                                }) {
                                    Image(self.viewModel.isNetworkFeeBlockOpen ? "chevron.compact.up" : "chevron.compact.down")
                                        .font(Font.system(size: 14.0, weight: .medium, design: .default))
                                        .foregroundColor(Color.tangemTapGrayDark6)
                                }
                            }.padding(.vertical)
                            if self.viewModel.isNetworkFeeBlockOpen {
                                VStack(spacing: 16.0) {
                                    if self.viewModel.shoudShowFeeSelector {
                                        Picker("", selection: self.$viewModel.selectedFeeLevel) {
                                            Text("send_fee_picker_low").tag(0)
                                            Text("send_fee_picker_normal").tag(1)
                                            Text("send_fee_picker_priority").tag(2)
                                        }
                                        .pickerStyle(SegmentedPickerStyle())
                                    }
                                    if self.viewModel.shoudShowFeeIncludeSelector {
                                        Toggle(isOn: self.$viewModel.isFeeIncluded) {
                                            Text("send_fee_include_description")
                                                .font(Font.system(size: 13.0, weight: .medium, design: .default))
                                                .foregroundColor(Color.tangemTapGrayLight4)
                                        }
                                    }
                                }
                                .padding(.top, 8.0)
                                .transition(.opacity)
                            }
                        }
                    }
                    Spacer()
                    VStack (spacing: 8.0) {
                        HStack{
                            Text("send_amount_label")
                                .font(Font.system(size: 14.0, weight: .medium, design: .default))
                                .foregroundColor(Color.tangemTapGrayDark6)
                            Spacer()
                            Text(self.viewModel.sendAmount)
                                .font(Font.system(size: 14.0, weight: .medium, design: .default))
                                .foregroundColor(Color.tangemTapGrayDark6)
                        }
                        HStack{
                            Text("send_fee_label")
                                .font(Font.system(size: 14.0, weight: .medium, design: .default))
                                .foregroundColor(Color.tangemTapGrayDark)
                            Spacer()
                            Text(self.viewModel.sendFee)
                                .font(Font.system(size: 14.0, weight: .medium, design: .default))
                                .foregroundColor(Color.tangemTapGrayDark)
                        }
                        Color.tangemTapGrayLight5
                            .frame(width: nil, height: 1.0, alignment: .center)
                            .padding(.vertical, 8.0)
                        HStack{
                            Text("send_total_label")
                                .font(Font.system(size: 20.0, weight: .bold, design: .default))
                                .foregroundColor(Color.tangemTapGrayDark6)
                            Spacer()
                            Text(self.viewModel.sendTotal)
                                .font(Font.system(size: 20.0, weight: .bold, design: .default))
                                .foregroundColor(Color.tangemTapGrayDark6)
                            
                        }
                        HStack{
                            Spacer()
                            Text(self.viewModel.sendTotalSubtitle)
                                .font(Font.system(size: 14.0, weight: .bold, design: .default))
                                .foregroundColor(Color.tangemTapGrayDark)
                        }
                    }
                    HStack(alignment: .center, spacing: 8.0) {
                        Spacer()
                        Button(action: {
                            self.viewModel.send() {
                                self.presentationMode.wrappedValue.dismiss()
                            }
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
                            .alert(isPresented: self.$viewModel.showErrorAlert) { () -> Alert in
                                return Alert(title: Text("common_error"),
                                             message: Text(self.viewModel.sendError!.localizedDescription),
                                             dismissButton: Alert.Button.default(Text("common_ok"),
                                                                                 action: { }))
                                
                        }
                    }
                    .padding(.top, 16.0)
                }
                .padding()
                .frame(minWidth: geometry.size.width,
                       maxWidth: geometry.size.width,
                       minHeight: geometry.size.height,
                       maxHeight: .infinity, alignment: .top)
            }
        }
        .onAppear() {
            self.viewModel.onAppear()
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
        ExtractView(viewModel: ExtractViewModel(amountToSend: Amount(with: cardViewModel.wallet!.blockchain,
                                                                     address: "adsfafa",
                                                                     type: .coin,
                                                                     value: 0.0),
                                                cardViewModel: $cardViewModel,
                                                sdkSerice: $sdkService))
    }
}
