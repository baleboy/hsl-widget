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
            routes {
              mode
            }
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

                // Deduplicate by code, merging vehicle modes from all occurrences
                // This collects ALL stop IDs that share the same code (for multi-direction stops)
                // Also filter stops without codes
                var stopsByCode: [String: Stop] = [:]

                for stop in stops {
                    // Skip stops without a code
                    guard let code = stop.code, !code.isEmpty else {
                        continue
                    }

                    // Extract unique vehicle modes from routes
                    var vehicleModes: Set<String>? = nil
                    if let routes = stop.routes, !routes.isEmpty {
                        vehicleModes = Set(routes.map { $0.mode })
                    }

                    // Check if we already have a stop with this code
                    if let existing = stopsByCode[code] {
                        // Merge vehicle modes from both the existing and new stop
                        var mergedModes = existing.vehicleModes ?? Set<String>()
                        if let newModes = vehicleModes {
                            mergedModes.formUnion(newModes)
                        }

                        // Collect all stop IDs for this code
                        var allIds = existing.allStopIds ?? [existing.id]
                        allIds.append(stop.gtfsId)

                        // Create merged stop with combined modes and all IDs
                        let mergedStop = Stop(
                            id: stop.gtfsId,
                            name: stop.name,
                            code: code,
                            latitude: stop.lat ?? existing.latitude,
                            longitude: stop.lon ?? existing.longitude,
                            vehicleModes: mergedModes.isEmpty ? nil : mergedModes,
                            allStopIds: allIds
                        )

                        print("HslApi: Merging \(code): collected IDs \(allIds), modes: \(mergedModes)")
                        stopsByCode[code] = mergedStop
                    } else {
                        // First occurrence of this code
                        let newStop = Stop(id: stop.gtfsId, name: stop.name, code: code, latitude: stop.lat, longitude: stop.lon, vehicleModes: vehicleModes, allStopIds: [stop.gtfsId])
                        stopsByCode[code] = newStop
                    }
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
    
    
    func fetchHeadsigns(stopId: String) async -> [String] {
        let query = """
            {
                stop(id:\"\(stopId)\"){
                    stoptimesWithoutPatterns(numberOfDepartures: 10) {
                        headsign
                    }
                }
            }
            """
        do {
            let request = try buildRequest(query: query)
            let (data, _) = try await URLSession.shared.data(for: request)

            if let decodedResponse = try? JSONDecoder().decode(HeadsignsQueryResponse.self, from: data) {
                // Extract unique headsigns
                let headsigns = decodedResponse.data.stop.stoptimesWithoutPatterns
                    .compactMap { $0.headsign }
                    .filter { !$0.isEmpty }

                // Get unique headsigns while preserving order
                var uniqueHeadsigns: [String] = []
                var seen = Set<String>()
                for headsign in headsigns {
                    if !seen.contains(headsign) {
                        uniqueHeadsigns.append(headsign)
                        seen.insert(headsign)
                    }
                }

                return Array(uniqueHeadsigns.prefix(3)) // Return max 3 headsigns
            }
        } catch {
            // Ignore cancellation errors - they're expected when user types/scrolls quickly
            let nsError = error as NSError
            if nsError.domain != NSURLErrorDomain || nsError.code != NSURLErrorCancelled {
                print("HslApi: Error fetching headsigns for stop \(stopId): \(error)")
            }
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
                    let mode = stopTime.trip.route.mode
                    let departure = Departure(departureTime: date, routeShortName: shortName,
                        headsign: headsign ?? "No headsign", mode: mode)
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
