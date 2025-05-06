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

    var media: NFTMedia? {
        asset.media
    }

    // [REDACTED_TODO_COMMENT]
    var headerState: NFTDetailsHeaderState? {
        let rarityKeyValuePairs = makeRarity(from: asset.rarity)

        if let description = asset.description, description.isNotEmpty {
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

        if rarityKeyValuePairs.isNotEmpty {
            return .rarity(rarityKeyValuePairs)
        }

        return nil
    }

    var traits: KeyValuePanelViewData? {
        guard asset.traits.isNotEmpty else {
            return nil
        }

        let maximumTraits = asset.traits.prefix(Constants.maximumTraits)

        let header = if asset.traits.count > Constants.maximumTraits {
            KeyValuePanelViewData.Header(
                title: Localization.nftDetailsTraits,
                actionConfig: KeyValuePanelViewData.Header.ActionConfig(
                    buttonTitle: Localization.commonSeeAll,
                    image: nil,
                    action: { [weak self] in self?.openAllTraits() }
                )
            )
        } else {
            KeyValuePanelViewData.Header(title: Localization.nftDetailsTraits, actionConfig: nil)
        }

        return KeyValuePanelViewData(
            header: header,
            keyValues: makeTraits(from: Array(maximumTraits))
        )
    }

    var baseInformation: KeyValuePanelViewData? {
        let header = KeyValuePanelViewData.Header(
            title: Localization.nftDetailsBaseInformation,
            actionConfig: KeyValuePanelViewData.Header.ActionConfig(
                buttonTitle: Localization.commonExplore,
                image: Assets.compassExplore,
                action: { [weak self] in self?.explore() }
            )
        )

        return KeyValuePanelViewData(header: header, keyValues: makeInfoKeyPairs())
    }

    private func makeRarity(from rarity: NFTAsset.Rarity?) -> [KeyValuePairViewData] {
        guard let rarity else { return [] }

        let label = makeKeyValuePairViewDataIfPossible(
            key: Localization.nftDetailsRarityLabel,
            value: rarity.label,
            action: { [weak self] in
                self?.openAssetExtendedInfo(
                    title: Localization.nftDetailsRarityLabel,
                    text: Localization.nftDetailsInfoRarityLabel
                )
            }
        )

        let rankValue = rarity.rank
        let rank = makeKeyValuePairViewDataIfPossible(
            key: Localization.nftDetailsRarityRank,
            value: rankValue != nil ? "\(rankValue)" : nil,
            action: { [weak self] in
                self?.openAssetExtendedInfo(
                    title: Localization.nftDetailsRarityRank,
                    text: Localization.nftDetailsInfoRarityRank
                )
            }
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
            action: { [weak self] in
                self?.openAssetExtendedInfo(
                    title: Localization.nftDetailsTokenStandard,
                    text: Localization.nftDetailsInfoTokenStandard
                )
            }
        )

        let contractAddress = makeKeyValuePairViewDataIfPossible(
            key: Localization.nftDetailsContractAddress,
            value: asset.id.collectionIdentifier,
            action: { [weak self] in
                self?.openAssetExtendedInfo(
                    title: Localization.nftDetailsContractAddress,
                    text: Localization.nftDetailsInfoContractAddress
                )
            }
        )

        let tokenID = makeKeyValuePairViewDataIfPossible(
            key: Localization.nftDetailsTokenId,
            value: asset.id.assetIdentifier,
            action: { [weak self] in
                self?.openAssetExtendedInfo(
                    title: Localization.nftDetailsTokenId,
                    text: Localization.nftDetailsInfoTokenId
                )
            }
        )

        let chain = makeKeyValuePairViewDataIfPossible(
            key: Localization.nftDetailsChain,
            value: nftChainNameProviding.provide(for: asset.id.chain),
            action: { [weak self] in
                self?.openAssetExtendedInfo(
                    title: Localization.nftDetailsChain,
                    text: Localization.nftDetailsInfoChain
                )
            }
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
        coordinator?.openTraits(with: KeyValuePanelViewData(header: nil, keyValues: traitsKeyValuePairs))
    }

    private func explore() {
        coordinator?.openExplorer(for: asset)
    }

    private func openDescription() {
        guard let description = asset.description else { return }

        coordinator?.openInfo(
            with: NFTAssetExtendedInfoViewData(
                title: Localization.nftAboutTitle,
                text: description
            )
        )
    }

    private func openAssetExtendedInfo(title: String, text: String) {
        coordinator?.openInfo(with: NFTAssetExtendedInfoViewData(title: title, text: text))
    }
}

private extension NFTAssetDetailsViewModel {
    enum Constants {
        static let maximumTraits = 6
    }
}
