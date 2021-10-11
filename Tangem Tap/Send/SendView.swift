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
import Moya

struct SendView: View {
    @ObservedObject var viewModel: SendViewModel
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var navigation: NavigationCoordinator
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
                                    if !viewModel.isSellingCrypto {
                                        CircleActionButton(action: {self.viewModel.pasteClipboardTapped() },
                                                           backgroundColor: .tangemTapBgGray,
                                                           imageName: self.viewModel.validatedClipboard == nil ? "doc.on.clipboard" : "doc.on.clipboard.fill",
                                                           isSystemImage: true,
                                                           imageColor: .tangemTapGrayDark6,
                                                           isDisabled: self.viewModel.validatedClipboard == nil)
                                            .accessibility(label: Text(self.viewModel.validatedClipboard == nil ? "voice_over_nothing_to_paste" : "voice_over_paste_from_clipboard"))
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
                                            isSystemImage: true,
                                            imageColor: .tangemTapGrayDark6
                                        )
                                        .accessibility(label: Text("voice_over_scan_qr_with_address"))
                                        .sheet(isPresented: self.$viewModel.navigation.sendToQR) {
                                            QRScanView(code: self.$viewModel.scannedQRCode)
                                                .edgesIgnoringSafeArea(.all)
                                        }
                                        .cameraAccessDeniedAlert($viewModel.showCameraDeniedAlert)
                                    }
                                   },
                                   message: self.viewModel.destinationHint?.message ?? " " ,
                                   isErrorMessage: self.viewModel.destinationHint?.isError ?? false)
                        .disabled(viewModel.isSellingCrypto)
                    
                    if viewModel.isAdditionalInputEnabled {
                        if case .memo = viewModel.additionalInputFields {
                            TextInputField(placeholder: self.viewModel.memoPlaceholder,
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
                                            textColor: viewModel.isSellingCrypto ? UIColor.tangemTapGrayDark6.withAlphaComponent(0.6) : UIColor.tangemTapGrayDark6,
                                            font: UIFont.systemFont(ofSize: 38.0, weight: .light),
                                            placeholder: "",
                                            decimalCount: self.viewModel.inputDecimalsCount)
                                .disabled(viewModel.isSellingCrypto)
                            Button(action: {
                                if !viewModel.isSellingCrypto {
                                    self.viewModel.isFiatCalculation.toggle()
                                }
                            }) { HStack(alignment: .center, spacing: 8.0) {
                                Text(self.viewModel.currencyUnit)
                                    .font(Font.system(size: 38.0, weight: .light, design: .default))
                                    .foregroundColor(!viewModel.isSellingCrypto ?
                                                        Color.tangemTapBlue : Color.tangemTapGrayDark6.opacity(0.5))
                                if !viewModel.isSellingCrypto {
                                    Image(systemName: "arrow.up.arrow.down")
                                        .font(Font.system(size: 17.0, weight: .regular, design: .default))
                                        .foregroundColor(Color.tangemTapBlue)
                                }
                            }
                            }
                            .disabled(viewModel.isSellingCrypto)
                        }
                        .padding(.top, 25.0)
                        Separator()
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
                                    if !viewModel.isSellingCrypto {
                                        Image(systemName: self.viewModel.isNetworkFeeBlockOpen ? "chevron.up" : "chevron.down")
                                            .font(Font.system(size: 14.0, weight: .medium, design: .default))
                                            .foregroundColor(Color.tangemTapGrayDark6)
                                            .padding()
                                    }
                                }
                                .accessibility(label: Text(self.viewModel.isNetworkFeeBlockOpen ? "voice_over_close_network_fee_settings" : "voice_over_open_network_fee_settings"))
                                .disabled(viewModel.isSellingCrypto)
                            }
                            if self.viewModel.isNetworkFeeBlockOpen || viewModel.isSellingCrypto {
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
                                .fixedSize(horizontal: false, vertical: true)
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
                                .fixedSize(horizontal: false, vertical: true)
                                .foregroundColor(Color.tangemTapGrayDark6)
                            
                        }
                        if !viewModel.isSellingCrypto {
                            HStack{
                                Spacer()
                                Text(self.viewModel.sendTotalSubtitle)
                                    .font(Font.system(size: 14.0, weight: .bold, design: .default))
                                    .fixedSize(horizontal: false, vertical: true)
                                    .foregroundColor(Color.tangemTapGrayDark)
                            }
                        }
                    }
                    WarningListView(warnings: viewModel.warnings, warningButtonAction: {
                        self.viewModel.warningButtonAction(at: $0, priority: $1, button: $2)
                    })
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.vertical, 16)
                    HStack(alignment: .center, spacing: 8.0) {
                        Spacer()
                        TangemButton(title: "wallet_button_send",
                                     systemImage: "arrow.right") {
                            self.viewModel.send() {
                                DispatchQueue.main.async {
                                    let alert = AlertBuilder.makeSuccessAlert(message: "send_transaction_success".localized) {
                                        presentationMode.wrappedValue.dismiss()
                                        onSuccess()
                                    }
                                    self.viewModel.sendError = AlertBinder(alert: alert, error: nil)
                                }
                            }
                        }.buttonStyle(TangemButtonStyle(layout: .big,
                                                        isDisabled: !self.viewModel.isSendEnabled))
                        .sheet(isPresented: $navigation.sendToSendEmail, content: {
                            MailView(dataCollector: viewModel.emailDataCollector, support: .tangem, emailType: .failedToSendTx)
                        })
                        .alert(item: self.$viewModel.sendError) { binder in
                            if binder.error == nil {
                                return binder.alert
                            }
                            return Alert(title: Text("alert_failed_to_send_transaction_title"),
                                         message: Text(String(format: "alert_failed_to_send_transaction_message".localized, binder.error?.localizedDescription ?? "Unknown error")),
                                         primaryButton: .default(Text("alert_button_send_feedback"), action: {
                                            navigation.sendToSendEmail = true
                                         }),
                                         secondaryButton: .default(Text("common_no")))
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
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
                    .receive(on: DispatchQueue.main)) { _ in
            viewModel.onEnterForeground()
        }
    }
}


struct ExtractView_Previews: PreviewProvider {
    static let assembly: Assembly = .previewAssembly(for: .ethereum)
    
    static var previews: some View {
        Group {
            SendView(viewModel: assembly.makeSellCryptoSendViewModel(with: Amount(with: assembly.previewBlockchain,
                                                                                  type: .token(value: Token(symbol: "DAI", contractAddress: "0xdwekdn32jfne", decimalCount: 18, blockchain: .ethereum(testnet: false))),
                                                                                  value: 0.0),
                                                                     destination: "Target",
                                                                     blockchain: assembly.previewBlockchain,
                                                                     card: assembly.previewCardViewModel),
                     onSuccess: {})
                .environmentObject(assembly.services.navigationCoordinator)
                .previewLayout(.iphone7Zoomed)
            SendView(viewModel: assembly.makeSendViewModel(with: Amount(with: assembly.previewBlockchain,
                                                                        type: .token(value: Token(symbol: "DAI", contractAddress: "0xdwekdn32jfne", decimalCount: 18, blockchain: .ethereum(testnet: false))),
                                                                        value: 0.0),
                                                           blockchain: assembly.previewBlockchain,
                                                           card: assembly.previewCardViewModel),
                     onSuccess: {})
                .environmentObject(assembly.services.navigationCoordinator)
                .previewLayout(.iphone7Zoomed)
        }
    }
}
