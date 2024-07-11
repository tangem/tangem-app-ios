//
//  ContainerVC.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import UIKit

final class ContainerVC: UIViewController {
    let contentVC: UIViewController
    let overlayVC: UIViewController
    let overlayVCCollapsedHeight: CGFloat
    let overlayVCExpandedYOffset: CGFloat = 64.0
    var overlayVCCollapsedYOffset: CGFloat { UIScreen.main.bounds.height - overlayVCCollapsedHeight }
    let minScale = 0.95
    let maxScale = 1.0
    let minAlpha = 0.0
    let maxAlpha = 0.5
    let cornerRadius = 14.0
    let animDuration = 0.3

    private var progress = 0.0 {
        didSet {
            updateScale()
            updateAlpha()
        }
    }

    private var isFinalProgress: Bool {
        return abs(progress) <= .ulpOfOne || abs(1.0 - progress) <= .ulpOfOne
    }

    private var constraint: NSLayoutConstraint!
    private var backgroundShadowView: UIView!

    init(
        contentVC: UIViewController,
        overlayVC: UIViewController,
        overlayVCCollapsedHeight: CGFloat
    ) {
        self.contentVC = contentVC
        self.overlayVC = overlayVC
        self.overlayVCCollapsedHeight = overlayVCCollapsedHeight
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupGR()
        setupContent()
        setupBackgroundShadowView() // The order in which this method is called matters
        setupOverlay()
        let _ = print("\(#function) called at \(CACurrentMediaTime())")
    }

    private func setupView() {
        view.backgroundColor = .black
    }

    private func setupBackgroundShadowView() {
        let backgroundShadowView = UIView()
        backgroundShadowView.backgroundColor = .black
        backgroundShadowView.alpha = minAlpha
        backgroundShadowView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        backgroundShadowView.isUserInteractionEnabled = false
        view.addSubview(backgroundShadowView)
        self.backgroundShadowView = backgroundShadowView
    }

    private func setupContent() {
        addChild(contentVC)

        let containerView = view!
        let contentView = contentVC.view!
        containerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(contentView)

        NSLayoutConstraint.activate([
            contentView.heightAnchor.constraint(equalToConstant: UIScreen.main.bounds.height),
            contentView.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.width),
        ])

        contentView.layer.cornerRadius = cornerRadius
        contentView.layer.masksToBounds = true

        contentVC.didMove(toParent: self)
    }

    private func setupOverlay() {
        addChild(overlayVC)

        let containerView = view!
        let overlayView = overlayVC.view!
        containerView.translatesAutoresizingMaskIntoConstraints = false
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(overlayView)

        constraint = overlayView
            .topAnchor
            .constraint(equalTo: containerView.topAnchor, constant: overlayVCCollapsedYOffset)

        NSLayoutConstraint.activate([
            constraint,
            overlayView.heightAnchor.constraint(equalToConstant: UIScreen.main.bounds.height),
            overlayView.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.width),
        ])

        overlayView.layer.cornerRadius = cornerRadius // [REDACTED_TODO_COMMENT]
        overlayView.layer.masksToBounds = true

        overlayVC.didMove(toParent: self)
    }

    private func setupGR() {
        let gr = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        gr.delegate = self
        view.addGestureRecognizer(gr)
    }

    private func updateProgress() {
        progress = clamp(
            (overlayVCCollapsedYOffset - constraint.constant) / (overlayVCCollapsedYOffset - overlayVCExpandedYOffset),
            min: 0.0,
            max: 1.0
        )
        let _ = print("\(#function) called at \(CACurrentMediaTime()) with \(progress)")
    }

    private func updateScale() {
        let invertedProgress = 1.0 - progress
        let scale = minScale + (maxScale - minScale) * invertedProgress
        let layer = contentVC.view.layer

        if isFinalProgress {
            let anim = CABasicAnimation(keyPath: "transform")
            anim.duration = animDuration
            layer.add(anim, forKey: "ContainerVC_scale")
        }

        let transform: CGAffineTransform = .scaleTransform(
            for: layer.bounds.size,
            scaledBy: .init(x: scale, y: scale),
            aroundAnchorPoint: .init(x: 0.0, y: 1.0),
            translationCoefficient: 0.5
        )

        contentVC.view.layer.setAffineTransform(transform)
    }

    private func updateAlpha() {
        let alpha = minAlpha + (maxAlpha - minAlpha) * progress

        if isFinalProgress {
            UIView.animate(withDuration: animDuration) {
                self.backgroundShadowView.alpha = alpha
            }
        } else {
            backgroundShadowView.alpha = alpha
        }
    }

    @objc
    private func handlePan(_ gr: UIPanGestureRecognizer) {
        let _ = print("\(#function) called at \(CACurrentMediaTime()) with \(gr.state)")
        switch gr.state {
        case .possible:
            break
        case .began:
            break
        case .changed:
            constraint.constant += gr.translation(in: nil).y
            gr.setTranslation(.zero, in: nil)
            updateProgress()
        case .ended:
            let targetOffset = gr.location(in: nil).y > UIScreen.main.bounds.height / 2.0
                ? overlayVCCollapsedYOffset
                : overlayVCExpandedYOffset

            constraint.constant = targetOffset
            UIView.animate(withDuration: animDuration) {
                self.view.layoutIfNeeded()
            }

            updateProgress()
        case .cancelled:
            break
        case .failed:
            break
        case .recognized:
            break
        @unknown default:
            fatalError()
        }
    }
}

// MARK: - UIGestureRecognizerDelegate protocol conformance

extension ContainerVC: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        let point = touch.location(in: nil)

        return overlayVC.view.frame.contains(point)
    }
}
