# Exercise Progress

## Rolul documentului

Document de planificare si handoff pentru progresul pe exercitii.
Se citeste impreuna cu `AGENTS.md`, codul ariei modificate si, pentru teste,
`docs/testing/testing_guide.md`.

**Status general:** planning; scope-ul detaliat nu este inca agreat.
**Ultima actualizare:** 2026-10-22.

Doar sectiunea `Cerinte confirmate` reprezinta decizii ale utilizatorului.
Restul documentului este o propunere initiala pentru discutie, nu autorizatie
pentru implementarea modificarilor de navigare, modele sau provideri.

## Cerinte confirmate

- Un ecran important al aplicatiei, accesibil din bottom navigation bar.
- Utilizatorul poate vedea progresul fiecarui exercitiu efectuat, printr-un chart.
- Simplitatea este o cerinta de produs: selectie de exercitiu si putine moduri
  de chart, fara dashboard sau numeroase optiuni.
- Metrica de baza: greutatea maxima ridicata intr-o sesiune pentru exercitiul ales.
- Pentru greutate x repetari, utilizatorul prefera evolutia celui mai bun set,
  definit prin produsul maxim, in locul sumei produselor tuturor seturilor.
- Utilizatorul a acceptat directia cu trei moduri: Max weight, Best set si
  All sets. Primele doua au un punct per sesiune; All sets arata produsul per set,
  in ordine, fara warm-up-uri.
- Flow-ul ales: Progress -> toate grupele musculare -> toate exercitiile grupei
  -> pagina de chart, cu selectorul modului sus.
- Pagina de chart este in landscape, cu telefonul rotit, conform clarificarii
  explicite a utilizatorului. Pagina nu este doar un chart lat in portrait.
- Utilizatorul doreste acces direct din iconita chart a exercitiului din workout
  editor, fara trecere prin grupele din Progress.
- In Progress afisam momentan sapte grupe; Cardio este exclus pana cand
  aplicatia poate salva date specifice cardio.
- Cardurile grupelor nu au iconita repetata: numele este elementul principal,
  iar chevron-ul este aliniat cu textul la capatul cardului.
- Pentru chart-urile Flutter folosim Syncfusion Charts. Best set este modul
  implicit din mock-up-ul acceptat.
- Favoritele si mini-chart-urile din Home / Progress Spotlight sunt o extensie
  propusa de utilizator, aflata in discutie; persistenta si UX-ul nu sunt alese.
- Feature-ul este planificat ca ultimul feature mare inainte de polish.
- Colaborarea urmeaza stilul didactic al planului de authentication/cloud backup:
  explicatie, alegerea solutiei, implementare incrementala si review.

## Situatia actuala verificata in cod

- `main_bottom_navigation.dart` contine deja butonul Progress cu indexul 3.
  `main_shell.dart` accepta numai trei tab-uri si nu contine pagina Progress.
- `features/progress` gestioneaza deja targetul saptamanal, prezenta si streak-ul.
- SQLite pastreaza in `logged_sets`: exercitiu, sesiune, greutate, repetari,
  warm-up, ordinea setului si aparitia exercitiului in sesiune.
- `workout_sessions` pastreaza statusul si momentele de inceput/finalizare.
  Timestamp-urile sunt salvate in secunde Unix.
- Finalizarea copiaza seturile cu actual_weight si actual_repetitions nenule
  din `active_session_sets` in `logged_sets`. Nenul nu inseamna automat pozitiv.
- Istoricul permite editarea si stergerea antrenamentelor.
- Exercitiile au ID stabil, nume si grupa musculara. Nu exista camp care sa
  distinga greutate externa, bodyweight sau asistenta, desi catalogul le include.
- Backup-ul include deja exercitiile, sesiunile si seturile salvate.
- `ProgressSpotlight` din Home este in prezent un placeholder.
- `ExerciseTileFooter` contine iconite chart si star, dar fara actiuni proprii.
  Overlay-ul actual pentru Add Set acopera intreaga zona de footer.
- `main.dart` solicita global `DeviceOrientation.portraitUp` la pornire.
- `MuscleGroups.names` si selectorul existent ofera deja grupele. Widget-ul
  existent de exercitii este legat de selectarea/editarea pentru workout;
  nu se reutilizeaza comportamentul lui de navigare fara adaptare.
- `pubspec.yaml` nu include inca o biblioteca dedicata chart-urilor.

## Flow ales si detalii propuse

1. Utilizatorul deschide tab-ul Progress.
2. Vede toate grupele musculare si selecteaza una.
3. Vede toate exercitiile grupei si selecteaza unul. Pagina de chart se deschide
   in landscape, cu selectorul modului sus si chart-ul ocupand spatiul principal.
4. Selectarea unui punct actualizeaza valoarea si contextul: data, greutate,
   repetari si, pentru modul toate seturile, sesiunea si numarul setului.

Acest flow inlocuieste recomandarea anterioara selector + chart direct in tab.
Propunere: exercitiile fara istoric raman vizibile cu un indiciu discret si
deschid un empty state. O grupa fara exercitii are propriul empty state.

### Aceeasi pagina de chart din mai multe locuri

- Progress: grupa -> exercitiu -> chart -> Back la lista de exercitii.
- Workout editor: iconita chart -> chart -> Back la acelasi editor, cu seturile,
  pozitia si sesiunea pastrate. Nu schimbam tab-ul activ pentru aceasta scurtatura.
- Home (daca favoritele sunt incluse): mini-chart -> chart -> Back la Home.
- Pagina primeste exercise ID; interogarile si calculele sunt comune celor trei
  puncte de intrare. Nu cream trei implementari ale progresului.
- Chart-ul citeste istoricul finalizat. Seturile workout-ului activ nu devin
  puncte istorice doar pentru ca deschidem chart-ul din editor.

### Landscape

- Propunere: pagina fullscreen, fara bottom navigation, cu Back/Close, numele
  exercitiului si selectorul celor trei moduri in partea de sus.
- Orientarea landscape este limitata la pagina de chart. La revenire se
  restabileste portrait, inclusiv pentru Back de sistem si inchiderea prin gest.
- Deschiderea din editor trebuie verificata si cu tastatura deschisa / un camp
  editat; nu trebuie pierduta ultima valoare sau oprita sesiunea/rest timer-ul.
- Detaliile orientarii si restrictiile platformelor se verifica la implementare
  pe dispozitivele tinta; nu presupunem ca orice device onoreaza blocarea.

### Favorite si Progress Spotlight — propunere in discutie

- Favoritul apartine exercise ID, nu unui set sau unei aparitii in workout.
- Aceeasi stare a stelei este vizibila in editor si pagina de chart.
- Recomandare UI: un mini-chart vizibil odata, swipe intre favorite si indicator
  de pozitie; Home nu creste cu o lista nelimitata de chart-uri.
- Recomandare: mini-chart-ul foloseste mereu Best set, cu nume si ultimul set
  relevant; nu adaugam selector de metrica separat in Home.
- Fara favorite: invitatie de a marca un exercitiu. Favorit fara istoric:
  mesaj explicit, fara trend inventat. Tap deschide pagina comuna de chart.
- Varianta basic: lista de ID-uri in preferinte locale, cu filtrarea ID-urilor
  inexistente dupa restore. Mai putina implementare, dar favoritele nu sunt
  recuperate automat prin backup-ul actual.
- Varianta recomandata daca favoritele trebuie restaurate: persistenta SQLite
  legata de exercitii si includere in snapshot; necesita actualizarea schemei,
  validarii si compatibilitatii cu backup-urile existente. Formatul exact se
  decide separat. Chart-urile in sine raman date derivate.
- Aceasta persistenta noua este separata de calculele de progress si se
  implementeaza dupa stabilizarea paginii si a scurtaturii din editor.

## Metricile si semnificatia lor

Cele trei moduri au fost acceptate ca directie de produs.

| Mod | Calcul | Limita de interpretare |
| --- | --- | --- |
| Max weight | MAX(weight) per sesiune | Nu arata cresterea repetarilor la aceeasi greutate |
| Best set | MAX(weight * repetitions) per sesiune | Cel mai mare produs nu inseamna automat cea mai mare forta sau cel mai eficient stimul |
| All sets | weight * repetitions pentru fiecare set, in ordine | Arata variatia intre seturi, nu doar evolutia intre antrenamente |

Exemplu: 60 kg x 8 -> 60 kg x 12 lasa chart-ul greutatii maxime neschimbat.
Best set creste daca trecem de la 80 x 8 = 640 la 80 x 10 = 800, fara a fi
influentat de simpla adaugare a unui set identic. Totusi, 60 x 12 = 720 depaseste
80 x 8 = 640. Afisam si perechea greutate/repetari, nu doar produsul.

Greutate x repetari este un volum de incarcare pe set, nu o masura a timpului
sub tensiune. Aplicatia nu inregistreaza durata repetarilor sau a fiecarui set.
Etichetele nu trebuie sa promita masurarea hipertrofiei ori a calitatii executiei.
Nu adaugam repetari maxime, volum total sau estimated 1RM ca moduri suplimentare.

Pentru All sets, recomandarea de discutat este un punct per set si separatoare
intre sesiuni, fara o linie continua intre antrenamente. Axa X reprezinta ordinea
seturilor, nu distante calendaristice. Punctele nu se comprima pe un singur ecran
pentru intregul istoric: se foloseste o fereastra vizibila cu acces la datele vechi.
Numarul initial de puncte si interactiunea raman de ales.

Pentru bodyweight si exercitii asistate trebuie stabilit ce reprezinta `weight`.
Nu deducem tipul doar din nume sau dintr-o valoare zero si nu interpretam automat
o valoare mai mare drept imbunatatire. Nu generam procente sau mesaje de progres
pozitiv pana cand sensul comparatiei este definit.

## Variante de implementare pentru discutie

### A. Varianta incrementala pe schema existenta — recomandarea initiala

Flow: SQLite -> query-uri dedicate -> modele de rezultate si calcule ->
provideri Riverpod -> lista si chart.

- Extinde `features/progress` cu date derivate, fara tabela separata de rezultate.
- Citeste valorile inregistrate si afiseaza metrici cu denumiri explicite.
- Nu clasifica automat cresterea/scaderea drept imbunatatire/regres.
- Avantaje: foloseste istoricul existent, functioneaza offline, nu necesita
  schimbarea formatului de backup pentru aceste date derivate. Persistenta
  favoritelor este o extensie separata si poate necesita schema/backup noi.
- Limite: semantica exercitiilor asistate/bodyweight ramane limitata de modelul
  actual; nu promite o interpretare automata universala a performantei.
- Complexitate: query-uri, agregare, stare de selectie, chart si refresh.
- Potrivita daca scopul este explorarea clara a istoricului personal.

Aceasta varianta poate fi pregatita pentru productie prin reguli corecte,
teste, accesibilitate si refresh verificat; scope redus nu inseamna calitate redusa.

### B. Varianta extinsa cu tipuri explicite de tracking

Flow: definirea tipului exercitiului -> introducerea consecventa a datelor ->
salvare -> calcule si interpretari specifice tipului -> chart.

- Afecteaza catalogul, modelul exercitiului, formularul de exercitii, editorul
  workout-ului, SQLite si contractele/validarea/compatibilitatea backup-urilor.
- Avantaje: permite semnificatii explicite pentru asistenta, greutate adaugata
  si repetari, plus mesaje de progres adaptate.
- Cost: trebuie decisa clasificarea exercitiilor existente si cum sunt tratate
  valorile istorice ambigue; un camp nou nu repara automat istoricul.
- Este o schimbare de model invaziva si necesita o alegere explicita.
- Merita daca interpretarea automata corecta pentru aceste tipuri este o
  cerinta de lansare. Nu se adauga implicit pentru simpla afisare a chart-ului.

## Reguli propuse pentru date si chart

- Sursa: seturile salvate ale sesiunilor completed, cu finished_at nenul.
  Sesiunile active si hint-urile nu contribuie.
- Excluderea warm-up-urilor din metricile principale; regula trebuie confirmata.
- Identitate prin exercise ID. Numele egale cu ID-uri diferite nu se combina
  automat. Se includ toate aparitiile exercitiului din sesiunile eligibile.
- Max weight si Best set au cate un punct per sesiune. Doua sesiuni cu acelasi
  exercitiu in aceeasi zi raman doua puncte distincte. Punctul pastreaza
  identitatea setului sursa pentru context; data singura nu identifica punctul.
- All sets pastreaza fiecare set individual si ordinea prin
  started_at, session ID, exercise order, set index si set ID.
- Propunere: started_at pentru data punctului si filtrare, afisat in ora locala;
  ordonare determinista prin started_at si session ID.
- Repetarile zero si valorile invalide necesita o regula explicita de excludere.
  Greutatea zero nu se exclude global: poate avea sens pentru bodyweight.
- Nu adaugam puncte cu valoare zero pentru zile fara antrenament.
- Fara date: empty state; un singur punct: valoare afisata fara trend inventat.
- Propunere pentru UI simplu: ultimele 12 zile cu date pentru modurile agregate,
  cu acces prin derulare la istoricul anterior, fara selector de perioade.
  Numarul de puncte si navigarea in istoric nu sunt confirmate.
- Refresh dupa finalizare, editare, stergere si restore, inclusiv cand exercitiul
  selectat dispare dupa restore. Esuarea incarcarii are feedback si retry.
- Datele chart-ului raman derivate; nu se includ separat in backup.
- Un sumar de record trebuie sa spuna daca este pe interval sau pe tot istoricul.

## Arii si fisiere probabil afectate

Pentru varianta A, dupa confirmarea scope-ului:

- `lib/features/progress/{domain,data,application,presentation}/`: modelele de
  rezultate, query-urile, calculele, providerii, pagina si widget-urile noi.
- `lib/app/shell/main_shell.dart`: conectarea paginii si a app bar-ului.
- `lib/app/shell/main_bottom_navigation.dart`: numai daca UX-ul ales necesita ajustari.
- `lib/features/workouts/application/active_session_lifecycle_controller.dart`:
  refresh dupa salvarea workout-ului.
- `lib/features/history/application/history_workout_actions_controller.dart`:
  refresh dupa editare/stergere.
- `lib/features/cloud_backup/application/invalidate_restored_data.dart`:
  invalidarea datelor de progress dupa restore.
- `pubspec.yaml`: dependenta Syncfusion Charts, cand incepe UI-ul chart-ului.
- `test/features/progress/` si testele punctelor de integrare afectate.
- `lib/features/workouts/presentation/widgets/exercise_card_components/exercise_tile_footer.dart`
  si `workout_exercise_card.dart`: actiuni distincte Add Set / chart / star.
- `lib/main.dart` si pagina noua de chart: analiza politicii actuale de
  orientare si integrarea lifecycle-ului landscape, fara deblocarea globala implicita.

Daca se includ favoritele: `ProgressSpotlight`, eventual layout-ul Home,
persistenta si providerii favoritelor. Daca se alege SQLite cu backup, sunt
afectate si `app_database.dart`, snapshot/validare/import/export si testele lor.

Nu este necesara acum o alegere intre biblioteci de chart. O evaluam dupa ce
stim interactiunile, accesibilitatea si volumul de date asteptat. Indexurile SQL
si optimizarile se justifica prin query-uri si verificari de performanta.

## In afara scope-ului propus initial

- Scor global de fitness, coaching sau predictii de progres.
- Comparatii intre utilizatori sau intre exercitii diferite.
- Greutate corporala, masuratori si fotografii de progres.
- Recorduri persistate separat, notificari sau celebrari de PR.
- Alte modificari de Home, in afara integrarii favoritelor propuse.
- Schimbari in live sync sau mecanismul de backup.

## Roadmap propus

| Etapa | Rezultat verificabil | Status |
| --- | --- | --- |
| Progress 00 - Product scope | Flow, metrici, tipuri de exercitii si reguli confirmate | in progress |
| Progress 01 - Data and calculations | Query, agregari si modele; testele sunt amanate la finalul feature-ului | in progress |
| Progress 02 - Application state | Selectie exercitiu/mod, loading/error si refresh testate | not started |
| Progress 03 - Navigation and exercise selection | Grupe -> exercitii, cu empty states | not started |
| Progress 04 - Charts | Trei moduri, pagina landscape comuna si navigare in istoric | not started |
| Progress 05 - Workout shortcut | Chart direct din editor, Back fara pierderea starii | not started |
| Progress 06 - Favorites and Spotlight | Optional, dupa alegerea persistentei si UX-ului | not started |
| Progress 07 - Release verification | Edit/delete/restore, orientare, accesibilitate si istoric mare verificate | not started |

La cererea explicita a utilizatorului din 2026-10-22, testele feature-ului sunt
notate acum si vor fi scrise/rulate la finalul implementarii. Aceasta alegere
se aplica acestui feature si are prioritate fata de recomandarea generala de
testare incrementala din ghid. Pana atunci, etapele nu se marcheaza `done`
doar pe baza review-ului codului sau a analyzer-ului. Chart-ul are si o
alternativa textuala pentru valori.

### Teste de recuperat la final

- SQLite real: query-ul intoarce doar seturile exercitiului cerut, din sesiuni
  completed cu finished_at; exclude active, alte exercitii si warm-up-uri.
  Verifica ordinea, sesiuni cu acelasi timestamp, conversia secundelor Unix,
  greutati intregi/zecimale si rezultatul gol.
- Calcul pur Max weight: un punct per sesiune, inclusiv doua sesiuni in aceeasi
  zi, ordine cronologica si selectie determinista la egalitate.
- Calcul pur Best set: maximul `weight * repetitions` al unui singur set per sesiune,
  fara suma seturilor; pastreaza setul sursa pentru greutate si repetari.
- All sets: toate seturile eligibile in ordine, grupate pe sesiuni, cu punctele
  si delimitatoarele corecte pentru aparitii repetate ale aceluiasi exercitiu.
- Cazuri limita pentru toate modurile: fara date, un singur punct, repetari zero,
  greutate zero si istorice mari; regulile pentru zero trebuie stabilite inainte.
- Widget/navigation: grupe -> exercitii -> chart, schimbarea modului, selectarea
  punctelor, empty states, iesirea din landscape si revenirea la pagina sursa.
- Editor: acces direct la chart si revenire fara pierderea seturilor sau starii
  sesiunii; actiunile Add Set / chart / star au zone distincte.
- Favorite/Spotlight: persistenta aleasa, sincronizarea stelelor, swipe-ul,
  empty state fara favorite si favorit fara istoric; restore-ul este verificat
  daca favoritele sunt incluse in snapshot.
- Refresh dupa workout finalizat, editare, stergere si restore; verificare manuala
  pe device pentru landscape, scroll, axa Y fixa, lizibilitate si istoric mare.

## Intrebari deschise

1. Includem favoritele in backup? Acceptam carousel-ul
   cu mini-chart Best set in Spotlight?
2. Cum navigam istoricul si cate puncte sunt vizibile initial?
3. Confirmam excluderea warm-up-urilor si pentru cele doua moduri agregate,
   data punctului, regulile pentru valori zero si departajarea produselor egale?
4. Cum prezentam limitele datelor bodyweight/asistate fara a extinde inutil scope-ul?

## Protocol de lucru si handoff

- Utilizatorul implementeaza in principal; Codex explica mecanismul si face review.
- Propunerile devin decizii numai dupa confirmarea utilizatorului si se muta
  intr-o sectiune dedicata de decizii confirmate.
- Fiecare etapa explica fisierele afectate si are verificari proprii.
- La finalul task-ului se actualizeaza statusul, log-ul si urmatorul pas.
- Formatter-ul se ruleaza numai pe fisierele Dart modificate, folosind dart.exe
  direct; analyzer-ul si testele se raporteaza separat, conform AGENTS.md.

## Implementation Log

### 2026-10-22 - Granularitate per sesiune

- Utilizatorul a ales ca Max weight sa reprezinte fiecare sesiune, iar Best set
  sa foloseasca aceeasi granularitate. Doua antrenamente in aceeasi zi produc
  doua puncte. Decizia inlocuieste propunerea initiala per zi.
- Functia `maxWeightSetsByDay` implementata de utilizator grupeaza in prezent
  per sesiune; inainte de folosire, numele trebuie aliniat cu comportamentul.
- Fisier modificat in acest task: doar planul. Formatter: nu este necesar.
  Analyzer si teste: nerulate pentru schimbarea de documentatie; testele
  feature-ului raman amanate conform cererii utilizatorului.

**Urmatorul pas:** functia pura Best set per sesiune.

### 2026-10-22 - Query initial si amanarea testelor

- Utilizatorul a implementat modelul `ExerciseProgressSet` si query-ul
  `loadExerciseProgressSets`. Review-ul query-ului a corectat filtrarea,
  coloanele si conversiile; formatter-ul si analyzer-ul au trecut la ultima
  verificare. SQL-ul nu a fost inca executat intr-un test.
- Utilizatorul a cerut explicit ca toate testele pentru Progress sa fie notate
  si realizate la finalul feature-ului. Lista este in sectiunea de mai sus.
- Confirmate Syncfusion Charts, excluderea Cardio si directia cardurilor de
  grupe fara iconita repetata.
- Fisier modificat in acest task: numai acest plan. Formatter: nu este necesar.
  Analyzer: nerulat pentru documentatie. Teste: nerulate la cererea utilizatorului.

**Urmatorul pas:** functia pura pentru Max weight pe zi, implementata de utilizator.

### 2026-10-17 - Grupe, pagina landscape si puncte de acces

- Acceptata directia celor trei moduri. Utilizatorul a ales navigarea prin
  grupe si exercitii si a clarificat explicit orientarea landscape.
- Adaugat accesul direct din workout editor si propunerea de favorite/Spotlight.
- Verificate iconitele existente si overlay-ul Add Set, politica portrait
  din main.dart si placeholder-ul Spotlight.
- Persistenta favoritelor, mini-chart-ul implicit si modul initial al paginii
  raman de ales. Nu sunt implementate navigare, orientare sau modele noi.
- Doar documentatie modificata. Formatter: nu este necesar. Analyzer: nerulat.
  Teste: nerulate.

**Urmatorul pas:** stabilirea scope-ului favoritelor si a modului implicit.

### 2026-10-17 - Scope simplificat si preferinta pentru Best set

- Utilizatorul prioritizeaza selectarea unui exercitiu si putine moduri de chart.
- Greutatea maxima pe zi si produsul maxim greutate x repetari sunt directia
  curenta; volumul total si repetarile maxime nu mai sunt moduri propuse.
- All sets fara warm-up este o idee optionala. Afisarea produsului per set,
  separatoarele intre sesiuni si navigarea in istoric sunt propuneri Codex.
- Revizuita recomandarea UI la selector + chart pe aceeasi pagina.
- Doar documentatie modificata. Formatter: nu este necesar. Analyzer: nerulat.
  Teste: nerulate.

**Urmatorul pas:** alegerea includerii All sets si a granularitatii Best set.

### 2026-10-17 - Draft initial de produs si planificare

- Citite planul auth/cloud backup si codul relevant pentru schema, navigare,
  finalizare/editare/stergere workout si invalidarea datelor dupa restore.
- Documentate cerintele exprimate si propunerile inca neconfirmate.
- Fisier adaugat: doar acest document. Implementarea aplicatiei nu este modificata.
- Formatter: nu este necesar. Analyzer: nerulat. Teste: nerulate (doar documentatie).

**Urmatorul pas:** discutarea flow-ului si a metricilor cu utilizatorul.
