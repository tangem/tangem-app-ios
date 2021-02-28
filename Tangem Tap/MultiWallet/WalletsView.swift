////
////  WalletsView.swift
////  Tangem Tap
////
////  Created by [REDACTED_AUTHOR]
////  Copyright © 2021 Tangem AG. All rights reserved.
////
//
//import Foundation
//import SwiftUI
//
//struct WalletsView: View {
//    [REDACTED_USERNAME] var viewModel: WalletsViewModel
//    [REDACTED_USERNAME] var navigation: NavigationCoordinator
//    
//    var body: some View {
//        VStack(spacing: 0) {
//            //navigationLinks
//            GeometryReader { geometry in
//                RefreshableScrollView(refreshing: self.$viewModel.isRefreshing) {
//                    VStack(spacing: 8.0) {
//                        CardView(image: self.viewModel.image,
//                                 width: geometry.size.width-100,
//                                 currentCardNumber: nil)
//                        
//                        //                        if self.isUnsupportdState {
//                        //                            ErrorView(title: "wallet_error_unsupported_blockchain".localized, subtitle: "wallet_error_unsupported_blockchain_subtitle".localized)
//                        //                        } else {
//                        //                            WarningListView(warnings: self.viewModel.warnings, warningButtonAction: {
//                        //                                self.viewModel.warningButtonAction(at: $0, priority: $1)
//                        //                            })
//                        //                            .padding(.horizontal, 16)
//                        //
//                        //                            ForEach(self.pendingTransactionViews) { $0 }
//                        //
//                        //                            if self.shouldShowEmptyView {
//                        //                                ErrorView(
//                        //                                    title: viewModel.isTwinCard ? "wallet_error_empty_twin_card".localized : "wallet_error_empty_card".localized,
//                        //                                    subtitle: viewModel.isTwinCard ? "wallet_error_empty_twin_card_subtitle".localized : "wallet_error_empty_card_subtitle".localized
//                        //                                )
//                        //                            } else {
//                        //                                if self.shouldShowBalanceView {
//                        //                                    BalanceView(
//                        //                                        balanceViewModel: self.viewModel.state.cardModel!.state.walletModel!.balanceViewModel,
//                        //                                        tokenViewModels: self.viewModel.state.cardModel!.state.walletModel!.tokenViewModels
//                        //                                    )
//                        //                                        .padding(.horizontal, 16.0)
//                        //                                } else {
//                        //                                    if self.noAccountView != nil {
//                        //                                        self.noAccountView!
//                        //                                    } else {
//                        //                                        EmptyView()
//                        //                                    }
//                        //                                }
//                        //                                AddressDetailView(showCreatePayID: self.$navigation.mainToCreatePayID,
//                        //                                                  showQr: self.$navigation.mainToQR,
//                        //                                                  selectedAddressIndex: self.$viewModel.selectedAddressIndex,
//                        //                                                  cardViewModel: self.viewModel.state.cardModel!)
//                        //
//                        //                                Color.clear.frame(width: 1, height: 1, alignment: .center)
//                        //                                    .sheet(isPresented: self.$navigation.mainToCreatePayID, content: {
//                        //                                        CreatePayIdView(cardId: self.viewModel.state.cardModel!.cardInfo.card.cardId ?? "",
//                        //                                                        cardViewModel: self.viewModel.state.cardModel!)
//                        //                                    })
//                        //                            }
//                        //                        }
//                        //                    }
//                        //                }
//                        //            }
//                        //            bottomButtons
//                        //                .padding([.top, .leading, .trailing], 8)
//                        //                .padding(.bottom, 16.0)
//                    }
//                    .navigationBarBackButtonHidden(true)
//                    .navigationBarTitle("wallet_title", displayMode: .inline)
//                    .navigationBarItems(trailing: Button(action: {
//                        //            if self.viewModel.state.cardModel != nil {
//                        //                self.viewModel.navigation.mainToSettings.toggle()
//                        //            }
//                    }, label: { Image("verticalDots")
//                        .foregroundColor(Color.tangemTapGrayDark6)
//                        .frame(width: 44.0, height: 44.0, alignment: .center)
//                        .offset(x: 10.0, y: 0.0)
//                    })
//                    .padding(0.0)
//                    )
//                    .background(Color.tangemTapBgGray.edgesIgnoringSafeArea(.all))
//                    .onAppear {
//                        //  self.viewModel.onAppear()
//                    }
//                    //  .navigationBarHidden(isNavBarHidden)
//                    .ignoresKeyboard()
//                    //        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
//                    //                    .filter {_ in !navigation.mainToSettings
//                    //                        && !navigation.mainToSend
//                    //                        && !navigation.mainToCreatePayID
//                    //                        && !navigation.mainToSendChoise
//                    //                        && !navigation.mainToTopup
//                    //                        && !navigation.mainToTwinOnboarding
//                    //                        && !navigation.mainToTwinsWalletWarning
//                    //                    }
//                    //                    .delay(for: 0.3, scheduler: DispatchQueue.global())
//                    //                    .receive(on: DispatchQueue.main)) { _ in
//                    //            viewModel.state.cardModel?.update()
//                }
//                //       .alert(item: $viewModel.error) { $0.alert }
//            }
//        }
//    }
//    
//}
//
//
//struct WalletsView_Previews: PreviewProvider {
//    static var previews: some View {
//        NavigationView {
//            WalletsView(viewModel: Assembly.previewAssembly.makeWalletsViewModel())
//                .environmentObject(Assembly.previewAssembly.navigationCoordinator)
//        }
//        .previewGroup(devices: [.iPhone8Plus])
//        .navigationViewStyle(StackNavigationViewStyle())
//        .environment(\.locale, .init(identifier: "en"))
//    }
//}
