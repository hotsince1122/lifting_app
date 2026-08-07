# Testing Guide

## Rolul documentului

Acesta este ghidul persistent pentru invatarea, scrierea si rularea testelor in
proiect.

Documentul este separat de planurile feature-urilor. Un plan de feature descrie
ce construim si progresul implementarii; acest ghid descrie cum alegem, scriem
si rulam testele.

Orice task care adauga sau modifica teste trebuie sa citeasca:

1. `AGENTS.md` pentru regulile generale de verificare;
2. planul feature-ului la care lucreaza;
3. acest document pentru strategia si comenzile de testare.

Documentul se actualizeaza cand proiectul adopta un nou tipar de testare, o
dependenta noua pentru teste sau o comanda noua verificata in workspace.

**Status:** active

**Ultima actualizare:** 2026-08-08

## Mod de lucru didactic

- Testarea este invatata si implementata incremental in fiecare etapa, nu
  adaugata la finalul unui feature.
- Codex explica ce comportament merita testat, ce nivel de test este potrivit
  si de ce, apoi utilizatorul incearca sa scrie testul.
- Codex poate oferi scheletul si fragmentele dificile ale unui test, dar nu
  livreaza implicit intreaga suita de teste gata de copiat.
- O etapa poate deveni `done` numai dupa ce au fost identificate si rulate
  testele relevante pentru comportamentul introdus.
- La finalul fiecarui task se raporteaza separat formatter-ul, analyzer-ul si
  testele.

## Modelul de baza: Arrange, Act, Assert

Primul model folosit este Arrange, Act, Assert:

1. **Arrange:** construim starea initiala si dependentele;
2. **Act:** executam o singura actiune relevanta;
3. **Assert:** verificam rezultatul observabil.

Exemplu minimal:

```dart
test('descrie comportamentul verificat', () {
  // Arrange
  final initialState = ...;

  // Act
  final result = initialState.someAction();

  // Assert
  expect(result, expectedValue);
});
```

Testele primesc nume care descriu comportamentul, nu implementarea interna. Un
test trebuie sa esueze atunci cand comportamentul promis este stricat, nu doar
cand se schimba structura codului.

Nu este obligatoriu sa folosim strict TDD pentru fiecare widget. Pentru logica
pura, parsare, validare si reguli de restore vom incerca frecvent sa scriem
testul inaintea implementarii. Pentru explorarea initiala a unui flow UI putem
implementa incremental si adauga testul imediat dupa stabilizarea
comportamentului.

## Organizarea fisierelor

Testele urmaresc structura din `lib` si folosesc sufixul `_test.dart`.

Exemplu:

```text
lib/features/example/domain/something.dart
test/features/example/domain/something_test.dart
```

Testul existent
`test/features/rest_timer/domain/rest_timer_state_test.dart` este primul exemplu
de unit test din proiect.

## Nivelurile pe care le vom invata

### 1. Unit tests

Testeaza o unitate mica fara Firebase real, retea sau UI.

Exemple pentru autentificare si cloud backup:

- validarea emailului si a parolei, daca regulile apartin aplicatiei;
- controller-ul de autentificare folosind un fake al contractului de Auth;
- serializarea si deserializarea snapshot-ului;
- respingerea unei versiuni de backup nesuportate;
- validarea metadata-ului si a checksum-ului;
- politica pentru `backupPending`.

Testul existent pentru `RestTimerState` construieste o stare, executa o actiune
si verifica rezultatul cu `expect`.

### 2. Widget tests

Testeaza comportamentul UI intr-un mediu Flutter controlat.

Exemple pentru autentificare si cloud backup:

- formularul afiseaza erorile potrivite;
- butonul de submit este dezactivat sau arata loading la momentul corect;
- utilizatorul poate continua ca guest;
- warning-ul pentru progres neprotejat este afisat;
- dialogul de conflict ofera `Keep local data` si
  `Replace with cloud backup`;
- UI-ul afiseaza ultimul backup reusit si starea pending.

Vom invata gradual `testWidgets`, `pumpWidget`, `find`, `tap`, `enterText` si
`pump`/`pumpAndSettle`.

### 3. Integration tests

Verifica mai multe layere impreuna si necesita uneori device, emulator sau o
baza de date reala.

Exemple pentru autentificare si cloud backup:

- exportul urmat de import reconstruieste aceleasi date SQLite;
- un import invalid face rollback complet;
- login-ul folosind Firebase Auth Emulator produce sesiunea asteptata;
- upload-ul si download-ul unui snapshot functioneaza cu serviciile Firebase
  emulate;
- flow-ul de reinstalare este verificat end-to-end.

Nu vom incepe direct cu aceste teste. Mai intai invatam unit tests si widget
tests, care sunt mai rapide si localizeaza mai bine cauza unui esec.

### 4. Security Rules tests

Storage Rules trebuie verificate separat, ideal cu Firebase Emulator Suite:

- un utilizator isi poate citi si scrie propriul backup;
- nu poate accesa backup-ul altui UID;
- un request neautentificat este respins;
- un fisier peste limita este respins;
- o cale sau un content type nepermis este respins.

Aceste teste nu sunt inlocuite de testele Flutter, deoarece valideaza reguli
executate de infrastructura Firebase.

## Test doubles

Unit tests pentru controllere nu apeleaza Firebase real. Definim contracte mici
si folosim:

- **fake:** implementare simpla, functionala, tinuta in memorie;
- **stub:** returneaza un rezultat pregatit pentru un scenariu;
- **mock:** verifica interactiuni precise, folosit numai cand acele interactiuni
  sunt comportamentul important.

Vom prefera initial fake-uri scrise manual. Sunt mai usor de inteles decat un
framework de mocking si fac dependentele arhitecturii vizibile.

### Testarea unui StreamProvider Riverpod

Pentru auth state, testul inlocuieste `authRepositoryProvider` cu un
`FakeAuthRepository` care returneaza un stream controlat. Astfel testam
contractul dintre repository si provider fara Firebase real, retea sau
credentiale.

Tiparul verificat in proiect este:

```dart
final container = ProviderContainer.test(
  overrides: [authRepositoryProvider.overrideWithValue(fakeRepository)],
);

container.listen(authStateProvider, (_, _) {});

final actualUser = await container.read(authStateProvider.future);
```

In Riverpod 3, simpla citire a proprietatii `.future` nu tine neaparat activ un
`StreamProvider` fara consumator. `container.listen(...)` simuleaza observarea
facuta de un widget prin `ref.watch`, porneste stream-ul si il pastreaza activ
pana cand valoarea asteptata este emisa.

Pentru auth foundation verificam cel putin ambele stari ale contractului:

- un `AuthUser` emis de repository este expus consumatorilor;
- valoarea `null` este expusa pentru utilizatorul guest/sign out.

### Testarea unui AsyncNotifier de operatii

Pentru un controller de operatii, provider-ul este initializat explicit, apoi
testul apeleaza notifier-ul si citeste `AsyncValue` rezultat:

```dart
final container = ProviderContainer.test(
  overrides: [authRepositoryProvider.overrideWithValue(fakeRepository)],
);

await container.read(authControllerProvider.future);
final controller = container.read(authControllerProvider.notifier);

await controller.someOperation();

final state = container.read(authControllerProvider);
```

Un `FakeAuthRepository` reutilizabil poate inregistra numarul apelurilor si
argumentele primite. Poate primi si o exceptie pregatita, pentru a verifica daca
aceeasi eroare ajunge in `AsyncError` fara Firebase real.

Pentru o operatie pending folosim un `Completer<void>`. Future-ul fake-ului
ramane nefinalizat pana la `completer.complete()`, permitand testului sa observe
starea loading si sa verifice daca un al doilea submit este ignorat.

Cand controller-ul foloseste `AsyncValue.guard`, eroarea este pastrata in
starea provider-ului; metoda asincrona nu o arunca din nou catre test. Testul
verifica `state.hasError`, tipul lui `state.error` si, cand este relevant,
codul tipizat din exceptie.

## Comenzi pentru acest workspace

Comanda Flutter obisnuita este:

```powershell
flutter test
```

In acest workspace, wrapper-ele Flutter pot ramane blocate. Varianta preferata
apeleaza Flutter Tool prin executabilul Dart.

### Toate testele

```powershell
& "C:\tools\flutter\bin\cache\dart-sdk\bin\dart.exe" `
  "C:\tools\flutter\bin\cache\flutter_tools.snapshot" `
  --suppress-analytics test
```

### Un singur fisier

```powershell
& "C:\tools\flutter\bin\cache\dart-sdk\bin\dart.exe" `
  "C:\tools\flutter\bin\cache\flutter_tools.snapshot" `
  --suppress-analytics test `
  "test\features\rest_timer\domain\rest_timer_state_test.dart"
```

### Un singur test ales dupa nume

```powershell
& "C:\tools\flutter\bin\cache\dart-sdk\bin\dart.exe" `
  "C:\tools\flutter\bin\cache\flutter_tools.snapshot" `
  --suppress-analytics test `
  "test\features\rest_timer\domain\rest_timer_state_test.dart" `
  --name "restores an expired timer as idle"
```

### Coverage

```powershell
& "C:\tools\flutter\bin\cache\dart-sdk\bin\dart.exe" `
  "C:\tools\flutter\bin\cache\flutter_tools.snapshot" `
  --suppress-analytics test --coverage
```

Coverage-ul este un indicator, nu obiectivul principal. Prioritatea este sa
testam riscurile si comportamentele importante, nu sa urmarim artificial un
procent de 100%.

Flutter Tool scrie un lockfile in SDK. Intr-un mediu Codex restrictionat,
rularea testelor poate necesita aprobarea accesului in afara workspace-ului;
in terminalul local al utilizatorului comenzile de mai sus nu ar trebui sa
necesite aceasta aprobare suplimentara.

## Intrebari deschise despre infrastructura de testare

1. Pentru testele SQLite folosim o baza reala pe device/emulator sau adaugam
   ulterior `sqflite_common_ffi` pentru teste locale?
2. In ce etapa introducem Firebase Emulator Suite pentru Auth, Storage si
   verificarea Security Rules?
3. Avem nevoie de o librarie de mocking sau fake-urile manuale raman suficiente
   pentru primele feature-uri testate?
4. Ce praguri sau rapoarte de coverage ar aduce valoare reala proiectului?

Aceste intrebari se decid numai cand etapa curenta are nevoie de ele. Nu adaugam
dependente de testare anticipat.

## Testing Log

### 2026-08-08 - Auth 02: validare, mapper si controller async

- Regulile locale pentru email, parola si confirmare au fost testate ca functii
  pure, folosind Arrange, Act, Assert.
- Maparea codurilor `FirebaseAuthException` a fost testata table-driven. Fiecare
  cod genereaza un test separat, iar codurile necunoscute devin
  `AuthErrorCode.unknown`.
- `FakeAuthRepository` a fost extras intr-un test double reutilizabil, cu
  inregistrarea apelurilor, eroare configurabila si future controlabil.
- Testele `AuthController` folosesc `ProviderContainer.test`, provider override,
  `AsyncValue` si `Completer<void>` pentru a verifica success, validation error,
  repository error, loading si prevenirea submit-urilor duplicate.
- Nu au fost folosite Firebase real, retea sau Firebase Auth Emulator.
- Testele focalizate de authentication au trecut: 29 din 29.
- Suita completa a trecut: 36 din 36.

**Urmatorul pas:** pentru `Auth 03`, fake-ul existent va fi extins numai cu
comportamentul Google Sign-In si provider linking care trebuie observat. Nu se
introduce un framework de mocking anticipat.

### 2026-08-07 - Auth state cu fake si provider override

- A fost adaugat un `FakeAuthRepository` manual, fara framework de mocking.
- `authRepositoryProvider` a fost suprascris intr-un `ProviderContainer.test`,
  astfel incat testele sa nu initializeze Firebase real.
- A fost documentata necesitatea unui listener pentru `StreamProvider` in
  testele Riverpod 3.
- Au fost verificate emiterea unui `AuthUser` si emiterea valorii `null` pentru
  starea guest.
- Testul focalizat de autentificare a trecut.
- Suita completa a trecut: 9 teste din 9.

**Urmatorul pas:** in `Auth 02`, testele vor acoperi regulile aplicatiei pentru
email/parola si comportamentul operatiilor prin fake-ul repository-ului.

### 2026-08-05 - Strategie initiala

- Au fost definite nivelurile invatate gradual: unit, widget, integration si
  Security Rules tests.
- A fost stabilita preferinta initiala pentru fake-uri manuale in unit tests,
  fara apeluri reale catre Firebase.
- Au fost documentate comenzile PowerShell potrivite pentru rularea Flutter Tool
  fara wrapper-ul `flutter.bat`.
- Testul focalizat
  `test/features/rest_timer/domain/rest_timer_state_test.dart` a fost rulat.
- Rezultat: toate cele 7 teste au trecut.

**Urmatorul pas:** primul test nou va fi scris impreuna cu prima regula de
autentificare care apartine aplicatiei, nu SDK-ului Firebase.
