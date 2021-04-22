//
//  WalletConnectView.swift
//  Tangem Tap
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI

struct WalletConnectView: View {
    @ObservedObject var viewModel: WalletConnectViewModel
    @EnvironmentObject var navigation: NavigationCoordinator
    
    var body: some View {
        VStack {
            if viewModel.sessions.count == 0 {
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
                        return WalletConnectSessionItemView(dAppName: item.session.dAppInfo.peerMeta.name,
                                                            cardId: item.wallet.cid) {
                            viewModel.disconnectSession(at: i)
                        }
                    }
                    .listRowInsets(.none)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.tangemTapBgGray.edgesIgnoringSafeArea(.all))
        .navigationBarTitle(Text("wallet_connect_sessions_title"))
        .navigationBarItems(trailing: NavigationBusyButton(isBusy: viewModel.isServiceBusy, color: .tangemTapBlue, systemImageName: "plus", action: {
            viewModel.openNewSession()
        })
        .accessibility(label: Text("voice_over_open_new_wallet_connect_session"))
        .sheet(isPresented: $navigation.walletConnectToQR) {
            QRScanView(code: $viewModel.code)
                .edgesIgnoringSafeArea(.all)
        })
        .alert(item: $viewModel.alert) { $0.alert }
        .onAppear {
            viewModel.onAppear()
        }
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
