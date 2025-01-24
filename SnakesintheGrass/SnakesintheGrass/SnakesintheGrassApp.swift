//
//  SnakesintheGrassApp.swift
//  SnakesintheGrass
//
//  Created by myle$ on 9/29/24.
//

import SwiftUI
import UIKit
import SpriteKit

@main
struct SnakesintheGrassApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate, UISceneDelegate {
    func sceneWillResignActive(_ scene: UIScene) {
        // Save game state when the app goes to the background.
        if let gameScene = findGameScene() {
            gameScene.saveGameState()
        }
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Load game state when the app returns to the foreground.
        if let gameScene = findGameScene() {
            gameScene.loadGameState()
        }
    }

    private func findGameScene() -> GameScene? {
        let rootView = UIApplication.shared.windows.first?.rootViewController?.view
        return (rootView as? SKView)?.scene as? GameScene
    }
}
