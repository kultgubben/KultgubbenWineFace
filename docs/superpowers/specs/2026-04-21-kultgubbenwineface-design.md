# KultgubbenWineFace — Design Spec

**Datum:** 2026-04-21
**Status:** Godkänd för implementation
**Projekt:** `C:\Users\rickard.larsson\Documents\KultgubbenWineFace\`

## Översikt

En Connect IQ **watch face** för Garmin Enduro 3 + Fenix 7/7S/7X/+Pro + Fenix 8 Solar + FR955. Visar tid, vinglas-räknare (Kultgubben-logik), datum och fem hälsokomplikationer (stress, body battery, batteritid, steg, puls). Designen är *Elegant* — serif-typografi, guldfärgad accent, spegelsymmetriska krökta texter längs bezelen.

Parallellt med befintliga projekt:
- **KultgubbenWine** (watch-app) — full drickes-logik med lägen, knappar, bonusclaim
- **KultgubbenWineField** (datafield) — samma logikkärna, syns bara under aktiviteter

Den här appen (WineFace) är urtavlan som visar vinglas-räknaren permanent.

## Omfattning

**I scope:**
- Watch face som visar tid + vinglas-räknare + datum + 5 komplikationer
- Vin-läge endast (inget växlande mellan vin/öl/champagne)
- Full AOD-stöd (always-on display) med low-power rendering
- Svenska + engelska språk

**Ej i scope (v1):**
- Mode-växling (bara vin)
- Bonus-claim (det sköts i watch-appen, inte här)
- Progressbar mot nästa glas
- Användar-inställningar (settings) — alla värden är fasta

## Visuell design

**Layoutprincip:** *Glas-hjälte* — vinglas i topp-centrerat som signatur, tid i centrum, datum under tid. Två krökta kompriktexter följer bezelen spegelsymmetriskt (topp + botten).

**Stil:** *Elegant* — serif-typsnitt (Georgia-liknande, egen `.fnt`-resurs), varm guldpalett, dämpade tonade färger.

**Färgpalett:**
| Element | Hex | Roll |
|---|---|---|
| Bakgrund | `#000000` | Svart (MIP-standard) |
| Glasfärg + antal | `#d4af37` | Varmt guld (hjälten) |
| Tid | `#f0e6d2` | Ljus guldvit |
| Datum | `#8a6d3b` | Dämpad guld |
| Kurvtext (topp + botten) | `#a8936a` | Guldgrå |

**Vertikal layout (280×280-referens):**

```
   ⚡ STRESS 34  ·  BB 67         ← topp-kurva r=118, y_mid=22
          🍷 3                     ← glas + antal, y=64-120
         14:32                     ← tid, font ~50, y=154-204
        TIS 21 APR                 ← datum, font ~12, y=204-216
   🔋 12d · 👣 7 240 · ♥ 62        ← botten-kurva r=128, y_mid=268
```

Gruppen glas+tid+datum är vertikalt centrerad mot urtavlans mitt.

**Krökta texter:**
- **Topp** — radie 118px, angular span ~100° (40° till 140°). Visar `⚡ STRESS NN · BB NN`.
- **Botten** — radie 128px, angular span ~100° (220° till 320°). Visar `🔋 Nd · 👣 N NNN · ♥ NN`.
- Asymmetri i radie kompenserar för att topp-textens "ovansida" pekar utåt (mot bezel) medan botten-texten pekar inåt. Vid samma radie skulle topptexten ligga optiskt närmare kanten.

**Ikoner i kurvtexter:**
- Egna små guldtonade bitmaps (~16×16) för: ⚡ blixt (stress), 🔋 batteri, 👣 fotspår, ♥ hjärta
- "BB" renderas som text-label (inte ikon) eftersom "body battery" saknar bra symbol
- Alla emojis i mockupen är platshållare — riktig app ritar PNG/vektorer

**Typografi:**
- Serif-font som egen resurs (konverterad från `.ttf` via Garmins font builder, t.ex. EB Garamond eller Playfair Display)
- Om font-build blir komplex i v1 → fallback till inbyggd `Graphics.FONT_SYSTEM_*` (sans-serif), dokumenteras som känd kompromiss
- Storlekar (på 280px-skärm): tid ~50px, datum ~12px, kurvtexter ~13px, glas-antal ~30px

## AOD-beteende (Always-On Display)

**Status v1: inaktiverat.** Urtavlan renderar samma fulla design i både wake- och sleep-läge.

**Motivering:**
- Enduro 3 har MIP-skärm (Memory-in-Pixel), inte AMOLED → ingen burn-in-risk
- Användaren föredrar den eleganta layouten alltid synlig (som tidigare urtavlor)
- MIP-tekniken drar ström per pixel-ändring, så statisk rendering i sleep kostar nästan ingenting

**Implementation:**
- `onEnterSleep()` / `onExitSleep()` är tomma stubbar — ingen state-växling
- `onUpdate(dc)` kör alltid full rendering

**Framtida återaktivering:**
Om AOD ska återinföras (t.ex. för AMOLED-enheter), återställ:
1. Fält `_isSleeping: Boolean` + låg-effekt-rendering `_drawAod(dc)`
2. Pixel-shift ±2 px baserat på `clock.min % 5`
3. Förgrening i `onUpdate` och `onPartialUpdate` för partial updates
Tidigare AOD-kod finns bevarad i git-historiken (commit före städ).

## Teknisk arkitektur

**Connect IQ app-typ:** `watch-face` (manifest `type="watch-face"`)

**Klasser:**

```
KultgubbenWineFaceApp extends AppBase
  ├── getInitialView() → [KultgubbenWineFaceView]

KultgubbenWineFaceView extends WatchUi.WatchFace
  ├── onLayout(dc)          → engångs-setup, ladda resurser
  ├── onShow()               → watch face blir synlig
  ├── onHide()               → watch face döljs
  ├── onUpdate(dc)           → full rendering (per sekund wake, per minut sleep)
  ├── onPartialUpdate(dc)    → minimal rendering (AOD partial update)
  ├── onEnterSleep()         → sätter _isSleeping = true
  ├── onExitSleep()          → sätter _isSleeping = false
  └── private:
      _isSleeping: Boolean
      _iconGlass, _iconBolt, _iconBattery, _iconFoot, _iconHeart: BitmapResource
      _fontSerifLarge, _fontSerifSmall, _fontSerifMicro: FontResource
```

**Data-källor:**

| Element | Källa | Fallback |
|---|---|---|
| Tid (HH:MM) | `System.getClockTime()` | — |
| Datum | `Time.Gregorian.info(Time.now(), FORMAT_MEDIUM)` | — |
| Vinglas-antal | `ActivityMonitor.getInfo().steps / stepsPerGlass + vigorous/30` | `0` om `Info` = null |
| Stress | `SensorHistory.getStressHistory({:period=>1})` → senaste sample | "—" om null |
| Body Battery | `SensorHistory.getBodyBatteryHistory({:period=>1})` → senaste sample | "—" om null |
| Batteri (dagar) | `System.getSystemStats().batteryInDays` | `System.getSystemStats().battery` (%) om null |
| Steg | `ActivityMonitor.getInfo().steps` | `0` om null |
| Puls | `ActivityMonitor.getHeartRateHistory(1, true)` senaste | "—" om null |

**Vinglas-formel:** samma som `KultgubbenWineField`:

```monkey
stepsPerGlass = isFriSat() ? 3000 : 4000
baseGlasses   = totalSteps / stepsPerGlass
bonusGlasses  = vigorous / 30
totalGlasses  = baseGlasses + bonusGlasses
```

Där `isFriSat()` = `day_of_week == 6 || day_of_week == 7` (Time.Gregorian).

**Krökt text-rendering:** `Dc.drawRadialText(centerX, centerY, font, text, justification, startAngleDeg, radius, attribute)` — tillgänglig i Connect IQ SDK 4.x+, stödd på Enduro 3.

**Ikon-rendering:** `Dc.drawBitmap(x, y, bitmapResource)` för PNG-resurser. Position beräknas så ikon + text blir visuellt sammanhållna på kurvan (ikon placeras först, text efter).

## Projektstruktur

```
KultgubbenWineFace/
├── manifest.xml                          # type="watch-face"
├── monkey.jungle
├── version.txt                           # "1.0" initialt
├── build-iq.ps1                          # bump + bygg .prg + .iq
├── .vscode/
│   └── tasks.json                        # Build, Start Simulator, Run in Simulator
├── resources/
│   ├── strings/strings.xml               # "KultgubbenWine", labels
│   ├── drawables/
│   │   ├── drawables.xml
│   │   ├── launcher_icon.png             # kopia av icon_wine.png
│   │   ├── icon_glass.png                # vinglas i guld
│   │   ├── icon_bolt.png                 # blixt (stress)
│   │   ├── icon_battery.png              # batteri
│   │   ├── icon_foot.png                 # fotspår
│   │   └── icon_heart.png                # hjärta
│   └── fonts/
│       ├── serif_large.fnt               # tid
│       ├── serif_small.fnt               # datum + kurvtext
│       └── serif_micro.fnt               # (om behövs)
├── resources-swe/
│   └── strings/strings.xml               # svenska strängar
├── source/
│   ├── KultgubbenWineFaceApp.mc
│   └── KultgubbenWineFaceView.mc
└── docs/
    └── superpowers/specs/
        └── 2026-04-21-kultgubbenwineface-design.md  (denna fil)
```

## Enheter (manifest products)

Samma lista som `KultgubbenWineField`:
- `enduro3`
- `fenix7`, `fenix7pro`, `fenix7s`, `fenix7spro`, `fenix7x`, `fenix7xpro`
- `fenix8solar47mm`, `fenix8solar51mm`
- `fr955`

Layout skalas via relativa positioner (radie/vinkel från centrum + procentsatser), inte fasta pixelkoordinater, så samma kod funkar på olika skärmstorlekar.

## Build-tooling

Samma pattern som `KultgubbenWineField`:

- `build-iq.ps1`:
  - Bumpar `version.txt` (minor-bump)
  - Bygger `.prg` för `enduro3`
  - Bygger `.iq` (distribuerbar paket) med `-e`-flagga
- `.vscode/tasks.json`:
  - "Build KultgubbenWineFace" (default build)
  - "Build IQ Package" (kör `build-iq.ps1`)
  - "Start Simulator" (startar simulator.exe detached om inte redan igång)
  - "Run in Simulator" (beroende av Build + Start Simulator)
- Developer key: `C:\Users\rickard.larsson\.connectiq\developer_key.der` (delad med andra projekten)
- SDK: `%APPDATA%\Garmin\ConnectIQ\Sdks\connectiq-sdk-win-8.4.1-2026-02-03-e9f77eeaa\`

## Manifest-specifika fält

- `type="watch-face"`
- `entry="KultgubbenWineFaceApp"`
- `minApiLevel="4.0.0"` (krävs för `drawRadialText`, `batteryInDays`)
- `launcherIcon="@Drawables.LauncherIcon"`
- Permissions: `UserProfile`, `SensorHistory` (för stress + body battery)
- Languages: `eng`, `swe`
- Unik `id` (ny UUID)

## Kända risker / öppna punkter

1. **Font-build komplexitet** — att generera egen `.fnt` från `.ttf` via Garmins font builder kan vara pillrigt. Om det blir blockerande i v1, fallback till systemfont + dokumenterad kompromiss.
2. **SensorHistory-tillgänglighet** — stress och body battery finns på Enduro 3 men värdet kan vara `null` direkt efter boot. Fallback-text ("—") måste hanteras.
3. **Radial text-stöd per device** — `drawRadialText` är officiellt tillgänglig från SDK 4.0, men några äldre enheter kan ha buggar. Testas i simulator per device.
4. **Batteri-estimat** — `batteryInDays` finns men kan vara `null` på nya enheter eller precis efter laddning. Fallback till procent (`battery`).

## Framtida förbättringar (ej v1)

- Mode-växling (vin/öl/champagne) via long-press eller settings
- Settings för att välja vilka komplikationer som visas
- Animerad "+1" när nytt glas tjänas
- Progress-ring mot nästa glas
- Egna färgteman
