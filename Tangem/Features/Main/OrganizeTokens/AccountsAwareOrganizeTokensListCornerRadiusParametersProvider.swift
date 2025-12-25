//
//  AccountsAwareOrganizeTokensListCornerRadiusParametersProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import struct UIKit.UIRectCorner

// [REDACTED_TODO_COMMENT]
struct AccountsAwareOrganizeTokensListCornerRadiusParametersProvider {
    private let sections: [OrganizeTokensListOuterSection]
    private let cornerRadius: CGFloat

    init(
        sections: [OrganizeTokensListOuterSection],
        cornerRadius: CGFloat
    ) {
        self.sections = sections
        self.cornerRadius = cornerRadius
    }

    // MARK: - Outer sections

    func cornerRadius(forOuterSectionAtIndex sectionIndex: Int) -> CGFloat {
        switch sections[sectionIndex].model.style {
        case .invisible:
            return 0.0
        case .default:
            return cornerRadius
        }
    }

    func rectCorners(forOuterSectionAtIndex sectionIndex: Int) -> UIRectCorner {
        switch sections[sectionIndex].model.style {
        case .invisible:
            return []
        case .default:
            return [.topLeft, .topRight]
        }
    }

    // MARK: - Inner sections

    func cornerRadius(forInnerSectionAt indexPath: OrganizeTokensIndexPath) -> CGFloat {
        let outerSectionStyle = sections[indexPath.outerSection].model.style
        let innerSectionStyle = sections[indexPath.outerSection].items[indexPath.innerSection].model.style

        switch (outerSectionStyle, innerSectionStyle) {
        case (.invisible, .draggable),
             (.invisible, .fixed):
            return cornerRadius
        default:
            return 0.0
        }
    }

    func rectCorners(forInnerSectionAt indexPath: OrganizeTokensIndexPath) -> UIRectCorner {
        let outerSectionStyle = sections[indexPath.outerSection].model.style
        let innerSectionStyle = sections[indexPath.outerSection].items[indexPath.innerSection].model.style

        switch (outerSectionStyle, innerSectionStyle) {
        case (.invisible, .draggable),
             (.invisible, .fixed):
            return [.topLeft, .topRight]
        default:
            return []
        }
    }

    // MARK: - Cells

    func cornerRadius(
        forItemAt indexPath: OrganizeTokensIndexPath
    ) -> CGFloat {
        let outerSectionStyle = sections[indexPath.outerSection].model.style
        let innerSectionStyle = sections[indexPath.outerSection].items[indexPath.innerSection].model.style

        switch (outerSectionStyle, innerSectionStyle) {
        case (.invisible, .invisible):
            let hasCornerRadius = isFirstItemInSection(at: indexPath) || isLastItemInSection(at: indexPath, outerSectionStyle: outerSectionStyle)
            return hasCornerRadius ? cornerRadius : 0.0
        default:
            return isLastItemInSection(at: indexPath, outerSectionStyle: outerSectionStyle) ? cornerRadius : 0.0
        }
    }

    func rectCorners(
        forItemAt indexPath: OrganizeTokensIndexPath
    ) -> UIRectCorner {
        var rectCorners = UIRectCorner()
        let outerSectionStyle = sections[indexPath.outerSection].model.style
        let innerSectionStyle = sections[indexPath.outerSection].items[indexPath.innerSection].model.style

        switch (outerSectionStyle, innerSectionStyle) {
        case (.invisible, .invisible):
            if isFirstItemInSection(at: indexPath) {
                rectCorners.insert(.topLeft)
                rectCorners.insert(.topRight)
            }
            if isLastItemInSection(at: indexPath, outerSectionStyle: outerSectionStyle) {
                rectCorners.insert(.bottomLeft)
                rectCorners.insert(.bottomRight)
            }
        default:
            if isLastItemInSection(at: indexPath, outerSectionStyle: outerSectionStyle) {
                rectCorners.insert(.bottomLeft)
                rectCorners.insert(.bottomRight)
            }
        }

        return rectCorners
    }

    private func isFirstItemInSection(at indexPath: OrganizeTokensIndexPath) -> Bool {
        return indexPath.innerSection == 0 && indexPath.item == 0
    }

    private func isLastItemInSection(
        at indexPath: OrganizeTokensIndexPath,
        outerSectionStyle: OrganizeTokensListOuterSectionViewModel.SectionStyle
    ) -> Bool {
        let isLastItemInInnerSection = indexPath.item == sections[indexPath.outerSection].items[indexPath.innerSection].items.count - 1

        switch outerSectionStyle {
        case .invisible:
            return isLastItemInInnerSection
        case .default:
            return isLastItemInInnerSection && indexPath.innerSection == sections[indexPath.outerSection].items.count - 1
        }
    }
}
