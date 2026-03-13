//
//  MultiWalletNotificationBannerMapper.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemUI
import TangemLocalization

struct NotificationBannerItem: NotificationBannerContainerItem, Equatable {
    let id: NotificationViewId
    let bannerType: NotificationBanner.BannerType
    let priority: NotificationBanner.Priority
}

struct MultiWalletNotificationBannerMapper {
    func mapItems(
        _ inputs: [NotificationViewInput]...
    ) -> [NotificationBannerItem] {
        inputs.flatMap { $0.map { mapItem($0) } }
    }
}

private extension MultiWalletNotificationBannerMapper {
    func mapItem(_ input: NotificationViewInput) -> NotificationBannerItem {
        NotificationBannerItem(
            id: input.id,
            bannerType: makeBannerType(from: input),
            priority: mapPriority(from: input.severity)
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
            textOnly: textOnly,
            bannerAction: bannerAction,
            input: input
        )
    }

    func makeBannerType(
        bannerKind: NotificationBannerKind,
        content: NotificationBanner.Content,
        textOnly: NotificationBanner.TextOnly,
        bannerAction: NotificationBanner.BannerAction,
        closeAction: NotificationBanner.CloseAction
    ) -> NotificationBanner.BannerType {
        switch bannerKind {
        case .status:
            return .status(content)
        case .critical:
            return .critical(content, bannerAction)
        case .warning:
            return .warning(content, bannerAction)
        case .informational:
            return .informational(textOnly, bannerAction, closeAction)
        case .promo(let effect):
            return .promo(textOnly, bannerAction, closeAction, mapEffect(effect))
        case .survey:
            return .survey(textOnly, bannerAction, closeAction)
        }
    }

    func mapEffect(_ effect: NotificationBannerKind.Effect) -> NotificationBanner.Effect {
        switch effect {
        case .card: .bannerCard
        case .magic: .bannerMagic
        }
    }

    func makeSeverityBasedBannerType(
        severity: NotificationView.Severity,
        content: NotificationBanner.Content,
        textOnly: NotificationBanner.TextOnly,
        bannerAction: NotificationBanner.BannerAction,
        input: NotificationViewInput
    ) -> NotificationBanner.BannerType {
        switch severity {
        case .critical:
            return .critical(content, bannerAction)
        case .warning:
            return .warning(content, bannerAction)
        case .info:
            if input.settings.event.isDismissable {
                let closeAction = makeCloseAction(from: input)
                return .informational(textOnly, bannerAction, closeAction)
            }

            return .status(content)
        }
    }

    func makeTextOnly(from input: NotificationViewInput) -> NotificationBanner.TextOnly {
        let title: AttributedString = switch input.settings.event.title {
        case .string(let string): AttributedString(string)
        case .attributed(let attributed): attributed
        case .none: AttributedString("")
        }

        let subtitle = AttributedString(input.settings.event.description ?? "")

        return NotificationBanner.TextOnly(title: title, subtitle: subtitle)
    }

    func makeContent(
        textOnly: NotificationBanner.TextOnly,
        input: NotificationViewInput
    ) -> NotificationBanner.Content {
        let messageIcon = input.settings.event.icon

        guard case .image(let imageType) = messageIcon.iconType else {
            return .text(textOnly)
        }

        let icon = NotificationBanner.Icon(
            imageType: imageType,
            width: mapSizeUnit(from: messageIcon.size.width),
            height: mapSizeUnit(from: messageIcon.size.height),
            renderingMode: messageIcon.renderingMode
        )

        return .textWithIcon(.init(text: textOnly, icon: icon))
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
        default: return .x7
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
        case .zero:
            return .none
        case .one:
            return .one(
                mapButton(notificationButtons[0], notificationId: notificationId)
            )
        default:
            return .two(
                left: mapButton(
                    notificationButtons[0],
                    notificationId: notificationId
                ),
                right: mapButton(
                    notificationButtons[1],
                    notificationId: notificationId
                )
            )
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

    func makeCloseAction(from input: NotificationViewInput) -> NotificationBanner.CloseAction {
        let notificationId = input.settings.id
        let dismissAction = input.settings.dismissAction

        return NotificationBanner.CloseAction {
            dismissAction?(notificationId)
        }
    }
}
