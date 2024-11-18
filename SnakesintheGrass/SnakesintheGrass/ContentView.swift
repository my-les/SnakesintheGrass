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
        let scene = MainMenu()
        scene.scaleMode = .resizeFill
        return scene
    }

    var body: some View {
        SpriteView(scene: scene)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea()
    }
}



