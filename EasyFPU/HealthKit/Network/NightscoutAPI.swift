import Combine
import CommonCrypto
import Foundation
import HealthKit

class NightscoutAPI {
    init(url: URL, secret: String? = nil) {
        self.url = url
        self.secret = secret
    }

    private enum Config {
        static let entriesPath = "/api/v1/entries/sgv.json"
        static let uploadEntriesPath = "/api/v1/entries.json"
        static let treatmentsPath = "/api/v1/treatments.json"
        static let statusPath = "/api/v1/devicestatus.json"
        static let retryCount = 1
        static let timeout: TimeInterval = 60
    }

    enum Error: LocalizedError {
        case badStatusCode
        case missingURL
    }

    let url: URL
    let secret: String?

    private let service = NetworkService()
}

extension NightscoutAPI {
    func checkConnection() -> AnyPublisher<Void, Swift.Error> {
        struct Check: Codable, Equatable {
            var eventType = "Note"
            var enteredBy = "freeaps-x"
            var notes = "FreeAPS X connected"
        }
        let check = Check()
        var request = URLRequest(url: url.appendingPathComponent(Config.treatmentsPath))

        if let secret = secret {
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpMethod = "POST"
            request.addValue(secret.sha1(), forHTTPHeaderField: "api-secret")
            request.httpBody = try! JSONCoding.encoder.encode(check)
        } else {
            request.httpMethod = "GET"
        }

        return service.run(request)
            .map { _ in () }
            .eraseToAnyPublisher()
    }

    
    
    


    func uploadTreatments(_ treatments: [CarbsEntryNS]) -> AnyPublisher<Void, Swift.Error> {
        
        
        //convert HKQuantitySample
        
        
        
        var components = URLComponents()
        components.scheme = url.scheme
        components.host = url.host
        components.port = url.port
        components.path = Config.treatmentsPath

        var request = URLRequest(url: components.url!)
        request.allowsConstrainedNetworkAccess = false
        request.timeoutInterval = Config.timeout
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        if let secret = secret {
            request.addValue(secret.sha1(), forHTTPHeaderField: "api-secret")
        }
        request.httpBody = try! JSONCoding.encoder.encode(treatments)
        request.httpMethod = "POST"

        return service.run(request)
            .retry(Config.retryCount)
            .map { _ in () }
            .eraseToAnyPublisher()
    }

    
}

private extension String {
    func sha1() -> String {
        let data = Data(utf8)
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA1_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_SHA1($0.baseAddress, CC_LONG(data.count), &digest)
        }
        let hexBytes = digest.map { String(format: "%02hhx", $0) }
        return hexBytes.joined()
    }
}
