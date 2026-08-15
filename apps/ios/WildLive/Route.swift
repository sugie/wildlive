// WildLive — Navigation destinations for the UI prototype.
//
// One flat enum drives every push in the NavigationStack. Each case carries
// exactly the identifiers the destination view needs to look up state on
// AppStore — never a whole model — so navigation state stays cheap and
// Hashable.

import Foundation

enum Route: Hashable {
    case myZoo
    case otherZoos
    case visitZoo(playerId: String)
    case animalDetail(animalId: UUID)
    case guild
    case regionPicker(hunterId: String)
    case dispatchConfirm(hunterId: String, regionId: String)
    case expeditions
    case expeditionResult(expeditionId: UUID)
    case captureName(expeditionId: UUID)
    case store
}
