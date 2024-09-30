//
//  ContentView.swift
//  SnakesintheGrass
//
//  Created by myle$ on 9/29/24.
//
import SwiftUI
import SpriteKit

struct ContentView: View {

    var scene: SKScene {
        let scene = GameScene(size: CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height))
        scene.scaleMode = .resizeFill
        return scene
    }

    var body: some View {
        SpriteView(scene: scene)
            .ignoresSafeArea() // Makes sure the game takes the entire screen
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

