# Design: KultgubbenBeerFace & KultgubbenChampagneFace

## Översikt

Två nya Garmin Connect IQ-urtavlor modellerade efter KultgubbenWineFace. Samma layout och logik — egna ikoner, färgpaletter och dryckeströsklar per app.

## Projektstruktur

Separata projekt bredvid nuvarande WineFace-repo:

```
KultgubbenBeerFace/
  source/
  resources/drawables/
  resources/strings/
  resources-swe/strings/
  manifest.xml
  monkey.jungle
  build-iq.ps1
  draw-beer.ps1          ← nytt skript för pintglas-ikon

KultgubbenChampagneFace/
  source/
  resources/drawables/
  resources/strings/
  resources-swe/strings/
  manifest.xml
  monkey.jungle
  build-iq.ps1
  draw-champagne.ps1     ← nytt skript för champagneflöjt-ikon
```

Samma målenheter som WineFace (enduro3, fenix7-serien, fr955).

## Layout

Identisk med KultgubbenWineFace:
- **Topbåge:** stress + body battery (ikon + värde längs båge)
- **Mitten:** dryckesikon (vänster-centrerad) + antal glas (siffra till höger om ikon)
- **Tid:** stor serif-font, centrerad
- **Datum:** liten serif, centrerad
- **Bottenbåge:** batteri, steg, puls

## Trösklar

| Urtavla         | Steg/glas vardag | Steg/glas fre–lör | Träningsbonus        |
|-----------------|------------------|-------------------|----------------------|
| WineFace        | 4 000            | 3 000             | +1 per 30 min vigorous |
| BeerFace        | 4 000            | 3 000             | +1 per 30 min vigorous |
| ChampagneFace   | 3 000            | 3 000             | +1 per 30 min vigorous |

ChampagneFace har alltså ingen fre/lör-bonus — 3 000 steg gäller alltid.

## Färgpaletter

### BeerFace — Amber
| Konstant         | Hex       | Användning                  |
|------------------|-----------|-----------------------------|
| COLOR_BG         | #000000   | Bakgrund                    |
| COLOR_AMBER      | #ffaa33   | Primär (ikon, antal, bågtext)|
| COLOR_AMBER_LIGHT| #ffcc55   | Tid                         |
| COLOR_AMBER_DIM  | #cc8822   | Datum                       |
| COLOR_AMBER_GRAY | #cc8833   | Bågtexter (sensor-värden)   |

### ChampagneFace — Pale Gold + Lila
| Konstant         | Hex       | Användning                  |
|------------------|-----------|-----------------------------|
| COLOR_BG         | #000000   | Bakgrund                    |
| COLOR_GOLD       | #ffe566   | Primär (ikon, antal)        |
| COLOR_GOLD_LIGHT | #fff0a0   | Tid                         |
| COLOR_GOLD_DIM   | #aa9944   | Datum                       |
| COLOR_PURPLE     | #8877bb   | Bågtexter (sensor-värden)   |

## Ikoner

Genereras med PowerShell-skript och sparas som PNG i `resources/drawables/`.

- **BeerFace:** `draw-beer.ps1` — pintglas med handtag och skumkrona (vit/krämfärgad topp)
- **ChampagneFace:** `draw-champagne.ps1` — smal champagneflöjt med stam, fot och bubblor

Ikonerna upscalas med bicubic-interpolation till 128×144 px (samma pipeline som WineFace).

## Vad som kopieras oförändrat

Följande källkod kopieras rakt av från WineFace utan logikändringar:

- `_drawTopArc` / `_drawBottomArc` / `_drawSegmentedArc` / `_drawArcIcon`
- `_drawTime` / `_drawDate`
- `_getHeartRate` / `_getSensorLatest` / `_formatSteps`
- `_isFriSat` (kopieras till BeerFace; utelämnas i ChampagneFace — 3000 steg gäller alltid)
- Font-laddning och konstanter för SERIF_FACES

## Vad som anpassas per projekt

- Färgkonstanter
- `STEPS_PER_GLASS_DEFAULT` och `STEPS_PER_GLASS_FRI_SAT`
- `_drawGlass` → `_drawBeer` / `_drawChampagne` (läser in rätt ikon-resurs)
- Ikon-PNG i resources/drawables
- App-namn i strings.xml (eng + swe)
- Launcher icon

## Övrigt

Visuell finjustering av ikoner och färger görs separat efter att urtavlorna är driftsatta och testade på enhet.
