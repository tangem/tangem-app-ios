//
//  MarketsTokenDetailsLinksMapper.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import UIKit
import TangemAssets

struct MarketsTokenDetailsLinksMapper {
    let openLinkAction: (MarketsTokenDetailsLinks.LinkInfo) -> Void

    func mapToSections(_ links: MarketsTokenDetailsLinks?) -> [MarketsTokenDetailsLinkSection] {
        guard let links else {
            return []
        }

        var sections = [MarketsTokenDetailsLinkSection]()
        if let officialLinks = links.officialLinks, !officialLinks.isEmpty {
            sections.append(.init(section: .officialLinks, chips: mapLinksToChips(officialLinks)))
        }
        if let socialLinks = links.social, !socialLinks.isEmpty {
            sections.append(.init(section: .social, chips: mapLinksToChips(socialLinks)))
        }
        if let repositoryLinks = links.repository, !repositoryLinks.isEmpty {
            sections.append(.init(section: .repository, chips: mapLinksToChips(repositoryLinks)))
        }
        if let blockchainSiteLinks = links.blockchainSite, !blockchainSiteLinks.isEmpty {
            sections.append(.init(section: .blockchainSite, chips: mapLinksToChips(blockchainSiteLinks)))
        }

        return sections
    }

    private func mapLinksToChips(_ links: [MarketsTokenDetailsLinks.LinkInfo]) -> [MarketsTokenDetailsLinkChipsData] {
        links.compactMap(mapLinkToChips)
    }

    private func mapLinkToChips(_ linkInfo: MarketsTokenDetailsLinks.LinkInfo) -> MarketsTokenDetailsLinkChipsData? {
        let icon = Self.mapLinkInfoToKnownSocialNetworkAsset(linkInfo)

        let title = if let url = URL(string: linkInfo.title), let hostTitle = url.host {
            hostTitle
        } else {
            linkInfo.title
        }

        let urlLink = if linkInfo.link.hasPrefix(Constants.httpPrefix) {
            linkInfo.link
        } else {
            Constants.defaultScheme + linkInfo.link
        }

        guard let url = URL(string: urlLink), UIApplication.shared.canOpenURL(url) else {
            return nil
        }

        return .init(
            text: title,
            icon: .leading(icon),
            link: urlLink,
            action: {
                openLinkAction(
                    .init(
                        id: linkInfo.id,
                        title: linkInfo.title,
                        link: urlLink
                    )
                )
            }
        )
    }

    private static func mapLinkInfoToKnownSocialNetworkAsset(_ linkInfo: MarketsTokenDetailsLinks.LinkInfo) -> ImageType {
        switch linkInfo.id {
        case "discord":
            Assets.SocialNetwork.discord
        case "facebook":
            Assets.SocialNetwork.facebook
        case "github":
            Assets.SocialNetwork.github
        case "instagram":
            Assets.SocialNetwork.instagram
        case "linkedin":
            Assets.SocialNetwork.linkedin
        case "reddit":
            Assets.SocialNetwork.reddit
        case "telegram":
            Assets.SocialNetwork.telegram
        case "twitter":
            Assets.SocialNetwork.twitter
        case "youtube":
            Assets.SocialNetwork.youtube
        case "whitepaper":
            Assets.whitepaper
        default:
            Assets.arrowRightUp
        }
    }
}

extension MarketsTokenDetailsLinksMapper {
    private enum Constants {
        static let httpPrefix = "http"
        static let defaultScheme = "https://"
    }
}
