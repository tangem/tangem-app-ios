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
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(
                    action: {
                        let numOfPages = viewModel.pages.count
                        let modulo = numOfPages > 0 ? numOfPages : 1
                        let currValue = viewModel.selectedCardIndex
                        viewModel.selectedCardIndex = (currValue - 1 + numOfPages) % modulo
                    }, label: {
                        Image(systemName: "arrow.backward.square.fill")
                    }
                )
            }

            ToolbarItem(placement: .cancellationAction) {
                Button(
                    action: {
                        viewModel.dropFirst()
                        print("⭐️dropFirst, now has \(viewModel.pages.count) items")
                    }, label: {
                        Image(systemName: "rectangle.badge.minus")
                    }
                )
            }

            ToolbarItem(placement: .principal) {
                Button(
                    action: {
                        viewModel.appendToEnd()
                        print("⭐️appendToEnd, now has \(viewModel.pages.count) items")
                    }, label: {
                        Text("Curr page #\(viewModel.selectedCardIndex), add new?")
                    }
                )
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                Button(
                    action: {
                        viewModel.dropLast()
                        print("⭐️dropLast, now has \(viewModel.pages.count) items")
                    }, label: {
                        Image(systemName: "folder.badge.minus")
                    }
                )
            }

            ToolbarItem(placement: .primaryAction) {
                Button(
                    action: {
                        let numOfPages = viewModel.pages.count
                        let modulo = numOfPages > 0 ? numOfPages : 1
                        let currValue = viewModel.selectedCardIndex
                        viewModel.selectedCardIndex = (currValue + 1) % modulo
                    }, label: {
                        Image(systemName: "arrow.forward.square.fill")
                    }
                )
            }
        }
        .alert(item: $viewModel.errorAlert) { $0.alert }
    }

    var scanCardButton: some View {
        Button(action: viewModel.scanCardAction) {
            Assets.scanWithPhone.image
                .foregroundColor(Colors.Icon.primary1)
                .frame(width: 44, height: 44)
        }
        .buttonStyle(PlainButtonStyle())
        .animation(nil)
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
    static let viewModel: MainViewModel = {
        InjectedValues[\.userWalletRepository] = FakeUserWalletRepository()
        let coordinator = MainCoordinator()
        return .init(coordinator: coordinator, mainUserWalletPageBuilderFactory: CommonMainUserWalletPageBuilderFactory(coordinator: coordinator))
    }()

    static var previews: some View {
        NavigationView {
            MainView(viewModel: viewModel)
        }
    }
}
