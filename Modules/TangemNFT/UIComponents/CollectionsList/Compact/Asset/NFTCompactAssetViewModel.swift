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

    var id: AnyHashable {
        switch state {
        case .loading(let id):
            id

        case .loaded(let viewData):
            viewData.asset.id
        }
    }

    private let openAssetDetailsAction: (NFTAsset) -> Void

    init(
        state: State,
        openAssetDetailsAction: @escaping (NFTAsset) -> Void
    ) {
        self.state = state
        self.openAssetDetailsAction = openAssetDetailsAction
    }

    func didClick() {
        guard let viewData = state.viewData else {
            return
        }

        openAssetDetailsAction(viewData.asset)
    }
}

// MARK: - Auxiliary types

extension NFTCompactAssetViewModel {
    struct ViewData {
        var media: NFTMedia? { NFTAssetMediaExtractor.extractMedia(from: asset) }
        var name: String { asset.name }
        var price: String?

        fileprivate let asset: NFTAsset

        init(
            asset: NFTAsset,
            priceFormatter: NFTPriceFormatting
        ) {
            self.asset = asset

            if let salePrice = asset.salePrice {
                price = priceFormatter.formatCryptoPrice(salePrice.last.value, in: asset.id.chain)
            }
        }
    }

    enum State {
        case loading(id: String)
        case loaded(ViewData)

        var viewData: ViewData? {
            switch self {
            case .loading:
                return nil
            case .loaded(let viewData):
                return viewData
            }
        }
    }
}
