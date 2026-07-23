//
//  SyncedHorizontalScrollView.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import UIKit

struct SyncedHorizontalScrollView<Content: View>: UIViewControllerRepresentable {
    @Binding var contentOffset: CGPoint
    let itemWidth: CGFloat
    let step: CGFloat
    @ViewBuilder let content: Content

    func makeUIViewController(context: Context) -> Controller {
        Controller(
            contentOffset: $contentOffset,
            itemWidth: itemWidth,
            step: step,
            content: content
        )
    }

    func updateUIViewController(_ controller: Controller, context: Context) {
        controller.itemWidth = itemWidth
        controller.step = step
        controller.host.rootView = content

        if controller.scrollView.contentOffset != contentOffset {
            controller.scrollView.setContentOffset(contentOffset, animated: context.transaction.animation != nil)
        }
    }

    final class Controller: UIViewController, UIScrollViewDelegate {
        let scrollView = UIScrollView()
        let host: UIHostingController<Content>

        private let contentOffset: Binding<CGPoint>
        private var dragStartOffsetX: CGFloat = 0
        var itemWidth: CGFloat
        var step: CGFloat

        init(contentOffset: Binding<CGPoint>, itemWidth: CGFloat, step: CGFloat, content: Content) {
            self.contentOffset = contentOffset
            self.itemWidth = itemWidth
            self.step = step
            host = UIHostingController(rootView: content)

            super.init(nibName: nil, bundle: nil)

            scrollView.delegate = self
            scrollView.showsHorizontalScrollIndicator = false
            scrollView.showsVerticalScrollIndicator = false
            scrollView.alwaysBounceHorizontal = true
            scrollView.alwaysBounceVertical = false
            scrollView.decelerationRate = .fast
            scrollView.contentInset = .init(top: 0, left: 16, bottom: 0, right: 16)
            scrollView.backgroundColor = .clear
            host.view.backgroundColor = .clear

            scrollView.translatesAutoresizingMaskIntoConstraints = false
            host.view.translatesAutoresizingMaskIntoConstraints = false

            view = scrollView
            addChild(host)
            scrollView.addSubview(host.view)
            host.didMove(toParent: self)

            let contentView = host.view!
            let frame = scrollView.frameLayoutGuide
            let contentGuide = scrollView.contentLayoutGuide
            NSLayoutConstraint.activate([
                contentView.topAnchor.constraint(equalTo: frame.topAnchor),
                contentView.bottomAnchor.constraint(equalTo: frame.bottomAnchor),
                contentView.leadingAnchor.constraint(equalTo: contentGuide.leadingAnchor),
                contentView.trailingAnchor.constraint(equalTo: contentGuide.trailingAnchor),
                contentView.topAnchor.constraint(equalTo: contentGuide.topAnchor),
                contentView.bottomAnchor.constraint(equalTo: contentGuide.bottomAnchor),
            ])
        }

        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            let new = scrollView.contentOffset
            guard new != contentOffset.wrappedValue else { return }

            DispatchQueue.main.async { [self] in
                contentOffset.wrappedValue = new
            }
        }

        func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
            dragStartOffsetX = scrollView.contentOffset.x
        }

        func scrollViewWillEndDragging(
            _ scrollView: UIScrollView,
            withVelocity velocity: CGPoint,
            targetContentOffset: UnsafeMutablePointer<CGPoint>
        ) {
            guard step > 0 else { return }

            let leadingInset = scrollView.contentInset.left
            let startIndex = ((dragStartOffsetX + leadingInset) / step).rounded()
            let translation = scrollView.contentOffset.x - dragStartOffsetX
            let translationThreshold = step * 0.1

            var targetIndex = startIndex
            if velocity.x > 0 || translation > translationThreshold {
                targetIndex += 1
            } else if velocity.x < 0 || translation < -translationThreshold {
                targetIndex -= 1
            }

            let lastIndex = max(0, ((scrollView.contentSize.width - itemWidth) / step).rounded())
            targetIndex = min(max(targetIndex, 0), lastIndex)

            targetContentOffset.pointee.x = targetIndex * step - leadingInset
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}
