//
//  HslApi.swift
//  HslWidget
//
//  Created by Francesco Balestrieri on 5.5.2024.
//

import Foundation

class HslApi {
    
    static let shared = HslApi()
    
    private let routingUrl = "https://api.digitransit.fi/routing/v2/hsl/gtfs/v1?digitransit-subscription-key="

    private let apiKey = "877adb1ee87e4aae9a7ff5fe39b2502b"
        
    enum HslApiError: Error {
        case invalidURL
        // Add more error cases as needed
    }
    
    
    func fetchAllStops() async -> [Stop] {
        let query = """
        {
          stops {
            gtfsId
            name
            code
            lat
            lon
          }
        }
        """
        do {
            let request = try buildRequest(query: query)
            let (data, _) = try await URLSession.shared.data(for: request)

            if let decodedResponse = try? JSONDecoder().decode(StopsQueryResponse.self, from: data) {
                var result = [Stop]()
                let stops = decodedResponse.data.stops
                print("HslApi: Received \(stops.count) stops from API")

                // Deduplicate by code, keeping the LAST occurrence
                // This typically keeps the platform/stop over the parent station
                // Also filter stops without codes
                var stopsByCode: [String: Stop] = [:]

                for stop in stops {
                    // Skip stops without a code
                    guard let code = stop.code, !code.isEmpty else {
                        continue
                    }

                    let newStop = Stop(id: stop.gtfsId, name: stop.name, code: code, latitude: stop.lat, longitude: stop.lon)

                    // Always replace - this keeps the last occurrence for each code
                    // In HSL data, parent stations typically come before platforms
                    if let existing = stopsByCode[code] {
                        print("HslApi: Replacing \(code): \(existing.id) -> \(newStop.id)")
                    }
                    stopsByCode[code] = newStop
                }

                result = Array(stopsByCode.values)
                print("HslApi: Returning \(result.count) stops after deduplication")
                return result
            } else {
                print("HslApi: Failed to decode stops response")
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("HslApi: Raw response (first 500 chars): \(jsonString.prefix(500))")
                }
            }
        } catch {
            print("HslApi: Error requesting stops: \(error)")
        }
        return []
    }
    
    
    func fetchDepartures(stationId: String, numberOfResults: Int) async -> [Departure] {

        let query = """
            {
                stop(id:\"\(stationId)\"){
                    stoptimesWithoutPatterns(numberOfDepartures: \(numberOfResults)) {
                        realtimeDeparture
                        serviceDay
                        headsign
                        trip{
                          route {
                            mode
                            shortName
                          }
                        }
                    }
                }
            }
            """
        do {
            let request = try buildRequest(query: query)
            let (data, _) = try await URLSession.shared.data(for: request)
            if let decodedResponse = try? JSONDecoder().decode(DepartureTimesQueryResponse.self, from: data) {
                var result = [Departure]()
                for stopTime in decodedResponse.data.stop.stoptimesWithoutPatterns {
                    let departureTimeStamp = stopTime.serviceDay + stopTime.realtimeDeparture
                    let date = Date(timeIntervalSince1970: departureTimeStamp)
                    let shortName = stopTime.trip.route.shortName
                    let headsign = stopTime.headsign
                    let departure = Departure(departureTime: date, routeShortName: shortName,
                        headsign: headsign ?? "No headsign")
                    result.append(departure)
                }
                print("HslApi: Fetched \(result.count) departures for stop \(stationId)")
                return result
            } else {
                print("HslApi: Failed to decode departures for stop \(stationId)")
            }
        } catch {
            print("HslApi: Error fetching departures for stop \(stationId): \(error)")
        }
        return []
    }

    private func buildRequest(query: String) throws -> URLRequest {
        guard let url = URL(string: routingUrl + apiKey) else {
            print("Invalid URL")
            throw HslApiError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = query.data(using: .utf8)
        request.setValue("application/graphql", forHTTPHeaderField: "Content-Type")
        return request
    }

}
