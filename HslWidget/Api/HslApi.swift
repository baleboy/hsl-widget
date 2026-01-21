//
//  HslApi.swift
//  HslWidget
//
//  Created by Francesco Balestrieri on 5.5.2024.
//

import Foundation

class HslApi {

    static let shared = HslApi()

    static var apiKey: String? {
        guard let apiKey = Bundle.main.object(forInfoDictionaryKey: "HSL_API_KEY") as? String else {
            fatalError("Could not read HSL API Key from Info.plist")
        }
        return apiKey
    }

    private let routingUrl = "https://api.digitransit.fi/routing/v2/hsl/gtfs/v1?digitransit-subscription-key="

    /// Create ephemeral URLSession that doesn't cache and can be cleaned up
    private func createSession() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.urlCache = nil
        return URLSession(configuration: config)
    }
        
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
            let session = createSession()
            defer { session.invalidateAndCancel() }

            let request = try buildRequest(query: query)
            let (data, _) = try await session.data(for: request)

            if let decodedResponse = try? JSONDecoder().decode(StopsQueryResponse.self, from: data) {
                var result = [Stop]()
                let stops = decodedResponse.data.stops
                debugLog("HslApi: Received \(stops.count) stops from API")

                // Deduplicate by code, merging vehicle modes from all occurrences
                // This collects ALL stop IDs that share the same code (for multi-direction stops)
                // Also filter stops without codes
                var stopsByCode: [String: Stop] = [:]
                var routeCountsByCode: [String: [String: Int]] = [:] // code -> (mode -> count)

                for stop in stops {
                    // Skip stops without a code
                    guard let code = stop.code, !code.isEmpty else {
                        continue
                    }

                    // Count routes per mode
                    var routeCounts = routeCountsByCode[code] ?? [:]
                    if let routes = stop.routes {
                        for route in routes {
                            routeCounts[route.mode, default: 0] += 1
                        }
                    }
                    routeCountsByCode[code] = routeCounts

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

                        // Calculate primary mode from accumulated route counts
                        let primaryMode = Stop.calculatePrimaryMode(from: routeCounts)

                        // Create merged stop with combined modes and all IDs
                        let mergedStop = Stop(
                            id: stop.gtfsId,
                            name: stop.name,
                            code: code,
                            latitude: stop.lat ?? existing.latitude,
                            longitude: stop.lon ?? existing.longitude,
                            vehicleModes: mergedModes.isEmpty ? nil : mergedModes,
                            allStopIds: allIds,
                            primaryMode: primaryMode
                        )

                        debugLog("HslApi: Merging \(code): collected IDs \(allIds), modes: \(mergedModes), primary: \(primaryMode ?? "nil")")
                        stopsByCode[code] = mergedStop
                    } else {
                        // First occurrence of this code
                        let primaryMode = Stop.calculatePrimaryMode(from: routeCounts)
                        let newStop = Stop(id: stop.gtfsId, name: stop.name, code: code, latitude: stop.lat, longitude: stop.lon, vehicleModes: vehicleModes, allStopIds: [stop.gtfsId], primaryMode: primaryMode)
                        stopsByCode[code] = newStop
                    }
                }

                result = Array(stopsByCode.values)
                debugLog("HslApi: Returning \(result.count) stops after deduplication")
                return result
            } else {
                debugLog("HslApi: Failed to decode stops response")
                if let jsonString = String(data: data, encoding: .utf8) {
                    debugLog("HslApi: Raw response (first 500 chars): \(jsonString.prefix(500))")
                }
            }
        } catch {
            debugLog("HslApi: Error requesting stops: \(error)")
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
            let session = createSession()
            defer { session.invalidateAndCancel() }

            let request = try buildRequest(query: query)
            let (data, _) = try await session.data(for: request)

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
                debugLog("HslApi: Error fetching headsigns for stop \(stopId): \(error)")
            }
        }
        return []
    }

    func fetchDepartures(stationId: String, numberOfResults: Int) async -> [Departure] {

        let query = """
            {
                stop(id:\"\(stationId)\"){
                    stoptimesWithoutPatterns(numberOfDepartures: \(numberOfResults)) {
                        scheduledDeparture
                        realtimeDeparture
                        realtime
                        realtimeState
                        serviceDay
                        departureDelay
                        headsign
                        stop {
                            platformCode
                        }
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
            let session = createSession()
            defer { session.invalidateAndCancel() }

            let request = try buildRequest(query: query)
            let (data, _) = try await session.data(for: request)
            if let decodedResponse = try? JSONDecoder().decode(DepartureTimesQueryResponse.self, from: data) {
                var result = [Departure]()
                for stopTime in decodedResponse.data.stop.stoptimesWithoutPatterns {
                    // Use scheduled departure for display time
                    let scheduledTimeStamp = stopTime.serviceDay + stopTime.scheduledDeparture
                    let scheduledDate = Date(timeIntervalSince1970: scheduledTimeStamp)

                    // Calculate realtime departure for timeline purposes
                    let realtimeTimeStamp = stopTime.serviceDay + stopTime.realtimeDeparture
                    let realtimeDate = Date(timeIntervalSince1970: realtimeTimeStamp)

                    let shortName = stopTime.trip.route.shortName
                    let headsign = stopTime.headsign
                    let mode = stopTime.trip.route.mode
                    let delaySeconds = stopTime.departureDelay
                    let platformCode = stopTime.stop?.platformCode
                    let departure = Departure(
                        departureTime: scheduledDate,
                        routeShortName: shortName,
                        headsign: headsign ?? "No headsign",
                        mode: mode,
                        delaySeconds: delaySeconds,
                        realtimeDepartureTime: realtimeDate,
                        platformCode: platformCode,
                        hasRealtimeData: stopTime.realtime,
                        realtimeState: stopTime.realtimeState,
                        serviceDay: stopTime.serviceDay
                    )
                    result.append(departure)

                    // Debug: log scheduled vs realtime
                    let formatter = DateFormatter()
                    formatter.dateFormat = "HH:mm:ss"
                    debugLog("HslApi: \(shortName) scheduled=\(formatter.string(from: scheduledDate)) realtime=\(formatter.string(from: realtimeDate)) delay=\(delaySeconds)s hasRealtime=\(stopTime.realtime) state=\(stopTime.realtimeState ?? "nil")")
                }
                debugLog("HslApi: Fetched \(result.count) departures for stop \(stationId)")
                return result
            } else {
                debugLog("HslApi: Failed to decode departures for stop \(stationId)")
            }
        } catch {
            debugLog("HslApi: Error fetching departures for stop \(stationId): \(error)")
        }
        return []
    }

    private func buildRequest(query: String) throws -> URLRequest {
        guard let url = URL(string: routingUrl + HslApi.apiKey!) else {
            debugLog("Invalid URL")
            throw HslApiError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = query.data(using: .utf8)
        request.setValue("application/graphql", forHTTPHeaderField: "Content-Type")

        // Request translations based on device language (supports fi, sv, en)
        let language = Locale.current.language.languageCode?.identifier ?? "fi"
        request.setValue(language, forHTTPHeaderField: "Accept-Language")

        return request
    }

}
