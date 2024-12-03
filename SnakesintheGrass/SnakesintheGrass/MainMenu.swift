//
//  MainMenu.swift
//  SnakesintheGrass
//
//  Created by myle$ on 11/18/24.
//

import Foundation
import SpriteKit

class MainMenu: SKScene {

    override func didMove(to view: SKView) {
        backgroundColor = .white

        // Create the title label
        let titleLabel = SKLabelNode(text: "slyme")
        titleLabel.fontName = "CourierNewPS-BoldMT"
        titleLabel.fontSize = 30
        titleLabel.fontColor = .black
        titleLabel.position = CGPoint(x: size.width / 2, y: size.height / 2 + 100)
        addChild(titleLabel)

        // Create the subtitle
        let subtitleLabel = SKLabelNode(text: "eat or be ate, snake or be snaked.")
        subtitleLabel.fontName = "CourierNewPS-BoldMT"
        subtitleLabel.fontSize = 14
        subtitleLabel.fontColor = .systemPink
        subtitleLabel.position = CGPoint(x: size.width / 2, y: size.height / 2 + 80)
        addChild(subtitleLabel)

        // Create the Play button
        let playButton = createButton(withText: "play", name: "playButton", position: CGPoint(x: size.width / 2, y: size.height / 2))
        addChild(playButton)

        // Create the About button
        let aboutButton = createButton(withText: "instructions", name: "aboutButton", position: CGPoint(x: size.width / 2, y: size.height / 2 - 60))
        addChild(aboutButton)

        // Create the High Scores button
        let highScoresButton = createButton(withText: "high scores", name: "highScoresButton", position: CGPoint(x: size.width / 2, y: size.height / 2 - 120))
        addChild(highScoresButton)

        // Initialize GameCenter
        GameCenterManager.shared.authenticatePlayer()
    }

    private func createButton(withText text: String, name: String, position: CGPoint) -> SKLabelNode {
        let button = SKLabelNode(text: text)
        button.fontName = "CourierNewPS-BoldMT"
        button.fontSize = 20
        button.fontColor = .darkGray
        button.position = position
        button.name = name
        return button
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let nodes = nodes(at: location)

        for node in nodes {
            if node.name == "playButton" {
                let gameScene = GameScene(size: self.size)
                gameScene.scaleMode = .resizeFill
                view?.presentScene(gameScene, transition: .flipHorizontal(withDuration: 0.5))
            } else if node.name == "aboutButton" {
                showAlert(withTitle: "how to play", message:
                """

                1. swipe to control the direction

                2. crush the apple

                3. don't snake yourself twin

                4. try to get the highest score

                """
                )
            } else if node.name == "highScoresButton" {
                GameCenterManager.shared.showLeaderboard()
            }
        }
    }

    private func showAlert(withTitle title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))

        if let viewController = view?.window?.rootViewController {
            viewController.present(alert, animated: true, completion: nil)
        }
    }
}
