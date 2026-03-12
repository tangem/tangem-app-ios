//
//  RefreshScrollViewObserver.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import UIKit

@MainActor
public protocol RefreshScrollViewObserver: UIScrollViewDelegate {
    func scrollViewDidSet(_ scrollView: UIScrollView?)
}
