import XCTest
@testable import SwiftyVK

final class AttemptShedulerTests: XCTestCase {
    
    func test_exeuteAllConcurrentOperations_forCertainTime() {
        // Given
        let group = DispatchGroup()
        for _ in 0..<operationCount { group.enter() }
        // When
        let samples = sheduleSamples(count: operationCount, concurrent: true, completion: { group.leave() })
        _ = group.wait(timeout: .now() + totalAsyncTime)
        // Then
        XCTAssertEqual(samples.map {$0.isFinished}, (0..<operationCount).map { _ in true },
            "All concurrent operations should be executed"
        )
    }
    
    func test_executeMinimumSerialOpearations_forOneSecond() {
        // When
        let samples = sheduleSamples(count: operationCount, concurrent: false)
        Thread.sleep(forTimeInterval: 0.9)
        // Then
        XCTAssertLessThanOrEqual(samples.filter { $0.isFinished }.count, shedulerLimit.count,
            "Operations should be executed serially"
        )
    }
    
    func test_executeAllSerialOpearations_forCertainTime() {
        // Given
        let group = DispatchGroup()
        for _ in 0..<operationCount { group.enter() }
        // When
        let samples = sheduleSamples(count: operationCount, concurrent: false, completion: { group.leave() })
        _ = group.wait(timeout: .now() + totalSyncTime * 10)
        // Then
        XCTAssertEqual(samples.filter { $0.isFinished }.count, operationCount,
            "All operations should be executed"
        )
    }
    
    func test_exeuteRandomOperations() {
        // Given
        let group = DispatchGroup()
        for _ in 0..<operationCount { group.enter() }
        // When
        let serial = sheduleSamples(count: operationCount, concurrent: false, completion: { group.leave() })
        let concurrent = sheduleSamples(count: operationCount, concurrent: true)
        Thread.sleep(forTimeInterval: 0.9)
        // Then
        XCTAssertLessThanOrEqual(serial.filter { $0.isFinished }.count, shedulerLimit.count,
            "Operations should be executed serially"
        )
        
        XCTAssertEqual(concurrent.map {$0.isFinished}, (0..<operationCount).map { _ in true },
            "All concurrent operations should be executed"
        )
        
        _ = group.wait(timeout: .now() + totalSyncTime * 10)

        XCTAssertEqual(serial.filter { $0.isFinished }.count, operationCount,
            "All serial operations should be executed"
        )
        
        sheduler?.setLimit(to: 0)
    }
    
    func test_executeOpration_whenShedulerLimitUpdated() {
        // Given
        let sheduler = AttemptShedulerImpl(limit: .unlimited)
        let samples = (0..<operationCount).map { _ in AttemptMock() }
        
        // When
        sheduler.setLimit(to: .limited(1))
        samples.forEach { sheduler.shedule(attempt: $0, concurrent: false) }
        
        // Then
        Thread.sleep(forTimeInterval: 0.9)
        
        XCTAssertEqual(samples.filter { $0.isFinished } .count, 1,
            "Only one operation should be executed"
        )
    }
    
    override func setUp() {
        sheduler = AttemptShedulerImpl(limit: shedulerLimit)
    }
    
    override func tearDown() {
        sheduler = nil
    }
}

private var sheduler: AttemptShedulerImpl?

private let shedulerLimit: AttemptLimit = 30
private let operationCount = 100

private var totalAsyncTime: TimeInterval {
    return AttemptMock().runTime * Double(operationCount)
}

private var totalSyncTime: TimeInterval {
    return TimeInterval(operationCount / shedulerLimit.count)
}

private func sheduleSamples(count: Int, concurrent: Bool, completion: (() -> ())? = nil) -> [AttemptMock] {
    let samples = (0..<count).map { _ in AttemptMock(completion: completion) }
    samples.forEach { sheduler?.shedule(attempt: $0, concurrent: concurrent) }
    return samples
}
