// WildLive — Hand-authored dummy data for the UI prototype.
//
// Nothing here is authoritative. The list is intentionally small (18 species,
// 8 hunters, 6 regions) — enough to exercise every screen without pretending
// to be the real Species master data.

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

    // MARK: Hunters

    static let hunters: [Hunter] = [
        Hunter(id: "hunter_ash",     name: "Ash the Apprentice",   tier: .basic,     skill: 15, contractCostG: 50,   bio: "Guild trainee. Available to anyone, any time.",                              available: true),
        Hunter(id: "hunter_bea",     name: "Bea Ironfoot",         tier: .basic,     skill: 22, contractCostG: 80,   bio: "Steady, reliable, unremarkable.",                                            available: true),
        Hunter(id: "hunter_cy",      name: "Cy Longstride",        tier: .advanced,  skill: 42, contractCostG: 260,  bio: "Ten seasons in the northern forests.",                                       available: true),
        Hunter(id: "hunter_dara",    name: "Dara of the Marsh",    tier: .advanced,  skill: 48, contractCostG: 320,  bio: "Specialises in wetlands. Prefers dawn dispatches.",                          available: true),
        Hunter(id: "hunter_eiji",    name: "Eiji Silvermoon",      tier: .elite,     skill: 68, contractCostG: 900,  bio: "Elite tracker. Contracts limited by Guild rotation.",                         available: true),
        Hunter(id: "hunter_fen",     name: "Fen the Quiet",        tier: .elite,     skill: 74, contractCostG: 1_100, bio: "Rare-region specialist. Currently working for another player.",             available: false),
        Hunter(id: "hunter_gwen",    name: "Gwendolyn Ashenwild",  tier: .legendary, skill: 92, contractCostG: 3_800, bio: "Legendary. One contract at a time across the entire Guild.",                available: true),
        Hunter(id: "hunter_hoshi",   name: "Hoshi of the High Passes", tier: .legendary, skill: 96, contractCostG: 4_500, bio: "Legendary. Rumoured to have found a Saola.",                          available: false)
    ]

    // MARK: Regions

    static let regions: [Region] = [
        Region(
            id: "outskirts",
            name: "Village Outskirts",
            subtitle: "Farmland edges, low forest",
            difficulty: .easy,
            simulatedDurationSeconds: 8,
            speciesPool: ["red_fox", "raccoon", "wild_boar", "roe_deer"],
            flavor: "Where anyone can begin. Common animals, quick returns."
        ),
        Region(
            id: "northern_taiga",
            name: "Northern Taiga",
            subtitle: "Boreal forest, cold rivers",
            difficulty: .medium,
            simulatedDurationSeconds: 20,
            speciesPool: ["grey_wolf", "moose", "eurasian_lynx", "red_fox"],
            flavor: "Vast, quiet, unforgiving. Hunters return with stories."
        ),
        Region(
            id: "japanese_alps",
            name: "Japanese Alps",
            subtitle: "Steep mountains, dense broadleaf",
            difficulty: .medium,
            simulatedDurationSeconds: 24,
            speciesPool: ["japanese_serow", "roe_deer", "eurasian_lynx"],
            flavor: "The Serow watches from the ridgeline."
        ),
        Region(
            id: "himalayan_range",
            name: "Himalayan Range",
            subtitle: "Alpine slopes above 4000m",
            difficulty: .high,
            simulatedDurationSeconds: 40,
            speciesPool: ["snow_leopard", "asian_elephant", "giant_panda"],
            flavor: "Thin air. Rare eyes in the snow."
        ),
        Region(
            id: "sumatran_rainforest",
            name: "Sumatran Rainforest",
            subtitle: "Equatorial rainforest",
            difficulty: .extreme,
            simulatedDurationSeconds: 55,
            speciesPool: ["sumatran_tiger", "asian_elephant", "javan_rhinoceros"],
            flavor: "Few Hunters return the way they left."
        ),
        Region(
            id: "annamite_range",
            name: "Annamite Range",
            subtitle: "Legendary. Whispers only.",
            difficulty: .extreme,
            simulatedDurationSeconds: 60,
            speciesPool: ["saola", "amur_leopard", "kakapo", "vaquita"],
            flavor: "Even a Legendary Hunter may return empty-handed."
        )
    ]

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
