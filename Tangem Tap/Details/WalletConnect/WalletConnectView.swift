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
        List {
            VStack {
                HStack {
                    Text("WalletConnect")
                        .font(.largeTitle)
                        .padding()
                    Spacer()
                }
                Spacer()
                Text("Status: \(viewModel.statusTitle)")
                    .font(.title)
                Spacer()
                TangemLongButton(isLoading: viewModel.isConnecting,
                                 title: "\(viewModel.buttonTitle)",
                                 image: "arrow.right") {
                    viewModel.onTap()
                }
                .buttonStyle(TangemButtonStyle(color: .green, isDisabled: false))
                .sheet(isPresented: $navigation.walletConnectToQR) {
                    QRScanView(code: $viewModel.code)
                        .edgesIgnoringSafeArea(.all)
                }
            }
        }
        
        
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
    }
}
