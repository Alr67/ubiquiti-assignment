import Testing
import Foundation
@testable import SLplanner

struct DecodingTests {

    // MARK: - Site Decoding

    @Test func decodeSiteWithAllFields() throws {
        let json = """
        {
            "id": 3401,
            "gid": 9091001000003401,
            "name": "Hagaplan",
            "alias": ["Karolinska sjukhuset Eugeniav\u{00e4}gen"],
            "abbreviation": "HAGA",
            "note": "f.d. Karolinska sjukhuset",
            "lat": 59.348,
            "lon": 18.030,
            "stop_areas": [10357],
            "valid": {"from": "2025-12-14T00:00:00"}
        }
        """
        let site = try JSONDecoder().decode(Site.self, from: Data(json.utf8))
        #expect(site.id == 3401)
        #expect(site.name == "Hagaplan")
        #expect(site.alias == ["Karolinska sjukhuset Eugeniav\u{00e4}gen"])
        #expect(site.abbreviation == "HAGA")
        #expect(site.note == "f.d. Karolinska sjukhuset")
        #expect(site.lat == 59.348)
        #expect(site.lon == 18.030)
        #expect(site.stopAreas == [10357])
    }

    @Test func decodeSiteMissingOptionalFields() throws {
        let json = """
        {
            "id": 5061,
            "gid": 9091001000005061,
            "name": "Sollentuna sim- och sporthall",
            "stop_areas": [52349],
            "valid": {"from": "2023-11-16T00:00:00"}
        }
        """
        let site = try JSONDecoder().decode(Site.self, from: Data(json.utf8))
        #expect(site.id == 5061)
        #expect(site.name == "Sollentuna sim- och sporthall")
        #expect(site.lat == nil)
        #expect(site.lon == nil)
        #expect(site.alias == nil)
        #expect(site.abbreviation == nil)
        #expect(site.note == nil)
    }

    // MARK: - Departure Decoding

    @Test func decodeDeparturesResponse() throws {
        let json = """
        {
            "departures": [
                {
                    "destination": "Hässelby strand",
                    "direction_code": 1,
                    "direction": "Hässelby strand",
                    "state": "EXPECTED",
                    "display": "5 min",
                    "scheduled": "2026-03-02T10:46:08",
                    "expected": "2026-03-02T10:46:24",
                    "journey": {"id": 2026030280031, "state": "NORMALPROGRESS"},
                    "stop_area": {"id": 1011, "name": "Slussen", "type": "METROSTN"},
                    "stop_point": {"id": 1011, "name": "Slussen", "designation": "1"},
                    "line": {
                        "id": 19,
                        "designation": "19",
                        "transport_authority_id": 1,
                        "transport_mode": "METRO",
                        "group_of_lines": "Tunnelbanans gröna linje"
                    },
                    "deviations": []
                }
            ],
            "stop_deviations": [
                {
                    "importance_level": 5,
                    "message": "Hiss ur funktion"
                }
            ]
        }
        """
        let response = try JSONDecoder().decode(DeparturesResponse.self, from: Data(json.utf8))
        #expect(response.departures.count == 1)
        #expect(response.stopDeviations.count == 1)

        let departure = response.departures[0]
        #expect(departure.destination == "Hässelby strand")
        #expect(departure.state == .expected)
        #expect(departure.display == "5 min")
        #expect(departure.line.designation == "19")
        #expect(departure.line.transportMode == .metro)
        #expect(departure.line.groupOfLines == "Tunnelbanans gröna linje")
        #expect(departure.stopArea.type == "METROSTN")
        #expect(departure.stopPoint.designation == "1")
    }

    @Test func decodeCancelledDeparture() throws {
        let json = """
        {
            "destination": "Fruängen",
            "direction_code": 2,
            "direction": "Fruängen",
            "state": "CANCELLED",
            "display": "10:46",
            "scheduled": "2026-03-02T10:46:00",
            "expected": "2026-03-02T10:46:00",
            "journey": {"id": 12345, "state": "CANCELLED"},
            "stop_area": {"id": 1011, "name": "Slussen", "type": "METROSTN"},
            "stop_point": {"id": 1011, "name": "Slussen"},
            "line": {
                "id": 14,
                "designation": "14",
                "transport_authority_id": 1,
                "transport_mode": "METRO"
            },
            "deviations": [
                {"importance_level": 7, "consequence": "CANCELLED", "message": "Inställd"}
            ]
        }
        """
        let departure = try JSONDecoder().decode(Departure.self, from: Data(json.utf8))
        #expect(departure.state == .cancelled)
        #expect(departure.stopPoint.designation == nil)
        #expect(departure.line.groupOfLines == nil)
        #expect(departure.deviations.count == 1)
        #expect(departure.deviations[0].importanceLevel == 7)
    }

    // MARK: - TransportMode

    @Test func transportModeFromStopAreaType() {
        #expect(TransportMode.from(stopAreaType: "BUSTERM") == .bus)
        #expect(TransportMode.from(stopAreaType: "METROSTN") == .metro)
        #expect(TransportMode.from(stopAreaType: "RAILWSTN") == .train)
        #expect(TransportMode.from(stopAreaType: "TRAMSTN") == .tram)
        #expect(TransportMode.from(stopAreaType: "SHIPBER") == .ship)
        #expect(TransportMode.from(stopAreaType: "FERRYBER") == .ship)
        #expect(TransportMode.from(stopAreaType: "UNKNOWN") == nil)
    }
}
