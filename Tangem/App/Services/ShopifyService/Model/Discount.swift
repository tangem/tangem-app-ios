//
//  Discount.swift
//  TangemShopify
//
//  Created by [REDACTED_AUTHOR]
//

import MobileBuySDK

struct Discount {
    private enum DiscountValue {
        case flat(Decimal)
        case percent(Decimal)
    }

    let code: String

    private let value: DiscountValue

    init?(_ discount: DiscountApplication) {
        // HACK: `code` property is not exposed through the DiscountApplication protocol
        if let discountCodeApplication = discount as? Storefront.DiscountCodeApplication {
            code = discountCodeApplication.code
        } else {
            return nil
        }

        switch discount.value {
        case let percentValue as Storefront.PricingPercentageValue:
            value = .percent(Decimal(percentValue.percentage))
        case let flatValue as Storefront.MoneyV2:
            value = .flat(flatValue.amount)
        default:
            AppLog.shared.debug("Unknown discount value")
            return nil
        }
    }
}

extension Discount {
    func discountAmount(itemsTotal: Decimal) -> Decimal {
        switch value {
        case .flat(let flatAmount):
            return flatAmount
        case .percent(let percentageAmount):
            var raw = itemsTotal * percentageAmount / 100
            var rounded = Decimal.zero
            NSDecimalRound(&rounded, &raw, 2, .bankers)
            return rounded
        }
    }

    func payDiscount(itemsTotal: Decimal) -> PayDiscount {
        return PayDiscount(code: code, amount: discountAmount(itemsTotal: itemsTotal))
    }
}

extension Storefront.DiscountCodeApplicationQuery {
    func discountFieldsFragment() {
        code()
            .value { $0
                .onMoneyV2 { $0
                    .amount()
                }
                .onPricingPercentageValue { $0
                    .percentage()
                }
            }
    }
}
