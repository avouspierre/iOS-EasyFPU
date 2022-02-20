import Combine
import Foundation
import UIKit
import HealthKit



final class BaseNightscoutManager {
//    @Injected() private var keychain: Keychain!
//    @Injected() private var broadcaster: Broadcaster!
    private var reachabilityManager: ReachabilityManager!

    private let processQueue = DispatchQueue(label: "BaseNetworkManager.processQueue")
    private var ping: TimeInterval?

    private var lifetime = Set<AnyCancellable>()

    private var isNetworkReachable: Bool {
        reachabilityManager.isReachable
    }

    private var nightscoutAPI: NightscoutAPI? {
        guard let urlString =  UserSettings.shared.nightscoutURL,
              let url = URL(string: urlString),
              let secret = UserSettings.shared.nightscoutSecret
        else {
            return nil
        }
        return NightscoutAPI(url: url, secret: secret)
    }


//    private func subscribe() {
//        _ = reachabilityManager.startListening(onQueue: processQueue) { status in
//            debug(.nightscout, "Network status: \(status)")
//        }
//    }

//    func sourceInfo() -> [String: Any]? {
//        if let ping = ping {
//            return [GlucoseSourceKey.nightscoutPing.rawValue: ping]
//        }
//        return nil
//    }

    

    

    func uploadTreatments(_ treatments: [HKQuantitySample], completionUpload: @escaping (Bool,Error?) -> Void) {
        guard !treatments.isEmpty, let nightscout = nightscoutAPI else {
            return
        }
        
        let CarbsEntries:[CarbsEntryNS] = treatments.map {
            CarbsEntryNS(
                    createdAt: $0.startDate,
                    carbs: Decimal(round($0.quantity.doubleValue(for: HealthDataHelper.unitCarbs)*100)/100),
                    enteredBy: CarbsEntryNS.manual
            )
        }

        processQueue.async {
            nightscout.uploadTreatments(CarbsEntries)
                .sink { completion in
                switch completion {
                case .finished:
                    //self.storage.save(treatments, as: fileToSave)
                    completionUpload(true,nil)
                case let .failure(error):
                    completionUpload(false,error)
                    //debug(.nightscout, error.localizedDescription)
                }
            } receiveValue: {}
            .store(in: &self.lifetime)
        }
    }
}
