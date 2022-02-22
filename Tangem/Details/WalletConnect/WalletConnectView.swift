//
//  WalletConnectView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI

struct WalletConnectView: View {
    @ObservedObject var viewModel: WalletConnectViewModel
    @EnvironmentObject var navigation: NavigationCoordinator
    
    @ViewBuilder
    var navBarButton: some View {
        NavigationBusyButton(isBusy: viewModel.isServiceBusy,
                             color: .tangemBlue,
                             systemImageName: "plus",
                             action: viewModel.openSession)
            .accessibility(label: Text("voice_over_open_new_wallet_connect_session"))
    }
    
    var body: some View {
        ZStack {
            VStack {
                if viewModel.sessions.isEmpty {
                    Text("wallet_connect_no_sessions_title")
                        .font(.system(size: 24, weight: .semibold))
                        .padding(.bottom, 10)
                    Text("wallet_connect_no_sessions_message")
                        .multilineTextAlignment(.center)
                        .font(.system(size: 17, weight: .medium))
                        .padding(.horizontal, 40)
                } else {
                    List {
                        ForEach(Array(viewModel.sessions.enumerated()), id: \.element) { (i, item) -> WalletConnectSessionItemView in
                            WalletConnectSessionItemView(dAppName: item.session.dAppInfo.peerMeta.name,
                                                         cardId: item.wallet.cid) {
                                viewModel.disconnectSession(at: i)
                            }
                        }
                        .listRowInsets(.none)
                    }
                    .listStyle(PlainListStyle())
                }
            }
            
            Color.clear.frame(width: 0.5, height: 0.5)
                .actionSheet(isPresented: $viewModel.isActionSheetVisible, content: {
                    ActionSheet(title: Text("common_select_action"), message: Text("wallet_connect_clipboard_alert"), buttons: [
                        .default(Text("wallet_connect_paste_from_clipboard"), action: viewModel.pasteFromClipboard),
                        .default(Text("wallet_connect_scan_new_code"), action: viewModel.scanQrCode),
                        .cancel()
                    ])
                })
            
            Color.clear.frame(width: 0.5, height: 0.5)
                .sheet(isPresented: $navigation.walletConnectToQR) {
                    QRScanView(code: $viewModel.code)
                        .edgesIgnoringSafeArea(.all)
                }
               
            Color.clear .frame(width: 0.5, height: 0.5)
                .cameraAccessDeniedAlert($viewModel.showCameraDeniedAlert)
            
            Color.clear .frame(width: 0.5, height: 0.5)
                .alert(item: $viewModel.alert) { $0.alert }
            
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.tangemBgGray.edgesIgnoringSafeArea(.all))
        .navigationBarTitle(Text("wallet_connect_sessions_title"))
        .navigationBarItems(trailing: navBarButton)
    }
}

struct WalletConnectView_Previews: PreviewProvider {
    static let assembly = Assembly.previewAssembly
    
    static var previews: some View {
        WalletConnectView(viewModel: assembly.makeWalletConnectViewModel(cardModel: assembly.services.cardsRepository.lastScanResult.cardModel!))
            .environmentObject(NavigationCoordinator())
            .previewGroup(devices: [.iPhone12Pro])
    }
}
