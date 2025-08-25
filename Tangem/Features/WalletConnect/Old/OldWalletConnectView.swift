//
//  WalletConnectView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemLocalization
import TangemAssets
import TangemUI
import TangemUIUtils

struct OldWalletConnectView: View {
    @ObservedObject var viewModel: OldWalletConnectViewModel

    @ViewBuilder
    var navBarButton: some View {
        NavigationBusyButton(
            isBusy: viewModel.isServiceBusy,
            color: UIColor.iconAccent,
            systemImageName: "plus",
            action: viewModel.openSession
        )
        .accessibility(label: Text(Localization.voiceOverOpenNewWalletConnectSession))
        .disableAnimations()
    }

    var body: some View {
        ZStack {
            VStack {
                if viewModel.noActiveSessions {
                    Text(Localization.walletConnectNoSessionsTitle)
                        .font(.system(size: 24, weight: .semibold))
                        .padding(.bottom, 10)
                    Text(Localization.walletConnectNoSessionsMessage)
                        .multilineTextAlignment(.center)
                        .font(.system(size: 17, weight: .medium))
                        .padding(.horizontal, 40)
                } else {
                    List {
                        ForEach(viewModel.sessions, id: \.id) { item -> WalletConnectSessionItemView in
                            WalletConnectSessionItemView(
                                dAppName: item.sessionInfo.dAppInfo.name
                            ) {
                                viewModel.disconnectSession(item)
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }

            Color.clear.frame(width: 0.5, height: 0.5)
                .actionSheet(isPresented: $viewModel.isActionSheetVisible, content: {
                    ActionSheet(title: Text(Localization.commonSelectAction), message: Text(Localization.walletConnectClipboardAlert), buttons: [
                        .default(Text(Localization.walletConnectPasteFromClipboard), action: viewModel.pasteFromClipboard),
                        .default(Text(Localization.walletConnectScanNewCode), action: viewModel.openQRScanner),
                        .cancel(),
                    ])
                })

            Color.clear.frame(width: 0.5, height: 0.5)
                .cameraAccessDeniedAlert($viewModel.showCameraDeniedAlert)

            Color.clear.frame(width: 0.5, height: 0.5)
                .alert(item: $viewModel.alert) { $0.alert }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Colors.Old.tangemBgGray.edgesIgnoringSafeArea(.all))
        .navigationBarTitle(Text(Localization.walletConnectSessionsTitle))
        .navigationBarItems(trailing: navBarButton)
        .onAppear(perform: viewModel.onAppear)
    }
}

struct WalletConnectView_Previews: PreviewProvider {
    static var previews: some View {
        OldWalletConnectView(viewModel: .init(disabledLocalizedReason: nil, coordinator: WalletConnectCoordinator()))
            .previewGroup(devices: [.iPhone12Pro])
    }
}
