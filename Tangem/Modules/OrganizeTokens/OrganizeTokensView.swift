//
//  OrganizeTokensView.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI

struct OrganizeTokensView: View {
    @ObservedObject private var viewModel: OrganizeTokensViewModel

    init(viewModel: OrganizeTokensViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 0.0) {
                ForEach(viewModel.sections) { sectionViewModel in
                    Section(
                        content: {
                            ForEach(sectionViewModel.items) { itemViewModel in
                                OrganizeTokensSectionItemView(viewModel: itemViewModel)
                            }
                        },
                        header: {
                            OrganizeTokensSectionView(viewModel: sectionViewModel)
                        }
                    )
                }
            }
        }
    }
}

// MARK: - Previews

struct OrganizeTokensView_Preview: PreviewProvider {
    static let viewModel = OrganizeTokensViewModel(coordinator: OrganizeTokensCoordinator())

    static var previews: some View {
        VStack {
            Group {
                OrganizeTokensView(viewModel: viewModel)
            }
            .background(Colors.Background.primary)
        }
        .padding()
        .previewLayout(.sizeThatFits)
        .background(Colors.Background.secondary)
    }
}
