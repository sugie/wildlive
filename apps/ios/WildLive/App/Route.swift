// WildLive — Navigation destinations.
//
// One flat enum drives every push in the NavigationStack. Each case carries
// exactly the identifiers the destination needs to load its own data — never
// a whole model — so navigation state stays cheap, Hashable, and every screen
// is reachable from a cold start.
//
// The expedition flow reads as the player experiences it:
//
//   maps → mapDetail → hunterPicker → dispatchConfirm → expedition
//                                                          ↓
//                                                      captureName → myZoo

import Foundation

enum Route: Hashable {
    // MARK: Live gameplay
    case myZoo
    case maps
    case mapDetail(mapID: String)
    case hunterPicker(mapID: String)
    case dispatchConfirm(mapID: String, hunterID: String)
    case expeditions
    case expedition(expeditionID: String)
    case captureName(expeditionID: String)
    case guild

    // MARK: Still mocked (prototype screens, not part of the live loop)
    case otherZoos
    case visitZoo(playerId: String)
    case animalDetail(animalId: UUID)
    case store
}
