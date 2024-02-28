//
//  WelcomeCoordinatorView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

struct WelcomeCoordinatorView: CoordinatorView {
    @ObservedObject var coordinator: WelcomeCoordinator

    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    init(coordinator: WelcomeCoordinator) {
        self.coordinator = coordinator
    }

    var body: some View {
        ZStack {
            content
            sheets
        }
        .navigationBarHidden(coordinator.viewState?.isMain == false)
        .animation(.default, value: coordinator.viewState)
    }

    @ViewBuilder
    private var content: some View {
        switch coordinator.viewState {
        case .welcome(let welcomeViewModel):
            WelcomeView(viewModel: welcomeViewModel)
                .navigationLinks(links)
        case .main(let mainCoordinator):
            MainCoordinatorView(coordinator: mainCoordinator)
        case .none:
            EmptyView()
        }
    }

    @ViewBuilder
    private var links: some View {
        NavHolder()
            .navigation(item: $coordinator.pushedOnboardingCoordinator) {
                OnboardingCoordinatorView(coordinator: $0)
            }
    }

    @ViewBuilder
    private var sheets: some View {
        NavHolder()
            .sheet(item: $coordinator.promotionCoordinator) {
                PromotionCoordinatorView(coordinator: $0)
            }
            .sheet(item: $coordinator.legacyTokenListCoordinator) {
                LegacyTokenListCoordinatorView(coordinator: $0)
            }
            .sheet(item: $coordinator.mailViewModel) {
                MailView(viewModel: $0)
            }
    }

    static let coordinator: WelcomeCoordinator = {
        let coordinator = WelcomeCoordinator(dismissAction: { _ in }, popToRootAction: { _ in })
        coordinator.start(with: WelcomeCoordinator.Options(shouldScan: false))
        return coordinator
    }()

    static let fake: WelcomeCoordinatorView = .init(coordinator: coordinator)
}

#Preview {
    struct TestView: View {
        @State var isMain: Bool? = nil

        let viewModel: MainViewModel = {
            InjectedValues[\.userWalletRepository] = FakeUserWalletRepository()
            let coordinator = MainCoordinator()
            let swipeDiscoveryHelper = WalletSwipeDiscoveryHelper()
            let viewModel = MainViewModel(
                coordinator: coordinator,
                swipeDiscoveryHelper: swipeDiscoveryHelper,
                mainUserWalletPageBuilderFactory: CommonMainUserWalletPageBuilderFactory(coordinator: coordinator)
            )
            swipeDiscoveryHelper.delegate = viewModel

            return viewModel
        }()

        var body: some View {
            NavigationView {
                ZStack {
                    if isMain == true {
                        MainView(viewModel: viewModel)
                    } else {
                        WelcomeCoordinatorView.fake
                    }
                }
                .overlay {
                    Button {
                        isMain?.toggle()
                    } label: {
                        Text("Toggle")
                    }
                }
                .navigationBarHidden(isMain == false)
                .animation(.default, value: isMain)
            }
            .onAppear {
                //            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isMain = false
                //            }
            }
        }
    }

    return TestView()
}
