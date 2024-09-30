//
//  GameScene.swift
//  SnakesintheGrass
//
//  Created by myle$ on 9/29/24.
//

import SpriteKit

class GameScene: SKScene {
    private var snake: [(Int, Int)] = []
    private var food: SKSpriteNode?
    private var moveDirection: CGVector = CGVector(dx: 1, dy: 0)
    private var nextMoveTime: TimeInterval = 0
    private let moveSpeed: TimeInterval = 0.2
    private var score: Int = 0
    private var scoreLabel: SKLabelNode?
    private let gridSize: CGFloat = 20
    private let gridWidth: Int
    private let gridHeight: Int

    override init(size: CGSize) {
        gridWidth = Int(size.width / gridSize)
        gridHeight = Int(size.height / gridSize)
        super.init(size: size)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMove(to view: SKView) {
        backgroundColor = .white
        setupGame()
    }

    private func setupGame() {
        snake.removeAll()
        food?.removeFromParent()
        score = 0
        moveDirection = CGVector(dx: 1, dy: 0)

        let startPosition = CGPoint(x: CGFloat(gridWidth / 2), y: CGFloat(gridHeight / 2))
        addSnakePart(at: startPosition)
        spawnFood()
        setupScoreLabel()
    }

    private func addSnakePart(at position: CGPoint) {
        let gridPosition = (Int(position.x / gridSize), Int(position.y / gridSize))
        snake.insert(gridPosition, at: 0)
    }

    private func spawnFood() {
        food?.removeFromParent()
        let texture = SKTexture(imageNamed: "apple")
        food = SKSpriteNode(texture: texture, size: CGSize(width: gridSize, height: gridSize))
        food?.position = CGPoint(x: CGFloat(Int.random(in: 0..<gridWidth)) * gridSize, y: CGFloat(Int.random(in: 0..<gridHeight)) * gridSize)
        addChild(food!)
    }

    private func setupScoreLabel() {
        scoreLabel = SKLabelNode(fontNamed: "Arial")
        scoreLabel?.fontSize = 24
        scoreLabel?.fontColor = .black
        scoreLabel?.position = CGPoint(x: size.width - 60, y: size.height - 40)
        scoreLabel?.text = "Score: 0"
        addChild(scoreLabel!)
    }

    override func update(_ currentTime: TimeInterval) {
        if currentTime > nextMoveTime {
            moveSnake()
            nextMoveTime = currentTime + moveSpeed
        }
    }

    private func moveSnake() {
        guard let head = snake.first else { return }
        let newHead = (
            (head.0 + Int(moveDirection.dx) + gridWidth) % gridWidth,
            (head.1 + Int(moveDirection.dy) + gridHeight) % gridHeight
        )

        let foodPosition = (Int(food?.position.x ?? 0) / Int(gridSize), Int(food?.position.y ?? 0) / Int(gridSize))
        if newHead == foodPosition {
            snake.insert(newHead, at: 0)
            spawnFood()
            updateScore()
        } else {
            snake.insert(newHead, at: 0)
            snake.removeLast()
        }

        if checkForCollisions() {
            gameOver()
        }

        updateSnakeDisplay()
    }

    private func checkForCollisions() -> Bool {
        guard let head = snake.first else { return false }
        return snake.dropFirst().contains { $0 == head }
    }

    private func updateScore() {
        score += 10
        scoreLabel?.text = "Score: \(score)"
    }

    private func gameOver() {
        let gameOverLabel = SKLabelNode(fontNamed: "Arial")
        gameOverLabel.fontSize = 48
        gameOverLabel.fontColor = .black
        gameOverLabel.position = CGPoint(x: size.width / 2, y: size.height / 2)
        gameOverLabel.text = "Game Over"
        addChild(gameOverLabel)

        let finalScoreLabel = SKLabelNode(fontNamed: "Arial")
        finalScoreLabel.fontSize = 24
        finalScoreLabel.fontColor = .black
        finalScoreLabel.position = CGPoint(x: size.width / 2, y: size.height / 2 - 40)
        finalScoreLabel.text = "Final Score: \(score)"
        addChild(finalScoreLabel)

        let restartLabel = SKLabelNode(fontNamed: "Arial")
        restartLabel.fontSize = 24
        restartLabel.fontColor = .black
        restartLabel.position = CGPoint(x: size.width / 2, y: size.height / 2 - 80)
        restartLabel.text = "Tap to Restart"
        addChild(restartLabel)

        isUserInteractionEnabled = true
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if snake.count == 1 {
            // Restart the game
            removeAllChildren()
            setupGame()
        } else {
            // Change direction
            guard let touch = touches.first else { return }
            let touchLocation = touch.location(in: self)
            updateMoveDirection(for: touchLocation)
        }
    }

    private func updateMoveDirection(for touchLocation: CGPoint) {
        guard let head = snake.first else { return }
        let headPosition = CGPoint(x: CGFloat(head.0) * gridSize, y: CGFloat(head.1) * gridSize)
        let dx = touchLocation.x - headPosition.x
        let dy = touchLocation.y - headPosition.y

        let newDirection: CGVector
        if abs(dx) > abs(dy) {
            newDirection = dx > 0 ? CGVector(dx: 1, dy: 0) : CGVector(dx: -1, dy: 0)
        } else {
            newDirection = dy > 0 ? CGVector(dx: 0, dy: 1) : CGVector(dx: 0, dy: -1)
        }

        // Prevent 180-degree turns
        if newDirection.dx != -moveDirection.dx || newDirection.dy != -moveDirection.dy {
            moveDirection = newDirection
        }
    }

    private func updateSnakeDisplay() {
        removeAllChildren()
        addChild(scoreLabel!)

        for (index, part) in snake.enumerated() {
            let partType: SnakePartType = index == 0 ? .head : (index == snake.count - 1 ? .tail : .body)
            let texture = SKTexture(imageNamed: partType.imageName(for: moveDirection))
            let newPart = SKSpriteNode(texture: texture, size: CGSize(width: gridSize, height: gridSize))
            newPart.position = CGPoint(x: CGFloat(part.0) * gridSize, y: CGFloat(part.1) * gridSize)
            addChild(newPart)
        }

        if let food = food {
            addChild(food)
        }
    }
}

enum SnakePartType: Int {
    case head = 0
    case body = 1
    case tail = 2

    func imageName(for direction: CGVector) -> String {
        switch self {
        case .head:
            if direction.dx > 0 { return "head_right" }
            if direction.dx < 0 { return "head_left" }
            if direction.dy > 0 { return "head_up" }
            return "head_down"
        case .body:
            return "body_horizontal"
        case .tail:
            if direction.dx > 0 { return "tail_left" }
            if direction.dx < 0 { return "tail_right" }
            if direction.dy > 0 { return "tail_down" }
            return "tail_up"
        }
    }
}
