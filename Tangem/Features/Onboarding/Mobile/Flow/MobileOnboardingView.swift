//
//  MobileOnboardingView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils

struct MobileOnboardingView: View {
    @ObservedObject var viewModel: MobileOnboardingViewModel

    private let navigationRouter: NavigationRouter?
    private let ownNavigationRouter: CommonNavigationRouter?

    private var configuration: StepsFlowConfiguration {
        StepsFlowConfiguration(
            hasProgressBar: viewModel.flowBuilder.hasProgressBar,
            navigationBarHeight: OnboardingLayoutConstants.navbarSize.height,
            progressBarHeight: OnboardingLayoutConstants.progressBarHeight,
            progressBarPadding: OnboardingLayoutConstants.progressBarPadding
        )
    }

    init(viewModel: MobileOnboardingViewModel, navigationRouter: NavigationRouter?) {
        self.viewModel = viewModel
        self.navigationRouter = navigationRouter
        ownNavigationRouter = CommonNavigationRouter()
    }

    var body: some View {
        if let navigationRouter {
            content(navigationRouter: navigationRouter)
        } else if let ownNavigationRouter {
            NavigationContainer(
                root: content(navigationRouter: ownNavigationRouter),
                router: ownNavigationRouter
            )
        }
    }
}

// MARK: - MobileOnboardingView

private extension MobileOnboardingView {
    func content(navigationRouter: NavigationRouter) -> some View {
        StepsFlowView(
            builder: viewModel.flowBuilder,
            navigationRouter: navigationRouter,
            shouldFireConfetti: $viewModel.shouldFireConfetti,
            configuration: configuration
        )
        .background(Color.clear.alert(item: $viewModel.alert) { $0.alert })
    }
}
