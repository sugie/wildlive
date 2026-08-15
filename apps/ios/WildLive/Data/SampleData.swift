// WildLive — Hand-authored dummy data for the remaining prototype screens.
//
// Nothing here is authoritative. It backs Other Zoos, Visit Zoo, Animal
// detail and the G Store; the live expedition loop uses real Game Master
// v0.3 data from the server instead.
//
// The Hunter and Region fixtures that used to live here were removed when
// those concepts went live: Hunters now come from GET /api/hunters and Maps
// from GET /api/players/{id}/maps, and keeping a parallel hand-written set
// would just be a second answer to the same question.

import Foundation

enum SampleData {

    // MARK: Species

    static let species: [Species] = [
        // Common
        Species(id: "red_fox",             commonName: "Red Fox",             scientificName: "Vulpes vulpes",         rarity: .common,    habitatSummary: "Temperate forests and grasslands, widespread."),
        Species(id: "raccoon",             commonName: "Raccoon",             scientificName: "Procyon lotor",         rarity: .common,    habitatSummary: "North American forests and urban edges."),
        Species(id: "wild_boar",           commonName: "Wild Boar",           scientificName: "Sus scrofa",            rarity: .common,    habitatSummary: "Broadleaf forests across Eurasia."),
        Species(id: "roe_deer",            commonName: "Roe Deer",            scientificName: "Capreolus capreolus",   rarity: .common,    habitatSummary: "Europe woodlands and farmland."),

        // Uncommon
        Species(id: "eurasian_lynx",       commonName: "Eurasian Lynx",       scientificName: "Lynx lynx",             rarity: .uncommon,  habitatSummary: "Boreal and mountain forests of Eurasia."),
        Species(id: "grey_wolf",           commonName: "Grey Wolf",           scientificName: "Canis lupus",           rarity: .uncommon,  habitatSummary: "Northern Hemisphere wilderness."),
        Species(id: "moose",               commonName: "Moose",               scientificName: "Alces alces",           rarity: .uncommon,  habitatSummary: "Boreal forests, near lakes and wetlands."),
        Species(id: "japanese_serow",      commonName: "Japanese Serow",      scientificName: "Capricornis crispus",   rarity: .uncommon,  habitatSummary: "Mountain forests of Honshu, Shikoku, Kyushu."),

        // Rare
        Species(id: "snow_leopard",        commonName: "Snow Leopard",        scientificName: "Panthera uncia",        rarity: .rare,      habitatSummary: "High mountains of Central and South Asia."),
        Species(id: "asian_elephant",      commonName: "Asian Elephant",      scientificName: "Elephas maximus",       rarity: .rare,      habitatSummary: "South and Southeast Asian forests and grasslands."),
        Species(id: "polar_bear",          commonName: "Polar Bear",          scientificName: "Ursus maritimus",       rarity: .rare,      habitatSummary: "Arctic sea ice and coastal regions."),
        Species(id: "giant_panda",         commonName: "Giant Panda",         scientificName: "Ailuropoda melanoleuca",rarity: .rare,      habitatSummary: "Bamboo forests of southwestern China."),

        // Epic
        Species(id: "sumatran_tiger",      commonName: "Sumatran Tiger",      scientificName: "Panthera tigris sumatrae", rarity: .epic,  habitatSummary: "Rainforests of Sumatra, Indonesia."),
        Species(id: "amur_leopard",        commonName: "Amur Leopard",        scientificName: "Panthera pardus orientalis", rarity: .epic, habitatSummary: "Temperate forests of the Russian Far East."),
        Species(id: "javan_rhinoceros",    commonName: "Javan Rhinoceros",    scientificName: "Rhinoceros sondaicus",  rarity: .epic,      habitatSummary: "Ujung Kulon National Park, Java."),

        // Legendary
        Species(id: "vaquita",             commonName: "Vaquita",             scientificName: "Phocoena sinus",        rarity: .legendary, habitatSummary: "Northern Gulf of California."),
        Species(id: "kakapo",              commonName: "Kakapo",              scientificName: "Strigops habroptilus",  rarity: .legendary, habitatSummary: "Predator-free islands of New Zealand."),
        Species(id: "saola",               commonName: "Saola",               scientificName: "Pseudoryx nghetinhensis", rarity: .legendary, habitatSummary: "Annamite Range, Vietnam and Laos.")
    ]

    static var speciesById: [String: Species] {
        Dictionary(uniqueKeysWithValues: species.map { ($0.id, $0) })
    }

    // MARK: G Bundles (RevenueCat-shaped mock products)

    static let gBundles: [GBundle] = [
        GBundle(id: "dev.wildlive.g.small",   title: "Small pouch of G",   gAmount: 500,    priceDisplay: "¥160",    bonusLabel: nil),
        GBundle(id: "dev.wildlive.g.medium",  title: "Medium sack of G",   gAmount: 1_800,  priceDisplay: "¥600",    bonusLabel: "+20%"),
        GBundle(id: "dev.wildlive.g.large",   title: "Large chest of G",   gAmount: 4_000,  priceDisplay: "¥1,200",  bonusLabel: "+33%"),
        GBundle(id: "dev.wildlive.g.huge",    title: "Explorer's vault",   gAmount: 12_000, priceDisplay: "¥3,200",  bonusLabel: "+50%")
    ]

    // MARK: Player (the current user)

    static func makeCurrentPlayer() -> Player {
        Player(
            id: "player_me",
            displayName: "You",
            gBalance: 1_200,
            animals: [
                Animal(id: UUID(), speciesId: "red_fox",       nickname: "Cinder",  trait: .none,             capturedAt: Date().addingTimeInterval(-86_400 * 3), capturedFromRegionId: "outskirts",       capturedByHunterId: "hunter_ash"),
                Animal(id: UUID(), speciesId: "roe_deer",      nickname: "Dawn",    trait: .exceptionalSize,  capturedAt: Date().addingTimeInterval(-86_400 * 2), capturedFromRegionId: "outskirts",       capturedByHunterId: "hunter_bea"),
                Animal(id: UUID(), speciesId: "eurasian_lynx", nickname: nil,       trait: .none,             capturedAt: Date().addingTimeInterval(-86_400),     capturedFromRegionId: "northern_taiga",  capturedByHunterId: "hunter_cy")
            ]
        )
    }

    // MARK: Other players (for the "visit other zoos" flow)

    static func makeOtherPlayers() -> [Player] {
        [
            Player(
                id: "player_kai",
                displayName: "Kai",
                gBalance: 320,
                animals: [
                    Animal(id: UUID(), speciesId: "wild_boar",   nickname: "Bramble",  trait: .none,        capturedAt: Date(), capturedFromRegionId: "outskirts",         capturedByHunterId: "hunter_ash"),
                    Animal(id: UUID(), speciesId: "grey_wolf",   nickname: "Nord",     trait: .melanistic,  capturedAt: Date(), capturedFromRegionId: "northern_taiga",    capturedByHunterId: "hunter_cy"),
                    Animal(id: UUID(), speciesId: "snow_leopard",nickname: "Ghost",    trait: .none,        capturedAt: Date(), capturedFromRegionId: "himalayan_range",   capturedByHunterId: "hunter_eiji")
                ]
            ),
            Player(
                id: "player_rin",
                displayName: "Rin",
                gBalance: 5_400,
                animals: [
                    Animal(id: UUID(), speciesId: "sumatran_tiger", nickname: "Ember",     trait: .exceptionalSize, capturedAt: Date(), capturedFromRegionId: "sumatran_rainforest", capturedByHunterId: "hunter_gwen"),
                    Animal(id: UUID(), speciesId: "amur_leopard",   nickname: "Frost",     trait: .none,            capturedAt: Date(), capturedFromRegionId: "annamite_range",      capturedByHunterId: "hunter_hoshi"),
                    Animal(id: UUID(), speciesId: "giant_panda",    nickname: "Bamboo",    trait: .none,            capturedAt: Date(), capturedFromRegionId: "himalayan_range",     capturedByHunterId: "hunter_eiji"),
                    Animal(id: UUID(), speciesId: "kakapo",         nickname: "Twilight",  trait: .leucistic,       capturedAt: Date(), capturedFromRegionId: "annamite_range",      capturedByHunterId: "hunter_hoshi")
                ]
            ),
            Player(
                id: "player_juno",
                displayName: "Juno",
                gBalance: 90,
                animals: [
                    Animal(id: UUID(), speciesId: "red_fox", nickname: "Copper", trait: .none, capturedAt: Date(), capturedFromRegionId: "outskirts", capturedByHunterId: "hunter_ash"),
                    Animal(id: UUID(), speciesId: "raccoon", nickname: nil,       trait: .none, capturedAt: Date(), capturedFromRegionId: "outskirts", capturedByHunterId: "hunter_ash")
                ]
            )
        ]
    }
}
