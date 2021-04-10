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
            if viewModel.walletConnectService.sessions.count == 0 {
                Text("wallet_connect_no_sessions_title")
                    .font(.system(size: 24, weight: .semibold))
                    .padding(.bottom, 10)
                Text("wallet_connect_no_sessions_message")
                    .font(.system(size: 17, weight: .medium))
            } else {
                List {
                    ForEach(Array(viewModel.walletConnectService.sessions.enumerated()), id: \.element) { (i, item) -> WalletConnectSessionItemView in
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
        .sheet(isPresented: $navigation.walletConnectToQR) {
            QRScanView(code: $viewModel.code)
                .edgesIgnoringSafeArea(.all)
        })
        .alert(item: $viewModel.error) { $0.alert }
        .onAppear {
            viewModel.onAppear()
        }
    }
}

struct WalletConnectView_Previews: PreviewProvider {
    static var previews: some View {
        WalletConnectView(viewModel: Assembly.previewAssembly.makeWalletConnectViewModel())
            .environmentObject(NavigationCoordinator())
            .previewGroup(devices: [.iPhone12Pro])
    }
}
