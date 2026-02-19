# LifeAgenda iOS 📱

App iOS de discipline personnelle — compagnon de l'app Iqra.

**Bundle ID :** `com.rezaimia.LifeAgenda`  
**Team ID :** `J875R59LND`  
**Target iOS :** 16.0+

---

## Structure du projet

```
LifeAgenda/
├── project.yml                     ← XcodeGen config
├── Gemfile                         ← Fastlane gems
├── fastlane/
│   ├── Fastfile                    ← Lanes build/deploy
│   ├── Appfile                     ← Bundle ID + Team ID
│   └── Matchfile                   ← Certificats via Match
├── .github/workflows/
│   └── deploy.yml                  ← GitHub Actions CI/CD
├── LifeAgenda/
│   ├── LifeAgendaApp.swift         ← Entry point
│   ├── Models/
│   │   └── Models.swift            ← DailyTask, SportProgram, etc.
│   ├── ViewModels/
│   │   └── AppStore.swift          ← Source de vérité (ObservableObject)
│   ├── Views/
│   │   ├── Shared/
│   │   │   └── ContentView.swift   ← Tab bar navigation
│   │   ├── Agenda/
│   │   │   └── AgendaView.swift    ← Vue principale
│   │   ├── Sport/
│   │   │   └── SportView.swift     ← Programme sportif
│   │   ├── Ideas/
│   │   │   └── IdeasView.swift     ← Notes & idées
│   │   └── Money/
│   │       └── MoneyView.swift     ← Finances
│   ├── Services/
│   │   └── WidgetSyncService.swift ← Sync App Group → Widget
│   ├── Resources/
│   │   └── DesignSystem.swift      ← Couleurs, fonts, helpers
│   └── Supporting/
│       ├── LifeAgenda.entitlements ← App Groups
│       └── Info.plist              ← auto-généré par XcodeGen
└── LifeAgendaWidget/
    ├── LifeAgendaWidget.swift      ← Widget home + lock screen
    ├── LifeAgendaWidget.entitlements
    └── Info.plist
```

---

## Setup initial (Windows / Git Bash)

### 1. Prérequis
Tu travailles sur Windows → le build se fait **100% via GitHub Actions** sur macOS hébergé. Tu n'as besoin que de :
- Git Bash
- Un compte GitHub avec ce repo

### 2. Créer les Bundle IDs sur App Store Connect

Aller sur [appstoreconnect.apple.com](https://appstoreconnect.apple.com) → Certificates, IDs & Profiles :

| Identifier | Bundle ID |
|---|---|
| LifeAgenda App | `com.rezaimia.LifeAgenda` |
| LifeAgenda Widget | `com.rezaimia.LifeAgenda.widget` |

Activer pour chaque : **App Groups**, **Push Notifications**

### 3. Créer l'App Group

Dans Identifiers → App Groups → `+` → `group.com.rezaimia.shared`

Ajouter ce groupe aux deux identifiants ci-dessus.

### 4. Créer l'app sur App Store Connect

Aller dans My Apps → `+` → New App → remplir avec Bundle ID `com.rezaimia.LifeAgenda`

### 5. Configurer Match (certificats)

Match stocke les certs dans un repo Git privé (tu peux réutiliser le même que Iqra).

Dans `fastlane/Matchfile`, mettre ton repo de certs :
```ruby
git_url("https://github.com/TON_USER/certificates")
username("ton@apple-id.com")
```

### 6. GitHub Secrets à configurer

Dans Settings → Secrets → Actions du repo :

| Secret | Description |
|---|---|
| `MATCH_DEPLOY_KEY` | Clé SSH privée pour accéder au repo certificates |
| `MATCH_PASSWORD` | Mot de passe chiffrement Match |
| `APP_STORE_CONNECT_API_KEY_CONTENT` | JSON de la clé API ASC (même que Iqra) |

### 7. Premier build

```bash
git add .
git commit -m "feat: initial LifeAgenda iOS"
git push origin main
```

→ GitHub Actions lance automatiquement le build et l'upload TestFlight.

---

## Architecture

### AppStore (ViewModel)
`AppStore` est un `ObservableObject` partagé via `@EnvironmentObject`. Il gère :
- Tâches personnalisées par date
- Complétions (✓/✗) par tâche et par date
- Punitions actives
- Idées / Notes
- Transactions financières
- Sync vers App Group `group.com.rezaimia.shared`

### App Group & Intégration Iqra
Les données partagées sont écrites dans `UserDefaults(suiteName: "group.com.rezaimia.shared")` :
- `lifeagenda_shared` → `SharedAgendaData` (streak, progression, tâches du jour)
- `widgetTasks` → `[WidgetTaskData]` pour les widgets

**Dans l'app Iqra**, tu peux lire ces données ainsi :
```swift
let ud = UserDefaults(suiteName: "group.com.rezaimia.shared")
let data = ud?.data(forKey: "lifeagenda_shared")
let shared = try? JSONDecoder().decode(SharedAgendaData.self, from: data!)
```

### Deep Link depuis Iqra
Ajoute dans Iqra un bouton qui ouvre :
```swift
URL(string: "lifeagenda://agenda")
```

Ajoute dans `LifeAgendaApp.swift` :
```swift
.onOpenURL { url in
    if url.scheme == "lifeagenda" {
        selectedTab = .agenda
    }
}
```

Et dans `Info.plist` (XcodeGen) :
```yaml
CFBundleURLTypes:
  - CFBundleURLSchemes: [lifeagenda]
```

---

## Widgets

### Home Screen Widget
- **Small** : 3 tâches + progression %
- **Medium** : 4 tâches + streak
- **Large** : 8 tâches + streak + date

### Lock Screen Widget  
- **Circular** : Gauge de progression
- **Rectangular** : Tâches complétées + streak
- **Inline** : Compteur simple

Les widgets se rafraîchissent toutes les 30 minutes et à chaque validation de tâche.

---

## Prochaines étapes (à implémenter ensemble)

- [ ] **Programme sport par photo** — Claude Vision API
- [ ] **Horaires prières géolocalisées** — CoreLocation + API Aladhan
- [ ] **Sélecteur de religion** — Islam / Chrétien / Juif au setup
- [ ] **Anti-triche** — Screen Time API / validation géolocalisation mosquée
- [ ] **Module "Mon Agenda" dans Iqra** — avec deep link

---

## Design System

| Token | Valeur |
|---|---|
| Fond principal | `#0a0a0a` |
| Fond secondaire | `#141414` |
| Cards | `#1a1a1a` |
| Accent or | `#d4a853` |
| Accent vert | `#2dd4bf` |
| Accent rouge | `#ef4444` |
| Accent bleu | `#3b82f6` |
| Accent violet | `#a855f7` |
| Texte principal | `#f5f5f5` |
| Texte secondaire | `#a0a0a0` |
| Bordures | `#2a2a2a` |
