//
//  OnrampPaymentMethod+ThemedImage.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress

extension OnrampPaymentMethod {
    func themedImageURL(isDark: Bool) -> URL {
        guard FeatureProvider.isAvailable(.onrampPaymentMethodThemedImages) else {
            return image
        }

        return imageURL(isDark: isDark)
    }
}
