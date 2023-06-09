//
//  OrganizeTokensListCornerRadiusParametersProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import struct UIKit.UIRectCorner

struct OrganizeTokensListCornerRadiusParametersProvider {
    private let sections: [OrganizeTokensListSectionViewModel]

    init(sections: [OrganizeTokensListSectionViewModel]) {
        self.sections = sections
    }

    func cornerRadius(forSectionAtIndex sectionIndex: Int) -> CGFloat {
        return sectionIndex == 0 ? 14.0 : 0.0
    }

    func rectCorners(forSectionAtIndex sectionIndex: Int) -> UIRectCorner {
        return sectionIndex == 0 ? [.topLeft, .topRight] : []
    }

    func cornerRadius(
        forItemAtIndexPath indexPath: IndexPath
    ) -> CGFloat {
        if indexPath.section == sections.count - 1,
           indexPath.item == sections[indexPath.section].items.count - 1 {
            return 14.0
        }

        if case .invisible = sections[indexPath.section].style,
           indexPath.section == 0,
           indexPath.item == 0 {
            return 14.0
        }

        return 0.0
    }

    func rectCorners(
        forItemAtIndexPath indexPath: IndexPath
    ) -> UIRectCorner {
        var rectCorners = UIRectCorner()

        if indexPath.section == sections.count - 1,
           indexPath.item == sections[indexPath.section].items.count - 1 {
            rectCorners.insert(.bottomLeft)
            rectCorners.insert(.bottomRight)
        }

        if case .invisible = sections[indexPath.section].style,
           indexPath.section == 0,
           indexPath.item == 0 {
            rectCorners.insert(.topLeft)
            rectCorners.insert(.topRight)
        }

        return rectCorners
    }
}
