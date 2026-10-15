//
//  FeedModal.swift
//  Tangem
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

enum FeedModal: Identifiable {
    case pulseTagFilter(PulseTagFilterBottomSheetViewModel)
    case marketCapInfo(MarketCapInfoBottomSheetViewModel)
    case realAssetsCategoryFilter(MarketsRealAssetsFilterBottomSheetViewModel)
    case earnNetworkFilter(EarnNetworkFilterBottomSheetViewModel)
    case earnTypeFilter(EarnTypeFilterBottomSheetViewModel)

    var id: ObjectIdentifier {
        switch self {
        case .pulseTagFilter(let viewModel): ObjectIdentifier(viewModel)
        case .marketCapInfo(let viewModel): ObjectIdentifier(viewModel)
        case .realAssetsCategoryFilter(let viewModel): ObjectIdentifier(viewModel)
        case .earnNetworkFilter(let viewModel): ObjectIdentifier(viewModel)
        case .earnTypeFilter(let viewModel): ObjectIdentifier(viewModel)
        }
    }
}
