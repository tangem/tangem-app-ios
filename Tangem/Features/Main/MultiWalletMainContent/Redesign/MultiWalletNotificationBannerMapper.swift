//
//  MultiWalletNotificationBannerMapper.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import TangemUI
import TangemLocalization
import TangemAccessibilityIdentifiers

struct NotificationBannerItem: NotificationBannerContainerItem, Equatable {
    let id: NotificationViewId
    let bannerType: NotificationBanner.BannerType
    let priority: NotificationBanner.Priority
    let accessibilityIdentifier: String?
}

struct MultiWalletNotificationBannerMapper {
    func mapItems(
        _ inputs: [NotificationViewInput]...
    ) -> [NotificationBannerItem] {
        mapItems(inputs)
    }

    func mapItems(_ inputs: [[NotificationViewInput]]) -> [NotificationBannerItem] {
        inputs.flatMap { $0.map { mapItem($0) } }
    }
}

private extension MultiWalletNotificationBannerMapper {
    func mapItem(_ input: NotificationViewInput) -> NotificationBannerItem {
        NotificationBannerItem(
            id: input.id,
            bannerType: makeBannerType(from: input),
            priority: mapPriority(from: input.severity),
            accessibilityIdentifier: input.settings.event.accessibilityIdentifier
        )
    }

    func mapPriority(from severity: NotificationView.Severity) -> NotificationBanner.Priority {
        switch severity {
        case .critical, .warning:
            return .high
        case .info:
            return .low
        }
    }

    func makeBannerType(from input: NotificationViewInput) -> NotificationBanner.BannerType {
        let textOnly = makeTextOnly(from: input)
        let content = makeContent(textOnly: textOnly, input: input)
        let bannerAction = makeBannerAction(from: input)

        if let bannerKind = input.settings.event.bannerKind {
            let closeAction = makeCloseAction(from: input)
            return makeBannerType(
                bannerKind: bannerKind,
                content: content,
                textOnly: textOnly,
                bannerAction: bannerAction,
                closeAction: closeAction
            )
        }

        return makeSeverityBasedBannerType(
            severity: input.severity,
            content: content,
            bannerAction: bannerAction
        )
    }

    func makeBannerType(
        bannerKind: NotificationBannerKind,
        content: NotificationBanner.Content,
        textOnly: NotificationBanner.TextOnly,
        bannerAction: NotificationBanner.BannerAction,
        closeAction: NotificationBanner.CloseAction?
    ) -> NotificationBanner.BannerType {
        switch bannerKind {
        case .status:
            return .status(content, bannerAction)
        case .critical:
            return .critical(content, bannerAction)
        case .warning:
            return .warning(content, bannerAction)
        case .informational(let alignment):
            return .informational(textOnly, bannerAction, closeAction, mapTextAlignment(alignment))
        case .promo(let effect):
            return .promo(content, bannerAction, closeAction, mapEffect(effect))
        case .survey:
            return .survey(textOnly, bannerAction, closeAction)
        }
    }

    func mapTextAlignment(_ alignment: NotificationBannerKind.TextAlignment) -> NotificationBanner.BannerTextAlignment {
        switch alignment {
        case .leading: .leading
        case .center: .center
        }
    }

    func mapEffect(_ effect: NotificationBannerKind.Effect) -> NotificationBanner.Effect {
        switch effect {
        case .plain: .none
        case .card: .bannerCard
        case .magic: .bannerMagic
        }
    }

    func makeSeverityBasedBannerType(
        severity: NotificationView.Severity,
        content: NotificationBanner.Content,
        bannerAction: NotificationBanner.BannerAction
    ) -> NotificationBanner.BannerType {
        switch severity {
        case .critical:
            return .critical(content, bannerAction)
        case .warning:
            return .warning(content, bannerAction)
        case .info:
            return .status(content, bannerAction)
        }
    }

    func makeTextOnly(from input: NotificationViewInput) -> NotificationBanner.TextOnly {
        let event = input.settings.event
        let override = event.redesignedBannerContent

        let title: AttributedString = switch override?.title ?? event.title {
        case .string(let string): AttributedString(string)
        case .attributed(let attributed): attributed
        case .none: AttributedString("")
        }

        let subtitle = AttributedString(override?.description ?? event.description ?? "")

        return NotificationBanner.TextOnly(title: title, subtitle: subtitle)
    }

    func makeContent(
        textOnly: NotificationBanner.TextOnly,
        input: NotificationViewInput
    ) -> NotificationBanner.Content {
        let messageIcon = input.settings.event.redesignedBannerContent?.icon ?? input.settings.event.icon

        // Status pills center the trailing icon against the text (per design); other kinds keep top alignment.
        let iconAlignment: NotificationBanner.Icon.Alignment = {
            if case .status? = input.settings.event.bannerKind { return .center }
            return .top
        }()

        switch messageIcon.iconType {
        case .image(let imageType):
            let icon = NotificationBanner.Icon(
                imageType: imageType,
                alignment: iconAlignment,
                width: mapSizeUnit(from: messageIcon.size.width),
                height: mapSizeUnit(from: messageIcon.size.height),
                renderingMode: messageIcon.renderingMode,
                color: messageIcon.color,
                isLeading: messageIcon.isLeading
            )
            return .textWithIcon(.init(text: textOnly, icon: icon))
        case .loadableIcon(let url):
            let loadableAlignment: SwiftUI.Alignment = iconAlignment == .center ? .leading : .topLeading
            let icon = NotificationBanner.LoadableIcon(
                url: url,
                alignment: loadableAlignment,
                width: mapSizeUnit(from: messageIcon.size.width),
                height: mapSizeUnit(from: messageIcon.size.height)
            )
            return .textWithLoadableIcon(.init(text: textOnly, icon: icon))
        default:
            return .text(textOnly)
        }
    }

    func mapSizeUnit(from dimension: CGFloat) -> SizeUnit {
        let steps = Int((dimension / 4.0).rounded())

        switch steps {
        case ..<1: return .zero
        case 1: return .x1
        case 2: return .x2
        case 3: return .x3
        case 4: return .x4
        case 5: return .x5
        case 6: return .x6
        case 7: return .x7
        case 8: return .x8
        case 9: return .x9
        case 10: return .x10
        case 11: return .x11
        case 12: return .x12
        case 13: return .x13
        case 14: return .x14
        case 15: return .x15
        case 16: return .x16
        case 17: return .x17
        case 18: return .x18
        default: return .x18
        }
    }

    func makeBannerAction(from input: NotificationViewInput) -> NotificationBanner.BannerAction {
        switch input.style {
        case .plain:
            return .buttons(.none)

        case .tappable(_, let action):
            let notificationId = input.settings.id
            return .tappable(NotificationBanner.Action {
                action(notificationId)
            })

        case .withButtons(let notificationButtons):
            return .buttons(
                mapButtons(
                    notificationButtons,
                    notificationId: input.settings.id
                )
            )
        }
    }

    func mapButtons(
        _ notificationButtons: [NotificationView.NotificationButton],
        notificationId: NotificationViewId
    ) -> NotificationBanner.Buttons {
        switch notificationButtons.count {
        case 0:
            return .none
        case 1:
            let button = notificationButtons[0]
            return .one(
                mapButton(button, notificationId: notificationId),
                accessibilityIdentifier: buttonAccessibilityIdentifier(for: button.actionType)
            )
        default:
            let left = notificationButtons[0]
            let right = notificationButtons[1]
            return .two(
                left: mapButton(left, notificationId: notificationId),
                right: mapButton(right, notificationId: notificationId),
                leftAccessibilityIdentifier: buttonAccessibilityIdentifier(for: left.actionType),
                rightAccessibilityIdentifier: buttonAccessibilityIdentifier(for: right.actionType)
            )
        }
    }

    func buttonAccessibilityIdentifier(for actionType: NotificationButtonActionType) -> String {
        switch actionType {
        case .reduceAmountBy:
            return SendAccessibilityIdentifiers.reduceFeeButton
        case .leaveAmount:
            return SendAccessibilityIdentifiers.leaveAmountButton
        case .openFeeCurrency:
            return TokenAccessibilityIdentifiers.feeCurrencyNavigationButton
        case .openGetTangemPay:
            return TangemPayAccessibilityIdentifiers.getTangemPayBannerOpenButton
        default:
            return CommonUIAccessibilityIdentifiers.notificationButton
        }
    }

    func mapButton(
        _ button: NotificationView.NotificationButton,
        notificationId: NotificationViewId
    ) -> TangemButton.Model {
        let actionType = button.actionType

        return TangemButton.Model(
            content: mapButtonContent(actionType),
            styleType: mapButtonStyleType(actionType.style),
            cornerStyle: .rounded,
            action: { button.action(notificationId, actionType) }
        )
    }

    func mapButtonContent(_ actionType: NotificationButtonActionType) -> TangemButton.Content {
        let title = actionType.title
        let icon = actionType.icon

        if title.isNotEmpty {
            if let icon {
                switch icon {
                case .leading(let imageType):
                    return .combined(
                        text: .init(title),
                        icon: imageType,
                        iconPosition: .left
                    )
                case .trailing(let imageType):
                    return .combined(
                        text: .init(title),
                        icon: imageType,
                        iconPosition: .right
                    )
                }
            } else {
                return .text(.init(title))
            }
        } else {
            if let icon {
                switch icon {
                case .leading(let imageType):
                    return .combined(
                        text: .init(title),
                        icon: imageType,
                        iconPosition: .left
                    )
                case .trailing(let imageType):
                    return .combined(
                        text: .init(title),
                        icon: imageType,
                        iconPosition: .right
                    )
                }
            } else {
                assertionFailure(
                    "There is no icon nor text, so what should be displayed?"
                )
                return .text(.init(title))
            }
        }
    }

    func mapButtonStyleType(_ style: MainButton.Style) -> TangemButton.StyleType {
        switch style {
        case .primary: .primary
        case .secondary: .secondary
        }
    }

    func makeCloseAction(from input: NotificationViewInput) -> NotificationBanner.CloseAction? {
        guard input.settings.event.isDismissable else {
            return nil
        }

        let notificationId = input.settings.id
        let dismissAction = input.settings.dismissAction

        return NotificationBanner.CloseAction {
            dismissAction?(notificationId)
        }
    }
}
