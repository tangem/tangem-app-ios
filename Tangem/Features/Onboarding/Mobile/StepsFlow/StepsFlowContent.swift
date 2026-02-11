//
//  StepsFlowContent.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import UIKit
import SwiftUI
import Combine

struct StepsFlowContent: UIViewControllerRepresentable {
    let actions: AnyPublisher<StepsFlowAction, Never>

    func makeUIViewController(context: Context) -> UIViewController {
        let flowVC = StepsFlowContentViewController()
        flowVC.bind(actions: actions)
        return flowVC
    }

    func updateUIViewController(_ viewController: UIViewController, context: Context) {}
}

private final class StepsFlowContentViewController: UIViewController {
    typealias Step = any StepsFlowStep
    typealias StepId = AnyHashable

    private var currentStepId: StepId?
    private var cache: [StepId: UIViewController] = [:]

    private var currentStepVC: UIViewController? {
        guard let currentStepId else { return nil }
        return cache[currentStepId]
    }

    private var actionSubscription: AnyCancellable?

    func bind(actions: AnyPublisher<StepsFlowAction, Never>) {
        actionSubscription = actions
            .sink { [weak self] action in
                self?.handle(action: action)
            }
    }
}

private extension StepsFlowContentViewController {
    func handle(action: StepsFlowAction) {
        let step = action.node.element
        let stepId = step.id

        let stepVC: UIViewController
        if let cachedVC = cache[stepId] {
            stepVC = cachedVC
        } else {
            stepVC = makeVC(step: step)
            cache(id: stepId, viewController: stepVC)
        }

        transition(from: currentStepVC, to: stepVC)

        if case .pop = action, let currentStepId {
            removeCache(id: currentStepId)
        }

        currentStepId = stepId
    }

    func makeVC(step: Step) -> UIViewController {
        let rootView = StepView(step: step)
        return UIHostingController(rootView: rootView)
    }

    func transition(from oldVC: UIViewController?, to newVC: UIViewController) {
        oldVC?.willMove(toParent: nil)
        addChild(newVC)

        view.addSubview(newVC.view)

        newVC.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            newVC.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            newVC.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            newVC.view.topAnchor.constraint(equalTo: view.topAnchor),
            newVC.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        newVC.view.alpha = 0

        if let oldVC {
            transition(
                from: oldVC,
                to: newVC,
                duration: 0.25,
                options: [.curveEaseInOut],
                animations: {
                    oldVC.view.alpha = 0
                    newVC.view.alpha = 1
                },
                completion: { _ in
                    oldVC.view.alpha = 1
                    oldVC.view.removeFromSuperview()
                    oldVC.removeFromParent()
                    newVC.didMove(toParent: self)
                }
            )
        } else {
            view.addSubview(newVC.view)
            newVC.view.alpha = 1
            newVC.didMove(toParent: self)
        }
    }

    func cache(id: StepId, viewController: UIViewController) {
        cache[id] = viewController
    }

    func removeCache(id: StepId) {
        cache.removeValue(forKey: id)
    }
}

private struct StepView: View {
    typealias Step = any StepsFlowStep

    private let step: Step

    init(step: Step) {
        self.step = step
    }

    var body: some View {
        ZStack {
            AnyView(step.makeView())
                .frame(maxHeight: .infinity, alignment: .top)

            // Workaround: forces the navigation bar to reset.
            Color.clear
                .stepsFlowNavBar(title: nil)
                .stepsFlowNavBar()
        }
    }
}
