# Lifting Tracker

Lifting Tracker este o aplicație Flutter pentru planificarea antrenamentelor,
urmărirea sesiunilor active și vizualizarea progresului.

Acest document descrie **arhitectura țintă** a proiectului. Migrarea către ea se
face gradual, astfel încât structura existentă din `lib/` poate fi temporar
diferită de cea prezentată mai jos.

## Principii

Structura proiectului urmărește patru reguli:

1. Codul este grupat în primul rând după responsabilitatea din aplicație, nu
   după tipul tehnic al fișierului.
2. Fiecare concept de business are un singur modul care îl deține.
3. Flow-urile pot combina mai multe features, fără să le copieze logica.
4. `core` conține numai cod generic, care nu cunoaște concepte precum workout,
   exercise, split sau history.

## Structura principală

```text
lib/
├── main.dart
├── app/
├── core/
├── features/
└── flows/
```

### `app/`

Conține infrastructura care pornește și asamblează aplicația:

- widget-ul rădăcină `MaterialApp`;
- navigația globală;
- shell-ul principal;
- bottom navigation;
- configurarea globală a aplicației.

Exemple:

```text
app/
├── lifting_tracker_app.dart
├── navigation/
└── shell/
    ├── main_shell.dart
    └── main_bottom_navigation.dart
```

`app` poate folosi `flows`, `features` și `core`. Celelalte module nu trebuie
să importe cod din `app`.

### `core/`

Conține infrastructură și componente complet generice:

- baza de date a aplicației;
- tema, culorile și gradienții;
- componente UI generice;
- tranziții și animații reutilizabile;
- utilitare tehnice.

```text
core/
├── database/
│   └── app_database.dart
├── theme/
│   ├── app_colors.dart
│   ├── app_gradients.dart
│   └── app_theme.dart
├── ui/
│   ├── app_bars/
│   ├── buttons/
│   ├── cards/
│   ├── modal/
│   └── transitions/
└── utils/
```

Un fișier poate intra în `core` numai dacă:

- nu conține logică de business;
- nu conține în nume un concept specific aplicației;
- poate fi înțeles fără cunoștințe despre fitness;
- nu importă nimic din `features`, `flows` sau `app`.

De exemplu, `GradientCard` poate sta în `core`, dar `WorkoutSummaryCard` nu.

### `features/`

Un feature este modulul care deține o capabilitate sau un concept de business.
Nu trebuie să corespundă unui singur ecran și poate avea zero, unul sau mai
multe ecrane.

Features principale ale aplicației sunt:

```text
features/
├── exercises/
├── plans/
├── workout/
├── history/
└── progress/
```

Responsabilitățile lor sunt:

- `exercises`: exerciții, muscle groups, căutare și selectare de exerciții;
- `plans`: split plans, split days și editarea planurilor;
- `workout`: sesiunea activă, seturi, pornirea și terminarea antrenamentului;
- `history`: sesiunile terminate și istoricul antrenamentelor;
- `progress`: weekly target, weekly progress și streak.

### `flows/`

Un flow este un proces sau ecran care combină capabilități din mai multe
features, fără să devină proprietarul lor.

```text
flows/
├── onboarding/
└── home_dashboard/
```

De exemplu, onboarding-ul folosește:

- `plans` pentru selectarea split-ului;
- `exercises` pentru selectarea exercițiilor;
- `progress` pentru weekly target.

`onboarding` deține numai ordinea pașilor, navigarea dintre ei, validarea
finalizării flow-ului și starea „setup completed”. Nu deține modelele sau
regulile interne ale feature-urilor pe care le folosește.

Similar, `home_dashboard` compune informații din `workout`, `history` și
`progress`, dar deține doar prezentarea dashboardului.

## Structura internă a unui feature

Un feature poate conține următoarele layere:

```text
features/plans/
├── domain/
├── data/
├── application/
└── presentation/
    ├── pages/
    ├── state/
    ├── view_data/
    └── widgets/
```

Nu se creează foldere goale doar pentru simetrie. Un layer apare numai când
feature-ul are cod care îi aparține.

### `domain/`

Conține conceptele și regulile de business pure:

- entities;
- value objects;
- enum-uri și stări de business;
- validări care nu depind de Flutter, Riverpod sau SQLite.

Exemple: `SplitPlan`, `SplitDay`, `Exercise`, `TrainingSet`.

### `data/`

Conține accesul la date:

- query-uri SQLite;
- citire și scriere în SharedPreferences;
- maparea rândurilor din baza de date;
- operații locale de salvare, actualizare și ștergere.

Persistența este o responsabilitate a acestui layer, nu o categorie de
provider.

### `application/`

Conține coordonarea feature-ului:

- provideri Riverpod;
- `Notifier`/`AsyncNotifier` controllers;
- acțiuni care combină mai multe operații de data access;
- state-ul feature-ului folosit de mai multe widget-uri.

Exemple: `ActiveSplitController`, `WorkoutSessionController`,
`weeklyProgressProvider`.

### `presentation/`

Conține interfața feature-ului:

- `pages/`: widget-uri care reprezintă o pagină sau o rută;
- `widgets/`: componente UI specifice feature-ului;
- `state/`: stare exclusiv vizuală, precum editing mode;
- `view_data/`: date pregătite special pentru afișare.

State-ul folosit de un singur widget rămâne, de preferat, în acel widget. Nu
orice boolean are nevoie de un provider global.

## Direcția dependențelor

Dependențele trebuie să curgă în următoarea direcție:

```text
app ───────────> flows ───────────> features ───────────> core
 │                  │                   │
 └──────────────────┴───────────────────┘
```

Reguli:

- `core` nu importă din niciun alt modul al aplicației;
- un feature nu importă niciodată dintr-un flow;
- un flow poate combina mai multe features;
- `app` asamblează aplicația și poate importa toate modulele;
- importurile circulare între features trebuie evitate;
- când două module au nevoie de același concept de business, conceptul rămâne
  în feature-ul care îl deține, iar celălalt îl consumă.

În interiorul unui feature, direcția obișnuită este:

```text
presentation ──> application ──> data
       │               │           │
       └──────────────> domain <────┘
```

Aceasta este o arhitectură pragmatică. Nu introducem repository interfaces,
use cases sau DTO-uri doar pentru a respecta formal o diagramă.

## Widget-uri reutilizabile

Un widget reutilizat în mai multe locuri nu devine automat componentă globală.
El rămâne în modulul care deține conceptul reprezentat.

Exemple:

- `GradientCard` → `core/ui/cards`;
- `SolidButton` → `core/ui/buttons`;
- `ExerciseSelector` → `features/exercises/presentation/widgets`;
- `SessionLaunchButton` → `features/workout/presentation/widgets`;
- `HistoryMonthCard` → `features/history/presentation/widgets`.

Regulă practică: dacă numele widget-ului conține `workout`, `exercise`,
`split`, `history` sau alt concept de business, el nu aparține lui `core`.

## Convenții de nume

### Fișiere și foldere

- Se folosește exclusiv `snake_case`.
- Fișierul este numit după responsabilitatea sau tipul public principal.
- Se evită nume precum `utils`, `helpers`, `aux_funcs` și `miscellaneous` atunci
  când există un nume mai precis.
- Un folder separat pentru un widget se creează numai când widget-ul formează
  o componentă complexă cu mai multe fișiere.

### Widgets

- Widget de pagină/rută: sufix `Page`, de exemplu `PlansPage`.
- Widget reutilizabil: nume după rol, de exemplu `WorkoutSummaryCard`.
- Callback: prefix `on`, de exemplu `onSave` sau `onExerciseSelected`.

### Riverpod

- Variabila providerului se termină întotdeauna în `Provider`.
- Clasa care expune acțiuni și modifică state-ul se termină în `Controller`.
- Fișierul unui controller se termină în `_controller.dart`.
- Providerii derivați mici și strâns legați pot fi grupați într-un fișier
  precum `plan_providers.dart`.

Exemplu:

```dart
final activeSplitProvider =
    AsyncNotifierProvider<ActiveSplitController, SplitPlan?>(
      ActiveSplitController.new,
    );

class ActiveSplitController extends AsyncNotifier<SplitPlan?> {
  // ...
}
```

### Modele și variabile

- Entitate de business: `SplitPlan`.
- Date agregate: `SplitPlanSummary`.
- Date create strict pentru UI: `SplitPlanViewData`.
- Reprezentare specifică bazei de date, dacă este necesară:
  `SplitPlanRecord`.
- Boolean: prefix `is`, `has`, `can` sau `should`.
- Identificator: sufix `Id`, nu `ID`.
- Colecție: nume la plural.
- Număr de elemente: `exerciseCount`, nu `nrOfExercises`.

## Alegerea folderului pentru un fișier nou

Pentru fiecare fișier nou se răspunde, în ordine, la următoarele întrebări:

1. Pornește sau configurează aplicația? → `app`.
2. Este complet generic și fără concepte de business? → `core`.
3. Deține o capabilitate sau un concept de business? → feature-ul respectiv.
4. Combină mai multe features într-un proces sau dashboard? → `flows`.
5. În interiorul modulului: este domain, data, application sau presentation?

Întrebarea finală de verificare este:

> Dacă modific această funcționalitate, care este singura zonă a aplicației în
> care m-aș aștepta să caut?

## Maparea structurii vechi

În timpul migrării, directoarele existente se mută aproximativ astfel:

| Structură veche | Destinație |
| --- | --- |
| `data/app_databases.dart` | `core/database/app_database.dart` |
| `data/animations` | `core/ui/transitions` |
| `data/queries` | `features/<owner>/data` |
| `models/entity` | `features/<owner>/domain` |
| `models/view_model` | `features/<owner>/presentation/view_data` |
| `providers/persisted` | `features/<owner>/application` sau `data` |
| `providers/presentation` | `application` sau `presentation/state` |
| `screens` | `<module>/presentation/pages` |
| `theme` | `core/theme` |
| `widgets/core` | `core/ui` |
| `widgets/<business-area>` | `<module>/presentation/widgets` |

## Reguli pentru refactor

Migrarea este structurală și nu trebuie să schimbe comportamentul aplicației.

- Se migrează un singur modul într-un commit.
- Nu se modifică simultan structura, SQL-ul și comportamentul providerilor.
- Se păstrează proiectul compilabil după fiecare etapă.
- După fiecare etapă se rulează:

```shell
dart format lib
flutter analyze
flutter test
```

- Fluxurile principale sunt verificate manual după mutări importante.
- Orice excepție de la regulile documentului trebuie să aibă un motiv clar,
  nu doar faptul că un fișier este utilizat în mai multe locuri.
