//
//  NFTAssetDetailsViewModel.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemUI
import TangemLocalization
import TangemAssets

public final class NFTAssetDetailsViewModel: ObservableObject, Identifiable {
    private let asset: NFTAsset

    private let nftChainNameProviding: NFTChainNameProviding
    private weak var coordinator: NFTAssetDetailsRoutable?

    public init(
        asset: NFTAsset,
        coordinator: NFTAssetDetailsRoutable?,
        nftChainNameProviding: NFTChainNameProviding
    ) {
        self.asset = asset
        self.coordinator = coordinator
        self.nftChainNameProviding = nftChainNameProviding
    }

    var name: String {
        asset.name
    }

    var imageURL: URL? {
        asset.media?.url
    }

    // [REDACTED_TODO_COMMENT]
    var headerState: NFTDetailsHeaderState? {
        let rarityKeyValuePairs = makeRarity(from: asset.rarity)

        if let description = asset.description {
            return .full(
                .description(
                    NFTDetailsHeaderState.DescriptionConfig(
                        text: description,
                        readMoreAction: { [weak self] in self?.openDescription() }
                    )
                ),
                rarityKeyValuePairs
            )
        }

        return .rarity(rarityKeyValuePairs)
    }

    var traits: KeyValuePanelConfig? {
        guard asset.traits.isNotEmpty else {
            return nil
        }

        let maximumTraits = asset.traits.prefix(Constants.maximumTraits)

        let header = if asset.traits.count > Constants.maximumTraits {
            KeyValuePanelConfig.Header(
                title: Localization.nftDetailsTraits,
                actionConfig: KeyValuePanelConfig.Header.ActionConfig(
                    buttonTitle: Localization.commonSeeAll,
                    image: nil,
                    action: { [weak self] in self?.openAllTraits() }
                )
            )
        } else {
            KeyValuePanelConfig.Header(title: Localization.nftDetailsTraits, actionConfig: nil)
        }

        return KeyValuePanelConfig(
            header: header,
            keyValues: makeTraits(from: Array(maximumTraits))
        )
    }

    var baseInformation: KeyValuePanelConfig? {
        let header = KeyValuePanelConfig.Header(
            title: Localization.nftDetailsBaseInformation,
            actionConfig: KeyValuePanelConfig.Header.ActionConfig(
                buttonTitle: Localization.commonExplore,
                image: Assets.compassExplore,
                action: { [weak self] in self?.explore() }
            )
        )

        return KeyValuePanelConfig(header: header, keyValues: makeInfoKeyPairs())
    }

    private func makeRarity(from rarity: NFTAsset.Rarity?) -> [KeyValuePairViewData] {
        guard let rarity else { return [] }

        let label = makeKeyValuePairViewDataIfPossible(
            key: Localization.nftDetailsRarityLabel,
            value: rarity.label,
            action: { [weak self] in self?.openRarityLabelDetails() }
        )

        let rankValue = rarity.rank
        let rank = makeKeyValuePairViewDataIfPossible(
            key: Localization.nftDetailsRarityRank,
            value: rankValue != nil ? "\(rankValue)" : nil,
            action: { [weak self] in self?.openRarityRankDetails() }
        )

        return [
            label,
            rank,
        ].compactMap { $0 }
    }

    private func makeTokenStandard(from standard: NFTContractType) -> String? {
        switch standard {
        case .erc721:
            "ERC-721"
        case .erc1155:
            "ERC-1155"
        case .other(let string):
            string
        case .unknown:
            nil
        }
    }

    /// Actions are under discussion, perhaps we wont do anything
    private func makeInfoKeyPairs() -> [KeyValuePairViewData] {
        let tokenStandard = makeKeyValuePairViewDataIfPossible(
            key: Localization.nftDetailsTokenStandard,
            value: makeTokenStandard(from: asset.contractType),
            action: { [weak self] in self?.opentTokenStandardDetails() }
        )

        let contractAddress = makeKeyValuePairViewDataIfPossible(
            key: Localization.nftDetailsContractAddress,
            value: asset.id.collectionIdentifier,
            action: { [weak self] in self?.opentTokenAddressDetails() }
        )

        let tokenID = makeKeyValuePairViewDataIfPossible(
            key: Localization.nftDetailsTokenId,
            value: asset.id.assetIdentifier,
            action: { [weak self] in self?.opentTokenIDDetails() }
        )

        let chain = makeKeyValuePairViewDataIfPossible(
            key: Localization.nftDetailsChain,
            value: nftChainNameProviding.provide(for: asset.id.chain),
            action: { [weak self] in self?.opentChainDetails() }
        )

        return [
            tokenStandard,
            contractAddress,
            tokenID,
            chain,
        ].compactMap { $0 }
    }

    private func makeTraits(from traits: [NFTAsset.Trait]) -> [KeyValuePairViewData] {
        traits.map {
            KeyValuePairViewData(
                key: KeyValuePairViewData.Key(text: $0.name, action: nil),
                value: KeyValuePairViewData.Value(text: $0.value, icon: nil)
            )
        }
    }

    private func makeKeyValuePairViewDataIfPossible(
        key: String,
        value: String?,
        action: @escaping () -> Void
    ) -> KeyValuePairViewData? {
        guard let value else { return nil }

        return KeyValuePairViewData(
            key: KeyValuePairViewData.Key(text: key, action: action),
            value: KeyValuePairViewData.Value(text: value, icon: nil)
        )
    }

    private func openAllTraits() {
        let traitsKeyValuePairs = makeTraits(from: asset.traits)
        coordinator?.openTraits(with: KeyValuePanelConfig(header: nil, keyValues: traitsKeyValuePairs))
    }

    private func explore() {}

    private func opentTokenStandardDetails() {}

    private func opentTokenAddressDetails() {}

    private func opentChainDetails() {}

    private func opentTokenIDDetails() {}

    private func openDescription() {}

    private func openRarityLabelDetails() {}

    private func openRarityRankDetails() {}
}

private extension NFTAssetDetailsViewModel {
    enum Constants {
        static let maximumTraits = 6
    }
}
