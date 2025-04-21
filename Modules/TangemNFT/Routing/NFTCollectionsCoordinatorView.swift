//
//  NFTEntrypointCoordinatorView.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI

public struct NFTCollectionsCoordinatorView: View {
    @ObservedObject var coordinator: NFTCollectionsCoordinator

    public init(coordinator: NFTCollectionsCoordinator) {
        self.coordinator = coordinator
    }

    public var body: some View {
        if let collectionsListViewModel = coordinator.collectionsListViewModel {
            NFTCollectionsList(viewModel: collectionsListViewModel)
        }
    }
}
