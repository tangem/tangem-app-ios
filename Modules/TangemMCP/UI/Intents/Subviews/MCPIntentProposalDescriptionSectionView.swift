//
//  MCPIntentProposalDescriptionSectionView.swift
//  TangemModules
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import Kingfisher
import TangemAssets
import TangemUI
import TangemUIUtils

struct MCPIntentProposalDescriptionSectionView: View {
    let section: MCPIntentProposalDescriptionSection
    let kingfisherImageCache: ImageCache

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                agentIcon

                Text(section.agent.host)
                    .font(token: DesignSystem.Font.captionMediumToken)
                    .foregroundStyle(DesignSystem.Color.textSecondary)

                Spacer(minLength: .zero)
            }

            Text(section.body)
                .font(token: DesignSystem.Font.subheadingMediumToken)
                .fixedSize(horizontal: false, vertical: true)
                .foregroundStyle(DesignSystem.Color.textPrimary)
        }
        .padding(16)
        .background(DesignSystem.Color.bgTransparentOnMaterialPrimary)
        .clipShape(.rect(cornerRadius: 24))
    }

    private var agentIcon: some View {
        KFImage(section.agent.iconURL)
            .placeholder {
                Shimmer()
            }
            .onFailureView {
                DesignSystem.Icons.Server.filled12.image
                    .resizable()
                    .scaledToFit()
                    .frame(size: .init(bothDimensions: 12))
                    .foregroundStyle(DesignSystem.Color.iconBrand)
                    .frame(size: .init(bothDimensions: 16))
                    .background(DesignSystem.Color.bgStatusInfoSubtle)
            }
            .targetCache(kingfisherImageCache)
            .resizable()
            .scaledToFit()
            .frame(size: .init(bothDimensions: 16))
            .clipShape(.rect(cornerRadius: 4))
    }
}
