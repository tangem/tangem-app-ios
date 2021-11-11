////
////  TwinsWalletCreationView.swift
////  Tangem
////
////  Created by [REDACTED_AUTHOR]
////  Copyright © 2020 Tangem AG. All rights reserved.
////
//
//import SwiftUI
//
//struct SimpleProgressBar: View {
//    
//    var isSelected: Bool
//    
//    var body: some View {
//        isSelected ?
//            Color.tangemBlue :
//            Color.tangemBlueLight2
//    }
//    
//}
//
//struct TwinsWalletCreationView: View {
//    [REDACTED_USERNAME] var navigation: NavigationCoordinator
//    [REDACTED_USERNAME] var viewModel: TwinsWalletCreationViewModel
//    [REDACTED_USERNAME](\.presentationMode) var presentationMode
//    var body: some View {
//        VStack(spacing: 0) {
//            NavigationBar(title: viewModel.isRecreatingWallet ? "details_twins_recreate_toolbar" : "details_row_title_twins_create",
//                          settings: .init(horizontalPadding: 8),
//                          backAction: {
//                            if self.viewModel.step == .first {
//                                self.dismiss(isWalletCreated: false)
//                            } else {
//                                self.viewModel.error = AlertBinder(alert: Alert(title: Text("twins_creation_warning_title"),
//                                                                                message: Text("twins_creation_warning_message"),
//                                                                                primaryButton: Alert.Button.destructive(Text("common_ok"), action: {
//                                                                                    self.dismiss(isWalletCreated: false)
//                                                                                }),
//                                                                                secondaryButton: Alert.Button.default(Text("common_cancel"))))
//                            }
//                          })
//            VStack(alignment: .leading, spacing: 8) {
//                Text(viewModel.step.stepTitle)
//                    .font(.system(size: 30, weight: .bold))
//                    .foregroundColor(.tangemBlue)
//                HStack {
//                    SimpleProgressBar(isSelected: true)
//                    SimpleProgressBar(isSelected: viewModel.step >= .second)
//                    SimpleProgressBar(isSelected: viewModel.step >= .third)
//                }
//                //.animation(.easeOut)
//                .transition(.opacity)
//                .frame(height: 3)
//                ZStack {
//                    Image(uiImage: viewModel.walletCreationService.isStartedFromFirstNumber ? viewModel.secondTwinCardImage : viewModel.firstTwinCardImage)
//                        .resizable()
//                        .frame(width: 108, height: 57)
//                        .offset(x: 22, y: -1.5)
//                        .opacity(viewModel.step >= .second ? 1 : 0.0)
//                        .animation(.easeOut)
//                        .transition(.opacity)
//                    Image(uiImage: viewModel.walletCreationService.isStartedFromFirstNumber ? viewModel.firstTwinCardImage : viewModel.secondTwinCardImage)
//                        .resizable()
//                        .frame(width: 108, height: 57)
//                        .offset(y: 11)
//                }
//                .frame(height: 104, alignment: .leading)
//                Text(viewModel.title)
//                    .font(.system(size: 30, weight: .bold))
//                Text(viewModel.step.hint)
//                Spacer()
//                HStack {
//                    Spacer()
//                    TangemLongButton(isLoading: self.viewModel.isCreationServiceBusy,
//                                     title: viewModel.buttonTitle,
//                                     image: "scan") {
//                        withAnimation {
//                            self.viewModel.buttonAction()
//                        }
//                    }
//                    .buttonStyle(TangemButtonStyle(color: .black, isDisabled: false))
//                }
//                .padding(.bottom, 16)
//            }
//            .padding(.horizontal, 24)
//            .background(Color.tangemBgGray.edgesIgnoringSafeArea(.all))
//            .foregroundColor(.tangemGrayDark6)
//        }
//        .onDisappear(perform: {
//            guard self.viewModel.isDismissing else { return }
//            self.viewModel.onDismiss()
//            
//            //important to reset dropped link to false
//            navigation.twinOnboardingToTwinWalletCreation = false
//            if viewModel.finishedWalletCreation {
//                navigation.detailsToTwinsRecreateWarning = false
//            }
//        })
//        .onAppear(perform: {
//            self.viewModel.onAppear()
//        })
//        .onReceive(viewModel.$finishedWalletCreation, perform: { isWalletsCreated in
//            if isWalletsCreated {
//                let alert = AlertBuilder.makeSuccessAlert(message: "notification_twins_recreate_success".localized,
//                                                          okAction: {
//                                                              self.dismiss(isWalletCreated: true)
//                                                          })
//                self.viewModel.error = AlertBinder(alert: alert)
//            }
//        })
//        .alert(item: $viewModel.error) { $0.alert }
//        .navigationBarTitle("")
//        .navigationBarHidden(true)
//    }
//    
//    private func dismiss(isWalletCreated: Bool) {
//        viewModel.isDismissing = true
//        
//        //if create wallet from main
//        if navigation.mainToTwinsWalletWarning {
//            // skip warning screen
//            navigation.mainToTwinsWalletWarning = false
//        } else { // if recreate wallet from details
//            if isWalletCreated {
//                // back directly to main screen
//                navigation.mainToSettings = false
//            } else {
//                // skip warning screen
//                navigation.detailsToTwinsRecreateWarning = false
//            }
//        }
//        
//    }
//}
//
//struct TwinsWalletCreationView_Previews: PreviewProvider {
//    static var previews: some View {
//        TwinsWalletCreationView(viewModel: Assembly.previewAssembly.makeTwinsWalletCreationViewModel(isRecreating: false))
//            .deviceForPreviewZoomed(.iPhone7)
//    }
//}
