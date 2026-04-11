import XCTest
@testable import ShowTime

@MainActor
final class ShowTimeTests: XCTestCase {

    override func setUp() {
        super.setUp()
        ShowTime.touches.removeAll()
        ShowTime.enabled = .always
        ShowTime.fillColor = nil
        ShowTime.strokeColor = UIColor(red: 0.21, green: 0.61, blue: 0.92, alpha: 1)
        ShowTime.strokeWidth = 3
        ShowTime.size = 44
        ShowTime.disappearAnimation = .standard
        ShowTime.disappearDelay = 0.2
        ShowTime.shouldIgnoreApplePencilEvents = true
    }

    override func tearDown() {
        ShowTime.enabled = .never
        ShowTime.touches.removeAll()
        super.tearDown()
    }

    func test_enablingShowTime() {
        ShowTime.enabled = .never
        XCTAssertEqual(ShowTime.enabled, .never)
        XCTAssertFalse(ShowTime.shouldEnable)

        ShowTime.enabled = .debugOnly
        XCTAssertEqual(ShowTime.enabled, .debugOnly)
        XCTAssertTrue(ShowTime.shouldEnable)

        ShowTime.enabled = .never
        XCTAssertEqual(ShowTime.enabled, .never)
        XCTAssertFalse(ShowTime.shouldEnable)

        ShowTime.enabled = .always
        XCTAssertEqual(ShowTime.enabled, .always)
        XCTAssertTrue(ShowTime.shouldEnable)
    }

    func test_creatingTouchIndicator() {
        let touch = MockTouch()
        let window = UIWindow()
        let indicator = TouchIndicatorLayer(touch: touch, relativeTo: window)
        XCTAssertEqual(indicator.bounds.width, ShowTime.size)
        XCTAssertEqual(indicator.bounds.height, ShowTime.size)
        XCTAssertEqual(indicator.strokeColor, ShowTime.strokeColor.cgColor)
        XCTAssertEqual(indicator.lineWidth, ShowTime.strokeWidth)
        XCTAssertNotNil(indicator.path)
    }

    func test_touchIndicatorUsesChangedValues() {
        ShowTime.size = 100
        ShowTime.strokeColor = .orange
        ShowTime.strokeWidth = 10
        ShowTime.fillColor = .green

        let touch = MockTouch()
        let window = UIWindow()
        let indicator = TouchIndicatorLayer(touch: touch, relativeTo: window)
        XCTAssertEqual(indicator.bounds.width, 100)
        XCTAssertEqual(indicator.bounds.height, 100)
        XCTAssertEqual(indicator.strokeColor, UIColor.orange.cgColor)
        XCTAssertEqual(indicator.lineWidth, 10)
        XCTAssertEqual(indicator.fillColor, UIColor.green.cgColor)
    }

    func test_handlingEvents() {
        XCTAssertTrue(ShowTime.touches.isEmpty)
        let eventWithNoTouches = MockEvent()
        let window = UIWindow()
        window.sendEvent(eventWithNoTouches)
        XCTAssertTrue(ShowTime.touches.isEmpty)

        let touch1 = MockTouch()
        let eventWithOneTouch = MockEvent(touches: [touch1])
        window.sendEvent(eventWithOneTouch)
        XCTAssertEqual(ShowTime.touches.count, 1)
        XCTAssertNotNil(ShowTime.touches[touch1])

        let touch2 = MockTouch()
        let touch3 = MockTouch()
        let eventWithMultipleTouches = MockEvent(touches: [touch2, touch3])
        window.sendEvent(eventWithMultipleTouches)
        XCTAssertEqual(ShowTime.touches.count, 3)
        XCTAssertNotNil(ShowTime.touches[touch2])
        XCTAssertNotNil(ShowTime.touches[touch3])
    }

    func test_touchPhases() {
        XCTAssertTrue(ShowTime.touches.isEmpty)
        let touch = MockTouch(phase: .began)
        let event = MockEvent(touches: [touch])
        let window = UIWindow()
        window.sendEvent(event)
        XCTAssertEqual(ShowTime.touches.count, 1)

        touch._phase = .moved
        window.sendEvent(event)
        XCTAssertEqual(ShowTime.touches.count, 1)

        touch._phase = .ended
        window.sendEvent(event)
        XCTAssertEqual(ShowTime.touches.count, 0)

        let touch2 = MockTouch(phase: .began)
        let event2 = MockEvent(touches: [touch2])
        window.sendEvent(event2)
        XCTAssertEqual(ShowTime.touches.count, 1)

        touch2._phase = .stationary
        window.sendEvent(event2)
        XCTAssertEqual(ShowTime.touches.count, 1)

        touch2._phase = .cancelled
        window.sendEvent(event2)
        XCTAssertEqual(ShowTime.touches.count, 0)
    }

    func test_ignoringApplePencilEvents() {
        XCTAssertTrue(ShowTime.touches.isEmpty)
        XCTAssertTrue(ShowTime.shouldIgnoreApplePencilEvents)

        let window = UIWindow()
        let applePencilTouch = MockTouch(type: .stylus)
        let event = MockEvent(touches: [applePencilTouch])
        window.sendEvent(event)
        XCTAssertEqual(ShowTime.touches.count, 0)

        ShowTime.shouldIgnoreApplePencilEvents = false
        window.sendEvent(event)
        XCTAssertEqual(ShowTime.touches.count, 1)
    }

    func test_removingTouchIndicatorsAfterDisabling() {
        XCTAssertTrue(ShowTime.touches.isEmpty)
        ShowTime.enabled = .always

        let window = UIWindow()
        let startEvent = MockEvent(touches: [MockTouch(phase: .began)])
        window.sendEvent(startEvent)
        ShowTime.enabled = .never
        let endEvent = MockEvent(touches: [MockTouch(phase: .ended)])
        window.sendEvent(endEvent)

        XCTAssertTrue(ShowTime.touches.isEmpty)
    }

    func test_autoFillColor() {
        ShowTime.fillColor = nil
        ShowTime.strokeColor = .red
        let indicator = TouchIndicatorLayer(touch: UITouch(), relativeTo: UIWindow())
        XCTAssertEqual(indicator.fillColor, UIColor.red.withAlphaComponent(0.5).cgColor)
        XCTAssertEqual(indicator.strokeColor, UIColor.red.cgColor)
    }

    func test_explicitFillColor() {
        ShowTime.fillColor = .yellow
        ShowTime.strokeColor = .black
        let indicator = TouchIndicatorLayer(touch: UITouch(), relativeTo: UIWindow())
        XCTAssertEqual(indicator.fillColor, UIColor.yellow.cgColor)
        XCTAssertEqual(indicator.strokeColor, UIColor.black.cgColor)
    }
}

// MARK: - Mocks

private extension ShowTimeTests {

    final class MockEvent: UIEvent {

        let touches: [UITouch]

        init(touches: [UITouch] = []) {
            self.touches = touches
        }

        override var allTouches: Set<UITouch>? {
            Set(touches)
        }
    }
}

private final class MockTouch: UITouch {

    let taps: Int
    var _phase: UITouch.Phase
    let _type: UITouch.TouchType

    init(tapCount: Int = 1, phase: UITouch.Phase = .began, type: UITouch.TouchType = .direct) {
        self.taps = tapCount
        self._phase = phase
        self._type = type
    }

    override var tapCount: Int { taps }
    override var phase: UITouch.Phase { _phase }
    override var type: UITouch.TouchType { _type }
}
