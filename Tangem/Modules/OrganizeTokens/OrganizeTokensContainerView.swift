//
//  OrganizeTokensContainerView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct OrganizeTokensContainerView: View {
    private static var didSetupUIAppearance = false

    private let viewModel: OrganizeTokensViewModel

    var body: some View {
        Group {
            if #available(iOS 16.0, *) {
                NavigationView {
                    organizeTokensView
                        .toolbarBackground(.hidden, for: .navigationBar)
                }
            } else {
                UIAppearanceBoundaryContainerView(boundaryMarker: OrganizeTokensContainerViewUIAppearanceBoundaryMarker.self) {
                    NavigationView {
                        organizeTokensView
                            .onAppear { Self.setupUIAppearanceIfNeeded() }
                    }
                }
            }
        }
        .ignoresSafeArea(edges: .vertical)
    }

    @ViewBuilder
    private var organizeTokensView: some View {
        OrganizeTokensView(viewModel: viewModel)
            .navigationTitle(Localization.organizeTokensTitle)
            .navigationBarTitleDisplayMode(.inline)
    }

    init(
        viewModel: OrganizeTokensViewModel
    ) {
        self.viewModel = viewModel
    }

    @available(iOS, obsoleted: 16.0, message: "Use native 'toolbarBackground(_:for:)' instead")
    private static func setupUIAppearanceIfNeeded() {
        if #unavailable(iOS 16.0), !didSetupUIAppearance {
            let navBarAppearance = UINavigationBarAppearance()
            navBarAppearance.configureWithTransparentBackground()

            let uiAppearance = UINavigationBar.appearance(
                whenContainedInInstancesOf: [OrganizeTokensContainerViewUIAppearanceBoundaryMarker.self]
            )
            uiAppearance.compactAppearance = navBarAppearance
            uiAppearance.standardAppearance = navBarAppearance
            uiAppearance.scrollEdgeAppearance = navBarAppearance
            uiAppearance.compactScrollEdgeAppearance = navBarAppearance

            didSetupUIAppearance = true
        }
    }
}

// MARK: - Previews

struct OrganizeTokensContainerView_Preview: PreviewProvider {
    static var previews: some View {
        let viewModelFactory = OrganizeTokensPreviewViewModelFactory()

        ForEach(OrganizeTokensPreviewConfiguration.allCases, id: \.name) { previewConfiguration in
            let viewModel = viewModelFactory.makeViewModel(for: previewConfiguration)
            OrganizeTokensContainerView(viewModel: viewModel)
                .previewLayout(.sizeThatFits)
                .previewDisplayName(previewConfiguration.name)
        }
    }
}

// MARK: - Auxiliary types

private class OrganizeTokensContainerViewUIAppearanceBoundaryMarker: UIViewController {}
