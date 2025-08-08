//
//  Toast.swift
//  TangemUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import SwiftUI
import class TangemUIUtils.PassThroughWindow

public final class Toast<V: View> {
    private var timer: Timer?

    private lazy var hostingController: UIHostingController<some View> = {
        let content = view.fixedSize(horizontal: false, vertical: true)

        let controller = UIHostingController(rootView: content)
        controller.view.backgroundColor = .clear

        return controller
    }()

    private let view: V

    public init(view: V) {
        self.view = view
    }

    deinit {
        dismiss(animated: false)
    }

    public func present(
        layout: Layout,
        type: PresentationTime,
        animated: Bool = true
    ) {
        let overlayWindow = UIApplication.shared.windows.last { $0 is PassThroughWindow }
        let mainWindow = UIApplication.mainWindow

        guard let window = overlayWindow ?? mainWindow else {
            return
        }

        switch type {
        case .always:
            break
        case .temporary(let interval):
            timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { _ in
                self.dismiss(animated: true) { withExtendedLifetime(self) {} }
            }
        }

        if animated {
            hostingController.view.alpha = 0
            hostingController.view.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        }

        window.addSubview(hostingController.view)

        setupConstraints(with: window.safeAreaLayoutGuide, and: layout)

        hostingController.view.layoutIfNeeded()

        if animated {
            UIView.animate(
                withDuration: 0.5,
                delay: 0,
                options: .curveEaseOut
            ) {
                self.hostingController.view.alpha = 1
                self.hostingController.view.transform = .identity
            }
        }
    }

    public func dismiss(animated: Bool, completion: @escaping () -> Void = {}) {
        timer?.invalidate()
        timer = nil

        if animated {
            UIView.animate(withDuration: 0.5) {
                self.hostingController.view.alpha = 0
            } completion: { _ in
                self.hostingController.view.removeFromSuperview()
                completion()
            }
        } else {
            hostingController.view.removeFromSuperview()
            completion()
        }
    }
}

// MARK: - Layout

private extension Toast {
    func setupConstraints(with safeAreaLayoutGuide: UILayoutGuide, and verticalLayout: Layout) {
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false

        var constraints: [NSLayoutConstraint] = [
            hostingController.view.leadingAnchor.constraint(
                equalTo: safeAreaLayoutGuide.leadingAnchor,
                constant: 16
            ),
            hostingController.view.trailingAnchor.constraint(
                equalTo: safeAreaLayoutGuide.trailingAnchor,
                constant: -16
            ),
            hostingController.view.centerXAnchor.constraint(
                equalTo: safeAreaLayoutGuide.centerXAnchor
            ),
        ]

        switch verticalLayout {
        case .top(let padding):
            constraints.append(
                hostingController.view.topAnchor.constraint(
                    equalTo: safeAreaLayoutGuide.topAnchor,
                    constant: padding
                )
            )
        case .bottom(let padding):
            constraints.append(
                hostingController.view.bottomAnchor.constraint(
                    equalTo: safeAreaLayoutGuide.bottomAnchor,
                    constant: -padding
                )
            )
        }

        NSLayoutConstraint.activate(constraints)
    }
}

public extension Toast {
    enum PresentationTime {
        case always
        case temporary(interval: TimeInterval = 2)
    }

    enum Layout {
        case top(padding: CGFloat = 80)
        case bottom(padding: CGFloat = 80)
    }
}
