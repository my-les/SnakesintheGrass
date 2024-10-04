import SpriteKit
import UIKit

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
    private var isGameOver: Bool = false

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

        // Adding swipe gesture recognizers
        let swipeUp = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        swipeUp.direction = .up
        view.addGestureRecognizer(swipeUp)

        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        swipeDown.direction = .down
        view.addGestureRecognizer(swipeDown)

        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        swipeLeft.direction = .left
        view.addGestureRecognizer(swipeLeft)

        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        swipeRight.direction = .right
        view.addGestureRecognizer(swipeRight)
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

    private func setupGame() {
        snake.removeAll()
        food?.removeFromParent()
        score = 0
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
        let randomX = CGFloat(Int.random(in: 0..<gridWidth)) * gridSize
        let randomY = CGFloat(Int.random(in: 0..<gridHeight)) * gridSize
        food?.position = CGPoint(x: randomX, y: randomY)
        addChild(food!)
    }

    private func setupScoreLabel() {
        scoreLabel = SKLabelNode(fontNamed: "CourierNewPS-BoldMT")
        scoreLabel?.fontSize = 16
        scoreLabel?.fontColor = .black
        scoreLabel?.position = CGPoint(x: size.width / 2, y: size.height - 95)
        scoreLabel?.text = "Score: 0"
        addChild(scoreLabel!)
    }

    override func update(_ currentTime: TimeInterval) {
        if !isGameOver && currentTime > nextMoveTime {
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

        // Check if the snake eats the food
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
        // Check if snake collides with itself
        return snake.dropFirst().contains { $0 == head }
    }

    private func updateScore() {
        score += 10
        scoreLabel?.text = "Score: \(score)"
    }

    private func gameOver() {
        isGameOver = true
        showGameOverAlert()
    }

    private func showGameOverAlert() {
        let alertController = UIAlertController(title: "Caught Lacking!", message: "Your score: \(score)", preferredStyle: .alert)

        let playAgainAction = UIAlertAction(title: "Play Again Lil Twin", style: .default) { [weak self] _ in
            self?.restartGame()
        }
        
        let shareScoreAction = UIAlertAction(title: "Share Score", style: .default) { [weak self] _ in
            self?.shareScore()
        }
        
        let mainMenuAction = UIAlertAction(title: "Main Menu", style: .default) { [weak self] _ in
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
        removeAllChildren()
        setupGame()
    }

    private func shareScore() {
        let activityViewController = UIActivityViewController(
            activityItems: ["I scored \(score) points in Snakes in the Grass!"],
            applicationActivities: nil
        )
        
        if let viewController = self.view?.window?.rootViewController {
            viewController.present(activityViewController, animated: true, completion: nil)
        }
    }

    private func goToMainMenu() {
        // Placeholder for now, as we don't have a main menu yet
        print("Going to main menu")
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
        // Clear existing snake parts and re-render
        children.filter { $0 is SKSpriteNode && $0 != food }.forEach { $0.removeFromParent() }

        for (index, part) in snake.enumerated() {
            let texture = SKTexture(imageNamed: SnakePartType(rawValue: index % 3)?.imageName(for: moveDirection) ?? "head")
            let newPart = SKSpriteNode(texture: texture, size: CGSize(width: gridSize, height: gridSize))
            newPart.position = CGPoint(x: CGFloat(part.0) * gridSize, y: CGFloat(part.1) * gridSize)
            addChild(newPart)
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
    }
}
