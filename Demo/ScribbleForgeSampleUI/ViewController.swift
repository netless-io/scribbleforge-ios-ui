//
//  ViewController.swift
//  ScribbleForgeSampleUI
//
//  Created by vince on 2026/1/30.
//

import UIKit
import ScribbleForge
import ScribbleForgeUI
import AgoraRtmKit

class ViewController: UIViewController {
    private let whiteboardContainer = WhiteboardContainerViewController()
    private var room: Room?
    private var rtmKit: AgoraRtmClientKit?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGray6
        addChild(whiteboardContainer)
        view.addSubview(whiteboardContainer.view)
        whiteboardContainer.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            whiteboardContainer.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            whiteboardContainer.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            whiteboardContainer.view.topAnchor.constraint(equalTo: view.topAnchor),
            whiteboardContainer.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        whiteboardContainer.didMove(toParent: self)

        startIfPossible()
    }

    // Call this once you have a joined room instance.
    private func startWhiteboard(with room: Room) {
        self.room = room
        whiteboardContainer.start(with: room, autoJoin: true)
    }

    private func startIfPossible() {
        guard let options = DemoConfig.buildJoinOptions() else {
            showMissingConfigAlert()
            return
        }
        let rtmAppId = DemoConfig.rtmAppId()
        let rtmToken = DemoConfig.rtmToken()
        guard !rtmAppId.isEmpty, !rtmToken.isEmpty else {
            showMissingConfigAlert()
            return
        }

        let rtmConfig = AgoraRtmClientConfig(appId: rtmAppId, userId: options.authOption.userId)
        rtmConfig.useStringUserId = true
        do {
            let rtmKit = try AgoraRtmClientKit(rtmConfig, delegate: nil)
            self.rtmKit = rtmKit
            rtmKit.login(rtmToken) { [weak self] _, errorInfo in
                DispatchQueue.main.async {
                    guard let self else { return }
                    if let errorInfo {
                        self.showRtmLoginAlert(errorInfo)
                        return
                    }
                    let room = Room(joinRoomOptions: options, agoraRtmKit: rtmKit)
                    self.startWhiteboard(with: room)
                }
            }
        } catch {
            showRtmInitAlert(error)
        }
    }

    private func showMissingConfigAlert() {
        let alert = UIAlertController(
            title: "Missing Config",
            message: "Please set ScribbleForgeRoomId / ScribbleForgeRoomToken / ScribbleForgeUserId / ScribbleForgeRtmAppId / ScribbleForgeRtmToken in RoomConfig.plist.",
            preferredStyle: .alert
        )
        alert.addAction(.init(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func showRtmLoginAlert(_ errorInfo: AgoraRtmErrorInfo) {
        let alert = UIAlertController(
            title: "RTM Login Failed",
            message: errorInfo.reason,
            preferredStyle: .alert
        )
        alert.addAction(.init(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func showRtmInitAlert(_ error: Error) {
        let alert = UIAlertController(
            title: "RTM Init Failed",
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        alert.addAction(.init(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
