//
//  ShtorkaMetrics.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemUIUtils

public enum ShtorkaMetrics {
    /// Starting height of the collapsed detent; consumers replace it with the measured height of their collapsed row.
    public static let collapsedHeight: CGFloat = 64

    /// Height the revealed content is laid out at until the sheet has been measured at the full detent.
    /// A large sheet spans the screen below the top safe area and a system gap; the gap is what the
    /// system leaves on a flat-screen phone, notched phones get 10 pt less and the measured sheet wins.
    static var minimumRevealedHeight: CGFloat {
        UIScreen.main.bounds.height - UIApplication.safeAreaInsets.top - largeDetentTopGap
    }

    private static var largeDetentTopGap: CGFloat {
        if #available(iOS 26.0, *) {
            return 10
        }

        return 20
    }
}
