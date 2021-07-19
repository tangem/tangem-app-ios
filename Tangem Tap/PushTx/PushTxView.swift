//
//  PushTxView.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI
import BlockchainSdk

struct FilledInputView: View {
    
    let title: String
    let text: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(Font.system(size: 13.0, weight: .medium, design: .default))
                .foregroundColor(Color.tangemTapGrayDark)
                .padding(.bottom, 4)
            Text(text)
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.tangemTapGrayDark6)
            Separator()
        }
        
        
    }
}


struct PushTxView: View {
    
    @ObservedObject var viewModel: PushTxViewModel
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var navigation: NavigationCoordinator
    let onSuccess: () -> Void
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(alignment: .leading, spacing: 0.0) {
                    HStack {
                        Text("common_push")
                            .font(Font.system(size: 30.0, weight: .bold, design: .default) )
                            .foregroundColor(Color.tangemTapGrayDark6)
                        Spacer()
                    }
                    .padding(.bottom)
                    FilledInputView(title: "send_destination_hint_address".localized, text: viewModel.destination)
                        .opacity(0.6)
                    VStack(alignment: .leading) {
                        Text("push_tx_address_hint")
                            .font(Font.system(size: 13.0, weight: .medium, design: .default))
                            .foregroundColor(Color.tangemTapGrayDark)
                            .opacity(0.6)
                            .padding(.bottom, 4)
                        HStack {
                            Text(viewModel.previousTotal)
                                .foregroundColor(.tangemTapGrayDark6)
                                .opacity(0.6)
                            Spacer()
                            Button(action: {
                                self.viewModel.isFiatCalculation.toggle()
                            }) { HStack(alignment: .center, spacing: 8.0) {
                                Text(self.viewModel.currency)
                                    .font(Font.system(size: 38.0, weight: .light, design: .default))
                                    .foregroundColor(self.viewModel.canFiatCalculation ?
                                                        Color.tangemTapBlue : Color.tangemTapBlue.opacity(0.5))
                                Image("arrow.up.arrow.down")
                                    .font(Font.system(size: 17.0, weight: .regular, design: .default))
                                    .foregroundColor(self.viewModel.canFiatCalculation ?
                                                        Color.tangemTapBlue : Color.tangemTapBlue.opacity(0.5))
                            }
                            }
                            .foregroundColor(.tangemTapBlue)
                            .disabled(!self.viewModel.canFiatCalculation)
                        }
                        .font(.system(size: 38, weight: .light))
                    }
                    .padding(.top, 15)
                    
                    Separator()
                    HStack {
                        Spacer()
                        Text(viewModel.walletTotalBalanceFormatted)
                            .font(Font.system(size: 13.0, weight: .medium, design: .default))
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                            .foregroundColor(Color.tangemTapGrayDark)
                    }
                    VStack(alignment: .leading) {
                        Text("send_network_fee_title")
                            .font(Font.system(size: 14.0, weight: .medium, design: .default))
                            .foregroundColor(Color.tangemTapGrayDark6)
                            .padding(.vertical, 8.0)
                        PickerView(contents: ["send_fee_picker_low".localized,
                                              "send_fee_picker_normal".localized,
                                              "send_fee_picker_priority".localized],
                                   selection: $viewModel.selectedFeeLevel)
                            .padding(.vertical, 8.0)
                        Text(viewModel.amountHint?.message ?? " " )
                            .font(.system(size: 13.0, weight: .medium, design: .default))
                            .foregroundColor((viewModel.amountHint?.isError ?? false ) ?
                                                Color.red : Color.tangemTapGrayDark)
                        Toggle(isOn: self.$viewModel.isFeeIncluded) {
                            Text("send_fee_include_description")
                                .font(Font.system(size: 13.0, weight: .medium, design: .default))
                                .foregroundColor(Color.tangemTapGrayDark6)
                        }
                    }
                    Spacer()
                    VStack (spacing: 8.0) {
                        AmountView(label: "send_amount_label",
                                   labelColor: .tangemTapGrayDark6,
                                   amountText: viewModel.amount)
                        
                        AmountView(label: "push_previous_fee",
                                   labelColor: .tangemTapGrayDark,
                                   amountText: viewModel.previousFee)
                            .opacity(0.6)
                        AmountView(label: "push_additional_fee",
                                   labelColor: .tangemTapGrayDark,
                                   isLoading: viewModel.isFeeLoading,
                                   amountText: viewModel.additionalFee)
                        Separator()
                        
                        AmountView(label: "send_total_label",
                                   labelColor: .tangemTapGrayDark6,
                                   labelFont: .system(size: 20, weight: .bold, design: .default),
                                   amountText: viewModel.sendTotal,
                                   amountScaleFactor: 0.5,
                                   amountLineLimit: 1)
                        HStack{
                            Spacer()
                            Text(viewModel.sendTotalSubtitle)
                                .font(Font.system(size: 14.0, weight: .bold, design: .default))
                                .fixedSize(horizontal: false, vertical: true)
                                .foregroundColor(Color.tangemTapGrayDark)
                        }
                    }
                    //                    WarningListView(warnings: viewModel.warnings, warningButtonAction: {
                    //                        self.viewModel.warningButtonAction(at: $0, priority: $1, button: $2)
                    //                    })
                    //                    .fixedSize(horizontal: false, vertical: true)
                    //                    .padding(.bottom, 16)
                    HStack(alignment: .center, spacing: 8.0) {
                        Spacer()
                        TangemLongButton(isLoading: false,
                                         title: "wallet_button_send",
                                         image: "arrow.right") {
                            viewModel.send() {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: {
                                    let alert = AlertBuilder.makeSuccessAlert(message: "send_transaction_success".localized) {
                                        presentationMode.wrappedValue.dismiss()
                                        onSuccess()
                                    }
                                    self.viewModel.sendError = AlertBinder(alert: alert, error: nil)
                                })
                            }
                        }.buttonStyle(TangemButtonStyle(color: .green,
                                                        isDisabled: !self.viewModel.isSendEnabled))
                        .disabled(!viewModel.isSendEnabled)
                        .sheet(isPresented: $navigation.pushToSendEmail, content: {
                            MailView(dataCollector: viewModel.emailDataCollector, support: viewModel.cardViewModel.emailSupport, emailType: .failedToSendTx)
                        })
                        .alert(item: self.$viewModel.sendError) { binder in
                            if binder.error == nil {
                                return binder.alert
                            }
                            return Alert(title: Text("alert_failed_to_send_transaction_title"),
                                         message: Text(String(format: "alert_failed_to_send_transaction_message".localized, binder.error?.localizedDescription ?? "Unknown error")),
                                         primaryButton: .default(Text("alert_button_send_feedback"), action: {
                                            navigation.pushToSendEmail = true
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
    }
}

struct PushTxView_Previews: PreviewProvider {
    static let assembly = Assembly.previewAssembly
    static var previews: some View {
        PushTxView(viewModel: assembly
                    .makePushViewModel(
                        for: .dummyTx(blockchain: .bitcoin(testnet: false), type: .coin, destinationAddress: "tb1qrvkydv7322e7fl9v58eqvn87tx2jtlpqaetz2n"),
                        blockchain: .bitcoin(testnet: false),
                        card: assembly.previewCardViewModel),
                   onSuccess: { })
            .environmentObject(assembly.services.navigationCoordinator)
    }
}
