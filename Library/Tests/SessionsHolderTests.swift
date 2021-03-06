import XCTest
@testable import SwiftyVK

final class SessionsHolderTests: XCTestCase {
    
    func makeHolder() -> SessionsHolderImpl {
        return SessionsHolderImpl(
            sessionMaker: SessionMakerMock(),
            sessionsStorage: SessionsStorageMock()
        )
    }
    
    func test_makeNewSession() {
        XCTAssertTrue(makeHolder().make(config: .default) is SessionMock)
    }
    
    func test_markAsDefault() {
        // Given
        let holder = makeHolder()
        let oldSession = holder.default
        let newSession = holder.make()
        // When
        try? holder.markAsDefault(session: newSession)
        // Then
        XCTAssertFalse(holder.default === oldSession)
        XCTAssertTrue(holder.default === newSession)
    }
    
    func test_destroySession() {
        // Given
        let holder = makeHolder()
        let newSession = holder.make()
        // When
        try? holder.destroy(session: newSession)
        // Then
        XCTAssertEqual(newSession.state, .destroyed)
    }
    
    func test_destroyDeadSession_shouldBeFail() {
        // Given
        let holder = makeHolder()
        let session = holder.make()
        // When
        do {
            try holder.destroy(session: session)
            try holder.destroy(session: session)
            XCTFail("Unexpected behavior")
        } catch let error {
            // Then
            XCTAssertEqual(error.asVK, VKError.sessionAlreadyDestroyed(session))
        }
    }
    
    func test_getAllSessions() {
        // Given
        let holder = makeHolder()
        // When
        let sessions = [holder.make(), holder.make(), holder.make(), holder.make(), holder.default]
        // Then
        XCTAssertEqual(holder.all.count, sessions.count)
    }
    
    func test_changeSefault() {
        // Given
        let holder = makeHolder()
        let oldDefaultId = holder.default.id
        holder.default.config = SessionConfig(apiVersion: "TEST")
        // When
        try? holder.destroy(session: holder.default)
        let newDefaultId = holder.default.id
        let newConfig = holder.default.config
        // Then
        XCTAssertNotEqual(oldDefaultId, newDefaultId)
        XCTAssertEqual(newConfig.apiVersion, "TEST")
    }
}
