import SpriteKit
import UIKit
import GameKit

class GameScene: SKScene {
    ///MARK: create skins eventually + add timer !!!!!!!!!

    private var snake: [(Int, Int)] = []
    private var food: SKSpriteNode?
    private var moveDirection: CGVector = CGVector(dx: 1, dy: 0)
    private var nextMoveTime: TimeInterval = 0
    private var moveSpeed: TimeInterval = 0.1
    private var score: Int = 0
    private var scoreLabel: SKLabelNode?

    private var level: Int = 1
    private var baseSpeed: TimeInterval = 0.1
    private let speedIncreaseFactor: Double = 0.85
    private var levelLabel: SKLabelNode?

    private let impactFeedbackGenerator = UIImpactFeedbackGenerator(style: .rigid)
    private let notificationFeedbackGenerator = UINotificationFeedbackGenerator()

    private var pauseButton: SKSpriteNode?

    private var gameTimer: Timer?

    private var startTime: TimeInterval = 0
    private var elapsedTime: TimeInterval = 0

    private var clockLabel: SKLabelNode!

    private let gridSize: CGFloat = 22
    private let gridWidth: Int
    private let gridHeight: Int
    private var isGameOver: Bool = false
    private var isPausedGame: Bool = false

    override init(size: CGSize) {
        gridWidth = Int(size.width / gridSize)
        gridHeight = Int(size.height / gridSize)
        super.init(size: size)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMove(to view: SKView) {
        backgroundColor = .black
        setupClockLabel()
        setupGame()
        impactFeedbackGenerator.prepare()
        notificationFeedbackGenerator.prepare()

        // Add swipe gestures
        addSwipeGesture(to: view, direction: .up)
        addSwipeGesture(to: view, direction: .down)
        addSwipeGesture(to: view, direction: .left)
        addSwipeGesture(to: view, direction: .right)

        setupPauseButton()
    }

    private func addSwipeGesture(to view: SKView, direction: UISwipeGestureRecognizer.Direction) {
        let swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        swipeGesture.direction = direction
        view.addGestureRecognizer(swipeGesture)
    }

    @objc private func handleSwipe(_ gesture: UISwipeGestureRecognizer) {
        switch gesture.direction {
        case .up:
            if moveDirection.dy == 0 { moveDirection = CGVector(dx: 0, dy: 1) }
        case .down:
            if moveDirection.dy == 0 { moveDirection = CGVector(dx: 0, dy: -1) }
        case .left:
            if moveDirection.dx == 0 { moveDirection = CGVector(dx: -1, dy: 0) }
        case .right:
            if moveDirection.dx == 0 { moveDirection = CGVector(dx: 1, dy: 0) }
        default:
            break
        }
    }

    private func togglePause() {
        isPausedGame.toggle()
        pauseButton?.color = isPausedGame ? .red : .gray
    }

    private func setupGame() {
        snake.removeAll()
        food?.removeFromParent()
        score = 0
        level = 1
        moveSpeed = baseSpeed
        clockLabel.text = "00:00.000"


        moveDirection = CGVector(dx: 1, dy: 0)
        isGameOver = false

        // Initial snake position
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

        let safeMargin: CGFloat = gridSize * 2 // Safe area from edges and UI elements

        let minX = safeMargin
        let maxX = size.width - safeMargin
        let minY = safeMargin
        let maxY = size.height - safeMargin

        let randomX = CGFloat(Int.random(in: Int(minX / gridSize)...Int(maxX / gridSize))) * gridSize
        let randomY = CGFloat(Int.random(in: Int(minY / gridSize)...Int(maxY / gridSize))) * gridSize

        food?.position = CGPoint(x: randomX, y: randomY)
        addChild(food!)
    }

    private func setupScoreLabel() {
        scoreLabel = SKLabelNode(fontNamed: "CourierNewPS-BoldMT")
        scoreLabel?.fontSize = 16
        scoreLabel?.fontColor = .white
        scoreLabel?.position = CGPoint(x: size.width / 2, y: size.height - 95)
        scoreLabel?.text = "Score: 0 | Level: 1"
        addChild(scoreLabel!)
    }

    private func setupClockLabel() {
        clockLabel = SKLabelNode(text: "00:00.000")
        clockLabel.position = CGPoint(x: size.width / 2, y: size.height - 75)
        clockLabel.fontName = "CourierNewPS-BoldMT"
        clockLabel.fontColor = .white
        clockLabel.fontSize = 19
        addChild(clockLabel)
    }

    private func format(timeInterval: TimeInterval) -> String {
        let interval = Int(timeInterval)
        let seconds = interval % 60
        let minutes = (interval / 60) % 60
        let milliseconds = Int(timeInterval * 1000) % 1000
        return String(format: "%02d:%02d.%03d", minutes, seconds, milliseconds)
    }

    private func setupPauseButton() {
        pauseButton = SKSpriteNode(imageNamed: "pause")
        pauseButton?.position = CGPoint(x: size.width - 50, y: size.height - 90)
        pauseButton?.name = "pauseButton"
        pauseButton?.size = CGSize(width: 40, height: 40)
        addChild(pauseButton!)
    }

    private func setupQuitButton() {
        let quitLabel = SKLabelNode(text: "QUIT?")
        quitLabel.fontName = "CourierNewPS-BoldMT"
        quitLabel.fontSize = 20
        quitLabel.fontColor = .red
        quitLabel.position = CGPoint(x: size.width / 2, y: size.height / 2.2)
        quitLabel.zPosition = 100
        quitLabel.name = "quitLabel"
        addChild(quitLabel)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let nodesAtPoint = nodes(at: location)

        if nodesAtPoint.contains(where: { $0.name == "pauseButton" }) {
            if isPaused {
                resumeGame()
            } else {
                pauseGame()
            }
        } else if nodesAtPoint.contains(where: { $0.name == "quitLabel" }) {
            showQuitConfirmation()
        }
    }

    private func pauseGame() {
        guard !isPaused else { return } // Avoid duplicate pauses

        isPaused = true
        self.isPaused = true
        stopClock()

        pauseButton?.texture = SKTexture(imageNamed: "play")

        if childNode(withName: "pausedLabel") == nil {
            let pausedLabel = SKLabelNode(text: "PAUSED")
            pausedLabel.fontName = "CourierNewPS-BoldMT"
            pausedLabel.fontSize = 40
            pausedLabel.position = CGPoint(x: size.width / 2, y: size.height / 2)
            pausedLabel.zPosition = 100
            pausedLabel.name = "pausedLabel"
            addChild(pausedLabel)
        }

        setupQuitButton()
    }

    private func showQuitConfirmation() {
        let alertController = UIAlertController(
            title: "Quit Game",
            message: "Are you sure you want to fold twin?",
            preferredStyle: .alert
        )

        let quitAction = UIAlertAction(title: "Quit", style: .destructive) { [weak self] _ in
            self?.quitGame()
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)

        alertController.addAction(quitAction)
        alertController.addAction(cancelAction)

        if let viewController = self.view?.window?.rootViewController {
            viewController.present(alertController, animated: true, completion: nil)
        }
    }

    private func quitGame() {
        cleanupScene()
        guard let view = self.view else {return}

        let transition = SKTransition.fade(withDuration: 0.5)
        let mainMenuScene = MainMenu(size: view.bounds.size)
        mainMenuScene.scaleMode = .resizeFill

        view.presentScene(mainMenuScene, transition: transition)
    }

    private func resumeGame() {
        pauseButton?.texture = SKTexture(imageNamed: "pause")
        isPaused = false
        self.isPaused = false

        if let pausedLabel = childNode(withName: "pausedLabel") {
            pausedLabel.removeFromParent()
        }

        if let quitLabel = childNode(withName: "quitLabel") {
            quitLabel.removeFromParent()
        }
    }

    override func update(_ currentTime: TimeInterval) {
        if !isGameOver && !isPaused && currentTime > nextMoveTime {
            moveSnake()
            nextMoveTime = currentTime + moveSpeed


            if startTime == 0 {
                startTime = currentTime
            }
            elapsedTime = currentTime - startTime
            clockLabel.text = format(timeInterval: elapsedTime)

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
            impactFeedbackGenerator.impactOccurred()
            snake.insert(newHead, at: 0)
            spawnFood()
            updateScore()
        } else {
            snake.insert(newHead, at: 0)
            snake.removeLast()
        }

        if checkForCollisions() {
            notificationFeedbackGenerator.notificationOccurred(.error)
            gameOver()
        }

        updateSnakeDisplay()
    }

    private func checkForCollisions() -> Bool {
        guard let head = snake.first else { return false }
        // Check if snake collides with itself
        return snake.dropFirst().contains { $0 == head }
    }

    private func updateScore() {
        score += 10
        scoreLabel?.text = "Score: \(score) | Level: \(level)"

        // Calculate new level
        let newLevel = (score / 50) + 1
        if newLevel != level {
            level = newLevel
            updateSpeedForLevel()
        }
    }

    private func updateSpeedForLevel() {
        // Every third level, increase speed
        if level % 3 == 0 {
            // Calculate how many speed increases have occurred
            let speedIncreases = level / 3
            // Apply the speed increase factor for each increment
            let newSpeed = baseSpeed * pow(speedIncreaseFactor, Double(speedIncreases))
            // Ensure speed doesn't get too fast (optional)
            moveSpeed = max(newSpeed, 0.05)
        }
    }

    private func gameOver() {
        isGameOver = true
        stopClock()
        showGameOverAlert()
        GameCenterManager().submitScore(score)
    }

    private func stopClock() {
        gameTimer?.invalidate()
        gameTimer = nil
    }

    private func showGameOverAlert() {
        //let finalTime = format(timeInterval: elapsedTime)
        let alertController = UIAlertController(title: "never backdoor yourself twin!", message: "you scored \(score) & reached level \(level).", preferredStyle: .alert)

        let playAgainAction = UIAlertAction(title: "play again", style: .default) { [weak self] _ in
            self?.restartGame()
        }

        let shareScoreAction = UIAlertAction(title: "share score", style: .default) { [weak self] _ in
            self?.shareScore()
        }

        let mainMenuAction = UIAlertAction(title: "main menu", style: .default) { [weak self] _ in
            self?.goToMainMenu()
        }

        alertController.addAction(playAgainAction)
        alertController.addAction(shareScoreAction)
        alertController.addAction(mainMenuAction)

        if let viewController = self.view?.window?.rootViewController {
            viewController.present(alertController, animated: true, completion: nil)
        }
    }

    private func restartGame() {
        cleanupScene()
        setupGame()
    }

    private func cleanupScene() {
        // Stop timers
        stopClock()

        // Remove all children
        removeAllChildren()
        removeAllActions()

        // Clear gesture recognizers (if added directly to the view)
        self.view?.gestureRecognizers?.forEach { self.view?.removeGestureRecognizer($0) }

        // Reset other properties
        gameTimer = nil
        clockLabel = nil
        pauseButton = nil
        food = nil
        scoreLabel = nil
        isGameOver = false
        isPausedGame = false
    }

    private func shareScore() {
        let activityViewController = UIActivityViewController(
            activityItems: ["I scored \(score) points in slyme! play now: https://apps.apple.com/us/app/slyme/id6739715471"],
            applicationActivities: nil
        )

        if let viewController = self.view?.window?.rootViewController {
            viewController.present(activityViewController, animated: true, completion: nil)
        }
    }

    private func goToMainMenu() {
        // Placeholder for now, as we don't have a main menu yet
        guard let view = self.view else { return }

        let transition = SKTransition.fade(withDuration: 0.5)
        let mainMenuScene = MainMenu(size: view.bounds.size)
        mainMenuScene.scaleMode = .resizeFill

        view.presentScene(mainMenuScene, transition: transition)

    }

    private func moveTowardsFood() {
        guard let head = snake.first, let food = food else { return }
        let foodPosition = (Int(food.position.x / gridSize), Int(food.position.y / gridSize))
        let dx = foodPosition.0 - head.0
        let dy = foodPosition.1 - head.1

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
        // Remove existing snake nodes
        children.filter { $0.name == "snakeSegment" }.forEach { $0.removeFromParent() }

        // Create new snake nodes with proper textures
        for (index, currentPosition) in snake.enumerated() {
            let previousPosition = index > 0 ? snake[index - 1] : nil
            let nextPosition = index < snake.count - 1 ? snake[index + 1] : nil

            let partType: SnakePartType
            if index == 0 {
                partType = .head
            } else if index == snake.count - 1 {
                partType = .tail
            } else {
                partType = .body
            }

            let textureName = partType.getTextureName(
                previousPosition: previousPosition,
                currentPosition: currentPosition,
                nextPosition: nextPosition
            )

            //print("typeshit \(textureName)")

            let texture = SKTexture(imageNamed: textureName)
            let node = SKSpriteNode(texture: texture, size: CGSize(width: gridSize, height: gridSize))
            node.position = CGPoint(x: CGFloat(currentPosition.0) * gridSize,
                                    y: CGFloat(currentPosition.1) * gridSize)
            node.name = "snakeSegment"
            //node.color = .black
            //print("this is the node: \(node)")
            addChild(node)
        }
    }


    private enum SnakePartType {
        case head
        case body
        case tail

        func getTextureName(previousPosition: (Int, Int)?,
                            currentPosition: (Int, Int),
                            nextPosition: (Int, Int)?) -> String {
            switch self {
            case .head:
                guard let next = nextPosition else {
                    print("heads")
                    return "head_up"
                }
                let dx = currentPosition.0 - next.0
                let dy = currentPosition.1 - next.1
                //print("this is dy: \(dy) and this is dx: \(dx)")
                if dx > 0 { return "head_right" }
                if dx < 0 { return "head_left" }
                if dy > 0 { return "head_up" }
                //print("gimmie head")
                return "head_down"

            case .tail:
                guard let prev = previousPosition else { return "tail_left" }
                let dx = prev.0 - currentPosition.0
                let dy = prev.1 - currentPosition.1
                if dx > 0 { return "tail_left" }
                if dx < 0 { return "tail_right" }
                if dy > 0 { return "tail_down" }
                //print("tookthatthangupshootymake it roll")
                return "tail_up"

            case .body:
                guard let prev = previousPosition, let next = nextPosition else {
                    print("1")
                    return "body_horizontal"
                }

                let isVertical = prev.0 == next.0
                let isHorizontal = prev.1 == next.1

                if isVertical { return "body_vertical" }
                if isHorizontal { return "body_horizontal" }

                // Handle corners
                let dx1 = currentPosition.0 - prev.0
                let dy1 = currentPosition.1 - prev.1
                let dx2 = next.0 - currentPosition.0
                let dy2 = next.1 - currentPosition.1

                switch (dx1, dy1, dx2, dy2) {
                case (1, 0, 0, 1), (0, -1, -1, 0):

                    print("this")
                    return "body_topleft"
                case (-1, 0, 0, 1), (0, -1, 1, 0):
                    print("that")
                    return "body_topright"
                case (1, 0, 0, -1), (0, 1, -1, 0):
                    print("typeshit")
                    return "body_bottomleft"
                case (-1, 0, 0, -1), (0, 1, 1, 0):
                    print("umm")
                    return "body_bottomright"
                default:
                    print("we got here")
                    return "body_vertical"
                }
            }
        }
    }
}
