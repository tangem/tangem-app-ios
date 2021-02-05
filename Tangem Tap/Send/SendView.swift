//
//  SendView.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import TangemSdk
import BlockchainSdk
import AVFoundation

struct SendView: View {
    @ObservedObject var viewModel: SendViewModel
    @Environment(\.presentationMode) var presentationMode
    let onSuccess: () -> Void
    
    private var addressHint: String {
        viewModel.isPayIdSupported ?
            "send_destination_hint".localized :
            "send_destination_hint_address".localized
    }
    
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
                    TextInputField(placeholder: self.addressHint,
                                   text: self.$viewModel.destination,
                                   suplementView: {
                                    CircleActionButton(action: {self.viewModel.pasteClipboardTapped() },
                                                       backgroundColor: .tangemTapBgGray,
                                                       imageName: self.viewModel.validatedClipboard == nil ? "doc.on.clipboard" : "doc.on.clipboard.fill",
                                                       isSystemImage: false,
                                                       imageColor: .tangemTapGrayDark6,
                                                       isDisabled: self.viewModel.validatedClipboard == nil)
                                        .disabled(self.viewModel.validatedClipboard == nil)
                                    CircleActionButton(
                                        action: {
                                            if case .denied = AVCaptureDevice.authorizationStatus(for: .video) {
                                                self.viewModel.showCameraDeniedAlert = true
                                            } else {
                                                self.viewModel.navigation.sendToQR = true
                                            }
                                        },
                                        backgroundColor: .tangemTapBgGray,
                                        imageName: "qrcode.viewfinder",
                                        isSystemImage: false,
                                        imageColor: .tangemTapGrayDark6
                                    )
                                    .sheet(isPresented: self.$viewModel.navigation.sendToQR) {
                                        QRScanView(code: self.$viewModel.destination,
                                                      codeMapper: {self.viewModel.stripBlockchainPrefix($0)})
                                            .edgesIgnoringSafeArea(.all)
                                    }
                                    .alert(isPresented: self.$viewModel.showCameraDeniedAlert) {
                                        return Alert(title: Text("common_camera_denied_alert_title"),
                                                     message: Text("common_camera_denied_alert_message"),
                                                     primaryButton: Alert.Button.default(Text("common_camera_alert_button_settings"),
                                                                                         action: {self.viewModel.openSystemSettings()}),
                                                     secondaryButton: Alert.Button.default(Text("common_ok"),
                                                                                           action: {}))
                                    }
                                   }, message: self.viewModel.destinationHint?.message ?? " " ,
                                   isErrorMessage: self.viewModel.destinationHint?.isError ?? false)
                    
                    if viewModel.isAdditionalInputEnabled {
                        if case .memo = viewModel.additionalInputFields {
                            TextInputField(placeholder: "send_extras_hint_memo".localized,
                                           text: self.$viewModel.memo,
                                           keyboardType: .numberPad,
                                           clearButtonMode: .whileEditing,
                                           message: self.viewModel.memoHint?.message ?? "",
                                           isErrorMessage: self.viewModel.memoHint?.isError ?? false)
                                .transition(.opacity)
                        }
                        
                        if case .destinationTag = viewModel.additionalInputFields {
                            TextInputField(placeholder: "send_extras_hint_destination_tag".localized,
                                           text: self.$viewModel.destinationTagStr,
                                           keyboardType: .numberPad,
                                           clearButtonMode: .whileEditing,
                                           message: self.viewModel.destinationTagHint?.message ?? "",
                                           isErrorMessage: self.viewModel.destinationTagHint?.isError ?? false)
                                .transition(.opacity)
                        }
                    }
                    
                    Group {
                        HStack {
                            CustomTextField(text: self.$viewModel.amountText,
                                            isResponder:  Binding.constant(nil),
                                            actionButtonTapped: self.$viewModel.maxAmountTapped,
                                            defaultStringToClear: "0",
                                            handleKeyboard: true,
                                            actionButton: "send_max_amount_label".localized,
                                            keyboard: UIKeyboardType.decimalPad,
                                            textColor: UIColor.tangemTapGrayDark6,
                                            font: UIFont.systemFont(ofSize: 38.0, weight: .light),
                                            placeholder: "",
                                            decimalCount: self.viewModel.inputDecimalsCount)
                            Button(action: {
                                self.viewModel.isFiatCalculation.toggle()
                            }) { HStack(alignment: .center, spacing: 8.0) {
                                Text(self.viewModel.currencyUnit)
                                    .font(Font.system(size: 38.0, weight: .light, design: .default))
                                    .foregroundColor(self.viewModel.canFiatCalculation ?
                                                        Color.tangemTapBlue : Color.tangemTapBlue.opacity(0.5))
                                Image("arrow.up.arrow.down")
                                    .font(Font.system(size: 17.0, weight: .regular, design: .default))
                                    .foregroundColor(self.viewModel.canFiatCalculation ?
                                                        Color.tangemTapBlue : Color.tangemTapBlue.opacity(0.5))
                            }
                            }
                            .disabled(!self.viewModel.canFiatCalculation)
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
                                .lineLimit(2)
                                .fixedSize(horizontal: false, vertical: true)
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
                                    Image(self.viewModel.isNetworkFeeBlockOpen ? "chevron.up" : "chevron.down")
                                        .font(Font.system(size: 14.0, weight: .medium, design: .default))
                                        .foregroundColor(Color.tangemTapGrayDark6)
                                }
                            }.padding(.vertical)
                            if self.viewModel.isNetworkFeeBlockOpen {
                                VStack(spacing: 16.0) {
                                    if self.viewModel.shoudShowFeeSelector {
                                        PickerView(contents: ["send_fee_picker_low".localized,
                                                              "send_fee_picker_normal".localized,
                                                              "send_fee_picker_priority".localized],
                                                   selection: self.$viewModel.selectedFeeLevel)
                                    }
                                    if self.viewModel.shoudShowFeeIncludeSelector {
                                        Toggle(isOn: self.$viewModel.isFeeIncluded) {
                                            Text("send_fee_include_description")
                                                .font(Font.system(size: 13.0, weight: .medium, design: .default))
                                                .foregroundColor(Color.tangemTapGrayDark6)
                                        }
                                    }
                                }
                                .padding(.vertical, 8.0)
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
                            if self.viewModel.isFeeLoading {
                                ActivityIndicatorView(color: UIColor.tangemTapGrayDark)
                                    .offset(x: 8)
                            } else {
                                Text(self.viewModel.sendFee)
                                    .font(Font.system(size: 14.0, weight: .medium, design: .default))
                                    .foregroundColor(Color.tangemTapGrayDark)
                                    .frame(height: 20)
                            }
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
                                .lineLimit(1)
                                .minimumScaleFactor(0.5)
                                .foregroundColor(Color.tangemTapGrayDark6)
                            
                        }
                        HStack{
                            Spacer()
                            Text(self.viewModel.sendTotalSubtitle)
                                .font(Font.system(size: 14.0, weight: .bold, design: .default))
                                .foregroundColor(Color.tangemTapGrayDark)
                        }
                    }
                    WarningListView(warnings: viewModel.warnings, warningButtonAction: { (index, priority) in
                        withAnimation {
                            self.viewModel.warningButtonAction(at: index, priority: priority)
                        }
                    })
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.bottom, 16)
                    HStack(alignment: .center, spacing: 8.0) {
                        Spacer()
                        TangemLongButton(isLoading: false,
                                         title: "wallet_button_send",
                                         image: "arrow.right") {
                            self.viewModel.send() {
                                DispatchQueue.main.async {
                                    let alert = Alert(title: Text("common_success"),
                                                      message: Text("send_transaction_success"),
                                                      dismissButton: Alert.Button.default(Text("common_ok"),
                                                                                          action: {
                                                                                            presentationMode.wrappedValue.dismiss()
                                                                                            onSuccess()
                                                                                          }))
                                    
                                    self.viewModel.sendError = AlertBinder(alert: alert)
                                }
                            }
                        }.buttonStyle(TangemButtonStyle(color: .green,
                                                        isDisabled: !self.viewModel.isSendEnabled))
                        .disabled(!self.viewModel.isSendEnabled)
                        .alert(item: self.$viewModel.sendError) { $0.alert }
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
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
                    .receive(on: DispatchQueue.main)) { _ in
            viewModel.onEnterForeground()
        }
    }
}


struct ExtractView_Previews: PreviewProvider {
    static var previews: some View {
        SendView(viewModel: Assembly.previewAssembly.makeSendViewModel(with: Amount(with: Blockchain.ethereum(testnet: false),
                                                                                    address: "adsfafa",
                                                                                    type: .coin,
                                                                                    value: 0.0),
                                                                       card: CardViewModel.previewCardViewModel),
                 onSuccess: {})
    }
}
