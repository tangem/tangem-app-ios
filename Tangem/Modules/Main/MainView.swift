//
//  MainView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct MainView: View {
    @ObservedObject var viewModel: MainViewModel

    var body: some View {
        CardsInfoPagerView(
            data: viewModel.pages,
            selectedIndex: $viewModel.selectedCardIndex,
            headerFactory: { info in
                info.header
            },
            contentFactory: { info in
                info.body
            },
            onPullToRefresh: viewModel.onPullToRefresh(completionHandler:)
        )
        .pageSwitchThreshold(0.4)
        .contentViewVerticalOffset(64.0)
        .horizontalScrollDisabled(viewModel.isHorizontalScrollDisabled)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .background(Colors.Background.secondary.edgesIgnoringSafeArea(.all))
        .ignoresSafeArea(.keyboard)
        .edgesIgnoringSafeArea(.bottom)
        .toolbar(content: {
            ToolbarItem(placement: .navigationBarLeading) {
                Assets.tangemLogo.image
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                detailsNavigationButton
            }
        })
    }

    var detailsNavigationButton: some View {
        Button(action: viewModel.openDetails) {
            NavbarDotsImage()
        }
        .buttonStyle(PlainButtonStyle())
        .animation(nil)
        .accessibility(label: Text(Localization.voiceOverOpenCardDetails))
    }
}

struct MainView_Preview: PreviewProvider {
    static var previews: some View {
        NavigationView {
            MainView(viewModel: .init(coordinator: MainCoordinator(), userWalletRepository: FakeUserWalletRepository()))
        }
    }
}
