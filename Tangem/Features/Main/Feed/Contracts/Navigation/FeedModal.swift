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

    var pulseTagFilter: PulseTagFilterBottomSheetViewModel? {
        guard case .pulseTagFilter(let viewModel) = self else { return nil }
        return viewModel
    }

    var marketCapInfo: MarketCapInfoBottomSheetViewModel? {
        guard case .marketCapInfo(let viewModel) = self else { return nil }
        return viewModel
    }

    var realAssetsCategoryFilter: MarketsRealAssetsFilterBottomSheetViewModel? {
        guard case .realAssetsCategoryFilter(let viewModel) = self else { return nil }
        return viewModel
    }

    var earnNetworkFilter: EarnNetworkFilterBottomSheetViewModel? {
        guard case .earnNetworkFilter(let viewModel) = self else { return nil }
        return viewModel
    }

    var earnTypeFilter: EarnTypeFilterBottomSheetViewModel? {
        guard case .earnTypeFilter(let viewModel) = self else { return nil }
        return viewModel
    }
}
