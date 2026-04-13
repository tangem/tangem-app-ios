//
//  PromotionMapper.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

enum PromotionMapper {
    static func mapToPromotion(from dto: PromotionsDTO.Load.Item) -> Promotion? {
        guard let id = dto.id,
              let placeholder = dto.placeholder,
              let title = dto.title,
              let subtitle = dto.subtitle,
              let iconUrl = dto.iconUrl else {
            return nil
        }

        return Promotion(
            id: id,
            placeholder: placeholder,
            priority: dto.priority,
            title: title,
            subtitle: subtitle,
            iconUrl: iconUrl,
            deeplink: dto.deeplink,
            buttonEnabled: dto.buttonEnabled ?? false,
            buttonText: dto.buttonText,
            dismissable: dto.dismissable ?? false
        )
    }
}
