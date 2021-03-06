import XCTest
@testable import SwiftyVK

final class QueryBuilderTests: XCTestCase {
    
    var builder: QueryBuilderImpl {
        return QueryBuilderImpl()
    }
    
    private func parameters(from parameters: String) -> [String: String] {
        var result = [String: String]()
        
        parameters.components(separatedBy: "&").forEach {
            let components = $0.components(separatedBy: "=")
            result[components.first!] = components.last!
        }
        
        return result
    }
    
    func test_apiVersion() {
        // When
        let sample = parameters(from: builder.makeQuery(parameters: .empty))

        // Then
        XCTAssertEqual(sample["v"], nil)
    }

    func test_language() {
        // When
        let sample = parameters(from: builder.makeQuery(parameters: .empty))
        
        // Then
        XCTAssertEqual(sample["lang"], SessionConfig.default.language.rawValue)
    }

    func test_httpsFlag() {
        // When
        let sample = parameters(from: builder.makeQuery(parameters: .empty))
        
        // Then
        XCTAssertEqual(sample["https"], "1")
    }

    func test_apiGetRequestParameters() {
        // When
        let sample = parameters(from: builder.makeQuery(parameters: [.userId: "test"]))
        
        // Then
        XCTAssertEqual(sample[Parameter.userId.rawValue], "test")
    }
    
    func test_ignoreNullParameter() {
        // When
        let sample = parameters(from: builder.makeQuery(parameters: [.userId: nil]))
        
        // Then
        XCTAssertFalse(sample.keys.contains(Parameter.userId.rawValue))
    }
    
    func test_addCaptchaParameters() {
        // When
        let sample = parameters(from: builder.makeQuery(parameters: [.userId: nil], captcha: (sid: "sid", key: "key")))
        
        // Then
        XCTAssertEqual(sample["captcha_sid"], "sid")
        XCTAssertEqual(sample["captcha_key"], "key")
    }
    
    func test_percentEncoding() {
        // Given
        let rawMessage = " !#$&'()*+,./:;=?@[]"
        
        // When
        let encodedQuery = builder.makeQuery(parameters: [.message: rawMessage])
        let encodedMesage = encodedQuery.components(separatedBy: "&")[2].components(separatedBy: "=")[1]
        
        // Then
        XCTAssertEqual(rawMessage, encodedMesage.removingPercentEncoding)
    }
}
