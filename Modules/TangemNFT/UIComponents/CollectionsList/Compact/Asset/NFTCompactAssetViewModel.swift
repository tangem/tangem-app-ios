//
//  NFTCompactAssetViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct NFTCompactAssetViewModel: Identifiable {
    let state: State
    private let openAssetDetailsAction: (NFTAsset) -> Void

    init(state: State, openAssetDetailsAction: @escaping (NFTAsset) -> Void) {
        self.state = state
        self.openAssetDetailsAction = openAssetDetailsAction
    }

    var id: AnyHashable {
        switch state {
        case .loading(let id):
            id

        case .loaded(let asset):
            asset.id
        }
    }

    func didClick() {
        guard let asset = state.asset else { return }
        openAssetDetailsAction(asset)
    }
}

extension NFTCompactAssetViewModel {
    enum State {
        case loading(id: String)
        case loaded(NFTAsset)

        var asset: NFTAsset? {
            switch self {
            case .loading: nil
            case .loaded(let nftAsset): nftAsset
            }
        }
    }
}
