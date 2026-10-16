# Authentication and Cloud Backup

## Rolul documentului

Acesta este documentul principal de planificare si handoff pentru feature-urile
de autentificare si cloud backup.

Orice task Codex care lucreaza la aceste feature-uri trebuie sa citeasca, in
aceasta ordine:

1. `AGENTS.md` pentru regulile generale ale proiectului;
2. acest document pentru deciziile, statusul si contextul feature-urilor;
3. codul existent din aria care urmeaza sa fie modificata.

Documentul trebuie actualizat la finalul fiecarui task care ia o decizie sau
modifica implementarea. Conversatiile sunt context temporar; acest fisier este
sursa persistenta de adevar pentru feature.

**Status general:** in progress

**Ultima actualizare:** 2026-10-15

## Obiectiv

Aplicatia va primi doua feature-uri legate, dar separate:

1. autentificarea utilizatorului;
2. backup si restore al progresului in cloud.

Aplicatia ramane local-first si complet utilizabila offline. Autentificarea nu
este obligatorie, iar cloud-ul nu devine baza de date operationala a
aplicatiei.

## Principii care nu trebuie incalcate

- SQLite ramane sursa de adevar pentru folosirea curenta a aplicatiei.
- Toate query-urile si toate modificarile de workout, plan, istoric si progres
  sunt efectuate local.
- Salvarea locala nu asteapta si nu depinde de un request catre Firebase.
- Lipsa internetului nu trebuie sa impiedice utilizarea normala a aplicatiei.
- Cloud-ul este folosit pentru backup si restore, nu pentru live sync.
- Nu se implementeaza merge intre doua baze de date care au evoluat separat.
- Autentificarea este optionala, dar backup-ul necesita un cont autentificat.
- Un utilizator neautentificat este informat ca progresul lui nu este protejat
  in cloud.
- Un cont Firebase poate avea mai multi provideri de autentificare asociati,
  dar toti trebuie sa conduca la acelasi Firebase UID.
- Restore-ul bazei locale trebuie sa fie atomic: ori se importa intregul backup,
  ori baza locala ramane nemodificata.
- Formatul v1 include integral `split_plans`, `split_days`, `exercises`,
  `day_exercises`, `workout_sessions`, `logged_sets` si
  `active_session_sets`, inclusiv sesiunile active/neterminate.
- Preferintele necesare restore-ului sunt pastrate in randul singleton
  `app_settings`: streak-ul saptamanal, targetul saptamanal, prezenta din
  saptamana curenta, inceputul acelei saptamani si finalizarea onboarding-ului.
- Securitatea si controlul costurilor fac parte din feature, nu sunt pasi
  optionali de final.

## In afara scopului

- sincronizare live intre dispozitive;
- istoric de backup-uri sau alegerea unui snapshot dintr-o zi anterioara;
- merge la nivel de workout, set sau plan;
- colaborare intre mai multi utilizatori;
- folosirea Firestore drept baza operationala;
- inlocuirea SQLite cu o baza de date remote;
- suport pentru folosirea intentionata si alternativa a doua telefoane cu progres
  independent.

## Decizii confirmate

### Autentificare

- Autentificarea va folosi Firebase Authentication.
- Proiectul de dezvoltare Firebase folosit de aplicatie este
  `lifting-tracker-dev`.
- Identificatorul Android stabil al aplicatiei este `com.luca.liftingtracker`.
- Configuratia publica generata de FlutterFire se pastreaza in repository.
  Service accounts, cheile private si fisierele de signing nu se salveaza in
  repository.
- Firebase este initializat inainte de `runApp`, dar autentificarea ramane
  optionala: starea `null` reprezinta un utilizator guest si nu blocheaza
  pornirea sau folosirea locala a aplicatiei.
- Codul aplicatiei depinde de contractul `AuthRepository` si de modelul propriu
  `AuthUser`, nu direct de tipul `User` din Firebase Auth.
- Starea de autentificare este expusa prin Riverpod ca `StreamProvider`, pornind
  din stream-ul Firebase `userChanges()`.
- Dependentele sunt injectabile si pot fi inlocuite cu fake-uri in unit tests,
  fara Firebase real sau conexiune la internet.
- `AuthRepository` expune operatiile email/parola fara sa expuna tipuri sau
  exceptii Firebase: creare cont, login, trimitere email de verificare, reload
  utilizator, resetare parola, schimbare parola si logout.
- Erorile Firebase Auth sunt traduse la `AuthException` si `AuthErrorCode`
  proprii aplicatiei. `wrong-password`, `user-not-found` si
  `invalid-credential` sunt unificate ca `invalidCredentials`.
- Aplicatia valideaza local numai regulile pe care le detine: campuri
  obligatorii si confirmarea exacta a parolei. Firebase ramane autoritatea
  pentru sintaxa emailului si politica de complexitate a parolei.
- Emailurile sunt normalizate prin eliminarea spatiilor exterioare inaintea
  operatiilor. Parolele nu sunt normalizate sau modificate.
- Operatiile sunt coordonate de un `AsyncNotifier<void>` separat de stream-ul
  sesiunii. Controller-ul expune loading/error, pastreaza erorile tipizate si
  ignora un al doilea submit cat timp o operatie este in curs.
- Crearea contului si trimiterea emailului de verificare raman operatii
  separate. Astfel, un esec la trimiterea emailului nu este prezentat gresit
  drept esec al crearii contului, iar verificarea poate fi reincercata.
- Proiectul Firebase va folosi planul Blaze.
- Cloud Storage va folosi un bucket aflat intr-o regiune europeana.
- Aplicatia poate fi folosita fara cont.
- Autentificarea este oferita la finalul onboarding-ului, dupa configurarea
  planului si exercitiilor. Utilizatorul poate crea un cont, se poate autentifica
  sau poate continua ca guest.
- Un utilizator care continua ca guest se poate autentifica ulterior din pagina
  `Account & Backup`, accesibila din app bar-ul ecranului principal.
- Flow-urile email/parola pentru creare cont si autentificare folosesc aceeasi
  pagina si acelasi controller. Crearea contului, autentificarea, resetarea
  parolei si verificarea emailului au loading si feedback de eroare proprii.
- Dupa autentificarea cu un email neverificat, utilizatorul poate continua in
  aplicatie si poate finaliza verificarea ulterior din `Account & Backup`.
  Backup-ul cloud ramane indisponibil pana la verificarea emailului.
- Pagina `Account & Backup` afiseaza starea guest, contul autentificat si cazul
  emailului neverificat. Starea sanatoasa nu necesita un notice separat; notice-ul
  este rezervat situatiilor care necesita o actiune sau explica o limitare.
- Metodele planificate sunt:
  - email si parola;
  - Google Sign-In;
  - Sign in with Apple.
- Primele metode implementate vor fi email/parola si Google.
- Sign in with Apple va fi implementat ulterior. Configurarea si testarea live
  necesita Apple Developer Program si acces la macOS/Xcode.
- Providerii suplimentari trebuie legati contului existent prin provider
  linking, nu folositi pentru a crea accidental un al doilea Firebase UID.
- Integrarea Google foloseste un adapter propriu, `GoogleIdentityClient`, astfel
  incat lifecycle-ul `google_sign_in` sa ramana in layer-ul data, iar contractul
  `AuthRepository` si controller-ul sa nu expuna tipuri SDK.
- `GoogleSignIn` este initializat lazy o singura data pentru instanta injectata.
  Flow-ul nu cere scope-uri suplimentare si nu porneste autentificare Google
  automata; sesiunea Firebase ramane sursa de adevar la pornirea aplicatiei.
- `AuthUser` expune providerii prin enum-ul propriu `AuthProviderType` si un set
  read-only. In aceasta etapa sunt cunoscuti `emailPassword` si `google`.
- Login-ul Google schimba credentialul Google pe un credential Firebase, iar
  linking-ul foloseste `linkWithCredential` pe utilizatorul Firebase curent.
  Astfel, providerul este atasat aceluiasi UID. Lipsa sesiunii si conflictele de
  credential/provider sunt erori tipizate; nu se face account merge automat.
- Logout-ul coordoneaza inchiderea sesiunii Firebase si a sesiunii locale Google.
- Schimbarea parolei se face direct in aplicatie pentru conturile care au
  providerul email/parola. Utilizatorul introduce parola curenta, repository-ul
  face reautentificarea Firebase cu credentialul email/parola si abia apoi
  apeleaza actualizarea parolei. Parolele nu sunt normalizate, iar politica de
  complexitate ramane detinuta de Firebase.
- Scope-ul Auth 03 este mobil, iOS si Android, cu produsul in continuare iOS-first.
  Sign in with Apple ramane un flow separat, amanat pana exista Apple Developer
  Program si acces la macOS/Xcode.
- Utilizatorul isi va putea sterge contul din aplicatie.
- Stergerea contului ramane un mock-up dezactivat pana la implementarea
  reautentificarii, stergerii backup-urilor remote si stergerii contului Firebase.
  Aceasta operatie ramane urmarita intr-o etapa ulterioara de account lifecycle.

### Backup si restore

- Scopul backup-ului este recuperarea progresului dupa reinstalarea aplicatiei
  sau mutarea pe alt dispozitiv.
- Varianta finala pastreaza un singur backup per UID: ultimul upload reusit
  inlocuieste backup-ul anterior. Aceasta este o decizie de produs definitiva,
  nu o simplificare temporara pentru prima iteratie.
- Se foloseste o singura cale fixa per UID, fara fisiere timestamped, istoric
  sau selectie de versiuni. Numele exact al caii se stabileste la implementare.
- Prima iteratie va avea backup manual.
- Actiunea manuala este expusa in `Account & Backup` ca `Back up now`.
- Backup-ul va fi un snapshot JSON.
- Snapshot-ul JSON va fi comprimat cu gzip pentru upload si decomprimat
  inainte de decodare si validare la download. Formatul JSON v1 ramane acelasi.
- Limitele confirmate sunt 2 MiB (2 * 1024 * 1024 bytes) pentru fisierul gzip
  si 20 MiB (20 * 1024 * 1024 bytes) pentru JSON-ul necomprimat. Limita gzip
  se aplica in client si in Storage Rules; limita JSON se verifica inainte de
  compresie si in timpul decomprimarii, inainte de acumularea intregului output.
- Depasirea limitelor opreste operatia fara trunchierea istoricului si fara
  stergerea backup-ului remote existent.
- Backup-ul va contine un timestamp si o versiune explicita a formatului, de
  exemplu `schemaVersion` sau `backupFormatVersion`.
- Backup-ul va fi salvat in Firebase Cloud Storage sub UID-ul utilizatorului.
- Restore-ul va reconstrui starea locala intr-o singura tranzactie SQLite.
- Restore-ul nu va face merge cu datele locale.
- Dupa autentificare, daca exista atat date locale, cat si un backup remote,
  utilizatorul va primi o alegere cu sensul:
  - `Keep local data`;
  - `Replace with cloud backup`.
- `Keep local data` pastreaza datele de pe dispozitiv si backup-ul cloud
  existent. Autentificarea si aceasta alegere nu declanseaza un upload care
  inlocuieste backup-ul remote. Un upload manual ulterior ramane o actiune
  explicita separata.
- Baza SQLite pastreaza separat `local_data_owner_uid` in `app_settings`:
  `NULL` pentru date locale nerevendicate, respectiv UID-ul contului caruia ii
  apartin dupa revendicare. Logout-ul nu sterge datele locale si nu reseteaza
  acest marker. Un UID diferit poate prelua datele cu antrenamente doar dupa o
  alegere explicita in flow-ul de conflict; datele fara antrenamente pot fi
  reatribuite automat printr-un UPDATE conditionat.
  Coloana este inclusa in schema SQLite v1 actuala, fara migrare deoarece
  aplicatia este in dezvoltare. Instalarile cu o baza locala anterioara
  necesita resetarea datelor aplicatiei si restore din backup-ul cloud.
- Detectarea backup-ului si alegerea de restore trebuie sa functioneze atat
  cand autentificarea are loc in onboarding, cat si cand are loc ulterior din
  aplicatie.
- Restore-ul va putea fi initiat si dupa login, dintr-o zona de cont/backup.
- Implementarea fiecarei capabilitati de backup include si starea de application
  necesara UI-ului, plus integrarea corespunzatoare in `Account & Backup`.
  Contractele, repository-urile, controllerele si testele se stabilizeaza inainte
  de construirea UI-ului acelei etape.
- Intr-o etapa ulterioara, backup-ul va fi declansat automat dupa terminarea
  fiecarui workout.
- Daca backup-ul automat nu poate fi efectuat, aplicatia va pastra local un flag
  care indica existenta unui backup pending.
- Un backup pending va fi reincercat cand exista din nou o oportunitate
  potrivita si conexiune la internet.
- Esecul unui backup nu anuleaza si nu marcheaza drept esuata salvarea locala a
  workout-ului.
- Pentru Backup 04 s-a ales varianta simpla: un singur flag `backup_pending`,
  fara revizii, coada de workout-uri sau snapshot-uri esuate pastrate local.
  Fiecare incercare exporta baza SQLite curenta si inlocuieste acelasi backup
  remote. Pending se seteaza inainte de incercare si ramane setat la esec.
- Upload-ul automat nu asteapta confirmare si nu afiseaza feedback UI nou de
  succes. Ruleaza fara sa blocheze utilizatorul cat timp aplicatia ruleaza;
  pending ramane persistent daca aplicatia este inchisa. Retry-ul la
  deschidere/revenire se implementeaza ulterior, cu verificarile existente
  de autentificare, preferinta si ownership.

## Flow functional tinta

### Guest

1. Utilizatorul poate continua fara cont.
2. Aplicatia functioneaza complet local.
3. UI-ul comunica faptul ca progresul nu este protejat in cloud.
4. Utilizatorul poate crea un cont sau se poate autentifica ulterior.

### Prima autentificare pe un dispozitiv cu date locale

1. Utilizatorul alege email/parola sau Google.
2. Firebase returneaza un UID.
3. Aplicatia verifica daca exista un backup remote pentru UID.
4. Daca nu exista backup remote, datele locale pot deveni datele asociate
   contului si pot fi salvate prin primul backup manual.
5. Daca exista backup remote si exista si date locale, utilizatorul alege intre
   pastrarea datelor locale si inlocuirea lor cu backup-ul cloud.
6. Aplicatia nu face merge implicit.

### Reinstalare sau telefon nou

1. Utilizatorul instaleaza aplicatia si se autentifica in acelasi cont.
2. Aplicatia identifica backup-ul prin Firebase UID.
3. Utilizatorul confirma restaurarea.
4. Backup-ul este validat inainte de modificarea bazei locale.
5. Importul este executat intr-o singura tranzactie SQLite.
6. Dupa succes, providerii Riverpod relevanti sunt invalidati sau reincarcati.

### Backup automat, etapa ulterioara

1. Workout-ul este finalizat si salvat complet in SQLite.
2. Salvarea locala este considerata reusita independent de cloud.
3. Aplicatia incearca sa genereze si sa incarce un snapshot.
4. La succes, actualizeaza momentul ultimului backup si sterge flag-ul pending.
5. La esec, pastreaza datele locale si seteaza flag-ul pending.

## Directia tehnica actuala

Aceasta sectiune descrie directia agreata, nu o implementare finala.

### Servicii Firebase

- `firebase_core` pentru initializare;
- `firebase_auth` pentru sesiune si providerii de autentificare;
- `google_sign_in` pentru flow-ul nativ Google;
- `firebase_storage` pentru fisierele de backup;
- Firebase App Check intr-o etapa de hardening.

Firestore nu este necesar pentru flow-ul stabilit in prezent.

### Separarea responsabilitatilor

Directia initiala este sa existe doua arii independente:

```text
authentication
  -> sesiune, login, logout, signup, provider linking, account deletion

cloud_backup
  -> export, validare, upload, download, restore, backup status

account_and_backup flow
  -> compune starea authentication si cloud_backup pentru pagina si notice-uri
```

Codul existent de workout, plans, history si progress continua sa lucreze cu
SQLite. Firebase nu trebuie introdus direct in fiecare controller sau fisier de
commands.

Fundatia implementata in `Auth 01` foloseste urmatorul flux unidirectional:

```text
FirebaseAuth
  -> FirebaseAuthRepository (implementeaza AuthRepository)
  -> authStateProvider
  -> consumatorii viitori de auth state
```

`firebaseAuthProvider` detine dependenta SDK, `authRepositoryProvider` expune
contractul aplicatiei, iar `authStateProvider` transforma stream-ul sesiunii in
stare Riverpod observabila. Aceste layere nu fac login si nu modifica SQLite.

Cat timp pagina `Account & Backup` afiseaza numai autentificarea, ea poate ramane
temporar in feature-ul `authentication`. Cand incepe sa consume si
`cloud_backup`, pagina si selectorul care combina cele doua stari se muta in
`flows/account_and_backup`. Feature-urile continua sa detina separat operatiile
si starea lor interna.

### Continutul snapshot-ului

Formatul v1 include integral tabelele `split_plans`, `split_days`, `exercises`,
`day_exercises`, `workout_sessions`, `logged_sets` si `active_session_sets`.
Sesiunile active/neterminate sunt incluse. Randul singleton `app_settings`
include `week_streak`, `workouts_per_week_target`, `weekly_gym_attendance`,
`weekly_gym_attendance_week_start` si `did_user_finish_setup`.

Date temporare sau derivate, precum starea unui rest timer activ, notificari
programate sau cache-uri, nu ar trebui incluse implicit.

Pentru ca restore-ul este complet si nu exista merge, ID-urile locale existente
pot fi pastrate in snapshot si reintroduse la import. Nu este necesara migrarea
generala la UUID doar pentru acest feature.

### Forma metadata-ului v1

```json
{
  "backupFormatVersion": 1,
  "createdAt": "2026-08-04T00:00:00Z",
  "data": {}
}
```

`createdAt` este serializat in UTC. Structura `data` foloseste numele coloanelor
SQLite pentru campurile fiecarui rand.

## Securitate si controlul costurilor

Masurile planificate includ:

- Storage Rules care permit accesul numai cand `request.auth.uid` corespunde
  UID-ului din calea obiectului;
- cai de backup controlate de aplicatie, nu nume arbitrare nelimitate;
- limita maxima pentru dimensiunea unui backup, impusa si prin Storage Rules;
- un singur snapshot per utilizator, la o cale fixa;
- validarea content type-ului si a metadata-ului permis de Storage Rules;
- Firebase App Check inainte de lansarea production;
- alerte de buget si monitorizarea usage-ului in Google Cloud;
- evitarea Phone Auth, care nu este necesara si are costuri SMS;
- email verification pentru conturile email/parola; backup-ul devine permis
  numai dupa verificarea emailului;
- testarea regulilor cu Firebase Emulator Suite, daca flow-ul de dezvoltare o
  permite;
- stergerea backup-urilor asociate atunci cand este sters contul.

Configuratia publica generata de FlutterFire este pastrata in repository pentru
ca un clone nou sa poata construi aplicatia. Cheile private, service accounts,
keystore-urile si alte credentiale secrete nu se salveaza in repository.

## Intrebari deschise

Aceste puncte nu trebuie tratate drept decizii pana cand utilizatorul nu le
confirma:

1. Se face automat un prim backup dupa autentificare, cand nu exista backup
   remote, sau numai la apasarea
   explicita a butonului?
2. Care este regiunea europeana exacta a bucket-ului?
3. Ce se intampla cu datele locale cand utilizatorul isi sterge contul?
4. Cum tratam un telefon vechi care incearca sa faca backup dupa ce datele au
    fost restaurate pe un telefon nou?
5. Care sunt momentele exacte de retry pentru un backup pending?
6. Care sunt textele finale si prioritatea vizuala pentru `last successful
    backup`, backup pending, backup esuat si restore in progres?
7. Cand introducem Sign in with Apple in raport cu publicarea pe iOS?

## Roadmap si status

Statusurile permise sunt `not started`, `in progress`, `blocked`, `deferred` si
`done`.

| Etapa | Continut | Status |
| --- | --- | --- |
| 0 | Plan general, delimitarea scope-ului si deciziile initiale | done |
| 1 | Firebase foundation si contractele de autentificare | done |
| 2 | Email/parola: signup, verify, login, reset si logout | done |
| 3 | Google Sign-In si provider linking | done |
| 4 | UX guest/account in onboarding si Account & Backup | done |
| 5 | Contractul snapshot-ului, export/import local tranzactional si teste; fara UI | done |
| 6 | Upload/download manual, controller/status si UI pentru backup manual | done |
| 7 | Detectare backup, conflicte, restore si UI-ul aferent | in progress |
| 8 | Account lifecycle ramas: account deletion si stergerea datelor remote | not started |
| 9 | Backup automat si pending/retry, fara UI suplimentar pentru automatizare | done |
| 10 | Storage Rules, App Check, bugete si hardening | in progress |
| 11 | Sign in with Apple si linking | deferred |

Statusul unei etape se schimba in `done` numai dupa implementare, formatter,
analyzer si testele relevante.

## Ordinea recomandata a task-urilor Codex

1. `Auth 01 - Firebase foundation`
2. `Auth 02 - Email and password`
3. `Auth 03 - Google Sign-In and provider linking`
4. `Auth 04 - Guest and account UX`
5. `Backup 01 - Snapshot contract and local export/import`
6. `Backup 02 - Manual Cloud Storage backup and UI`
7. `Backup 03 - Restore flows and conflict UI`
8. `Backup 04 - Automatic backup, pending UI and hardening`
9. `Auth 05 - Sign in with Apple`, cand exista prerechizitele externe

Task-urile dependente se executa secvential. Daca sunt folosite worktree-uri
separate, task-ul urmator trebuie sa porneasca din starea Git care contine
commit-urile task-ului anterior.

## Mod de lucru didactic

- Utilizatorul implementeaza in principal codul.
- Codex explica intai mecanismul, flow-ul si fisierele afectate.
- Pentru solutii cu diferente semnificative de complexitate, Codex prezinta
  varianta incrementala si varianta production-grade.
- Codex recomanda o varianta si explica tradeoff-urile, dar utilizatorul confirma
  alegerea.
- Codex ofera snippet-uri mici si focalizate, nu implementarea integrala din
  prima.
- Daca utilizatorul spune ca vrea sa incerce, Codex asteapta implementarea lui
  si apoi face review concret.
- Refactorurile invazive sunt explicate si confirmate inainte de modificare.
- Fiecare etapa trebuie sa aiba un rezultat verificabil inainte de a trece la
  urmatoarea.
- Testarea este facuta incremental conform
  [`docs/testing/testing_guide.md`](../testing/testing_guide.md), nu adaugata la
  finalul feature-ului.

## Protocol de handoff intre task-uri

La inceputul unui task:

1. citeste `AGENTS.md` si acest document;
2. verifica statusul roadmap-ului si ultimul entry din Implementation Log;
3. inspecteaza codul curent, fara sa presupui ca planul descrie deja
   implementarea;
4. identifica intrebarile deschise care blocheaza etapa;
5. explica utilizatorului flow-ul si fisierele afectate inainte de schimbari
   invazive.

La finalul unui task:

1. actualizeaza statusul etapelor;
2. muta deciziile confirmate din `Intrebari deschise` in sectiunea potrivita;
3. adauga un entry in `Implementation Log`;
4. noteaza fisierele modificate si comportamentul rezultat;
5. raporteaza separat formatter-ul, analyzer-ul si testele;
6. noteaza urmatorul pas recomandat;
7. ideal, lasa repository-ul intr-o stare verificata si salvata intr-un commit
   inainte ca un task dependent sa inceapa.

## Implementation Log

### 2026-10-16 - Schema SQLite v1 ca punct de plecare nou

- Utilizatorul a confirmat ca progresul de pe instalarea mai veche este deja
  salvat in cloud si a ales sa renunte la migrarea SQLite pentru acea instalare.
- Baza noua foloseste versiunea 1 cu schema actuala completa, inclusiv
  `automatic_backup_enabled`, `backup_pending` si `local_data_owner_uid`.
  Codul pentru upgrade-ul 1 -> 2 si reconstruirea tabelului `exercises` a fost
  eliminat; cheile straine sunt activate direct la deschidere.
- O baza locala deja creata la versiunea 2 nu poate fi deschisa de aceasta
  versiune a aplicatiei. Pe dispozitivul respectiv trebuie sterse datele
  aplicatiei, apoi utilizatorul se autentifica si restaureaza backup-ul cloud.
- Fisiere: `lib/core/database/app_database.dart`, testul SQLite pentru pending
  si acest plan.
- Formatter: 2 fisiere Dart verificate, 1 reformatat.
- Analyzer: `No issues found`.
- Teste: 2/2 focalizate pentru schema/pending si importul snapshot-ului;
  suita completa 266/266, toate trecute.

**Urmatorul pas:** verificarea Storage Rules si configurarea Firebase App Check.

### 2026-10-15 - Backup 04 basic: verificare finala

- Utilizatorul a confirmat smoke test-ul pe emulator: backup-ul automat
  functioneaza dupa finalizarea unui workout.
- Doua widget tests noi verifica retry-ul la redeschidere pentru un UID care
  detine datele locale: pending true porneste un singur upload si il sterge la
  succes; toggle OFF pastreaza pending fara upload. Testele existente confirma
  ca pending false nu declanseaza cerere de metadata in gate.
- Fisierele Dart modificate au fost formatate; in aceasta verificare 12 fisiere
  au fost verificate si 2 reformate.
- Analyzer: `No issues found`.
- Teste: 19/19 pentru gate; suita completa 266/266, toate trecute.
- `git diff --check` nu raporteaza erori; avertismentele Git privesc doar
  conversia LF/CRLF la o scriere viitoare.
- Etapa 9 este incheiata pentru comportamentul basic agreat. Limita acceptata
  pentru workout-uri suprapuse ramane documentata mai jos.
- Migrarea coloanelor `automatic_backup_enabled` si `backup_pending` pentru
  baze SQLite deja create la versiunea 2 ramane necesara inainte de release.
  Va fi tratata impreuna cu etapa 10 de hardening; acest test pe emulator nu
  verifica o instalare veche.

**Urmatorul pas:** utilizatorul face commit, apoi incepe etapa 10 cu migrarea
SQLite, verificarea Storage Rules si Firebase App Check.

### 2026-10-15 - Backup 04: retry pending la intrarea in aplicatie

- Utilizatorul a adaugat in `SignInDataGate` o incercare unica per UID cand
  evaluarea ajunge la `continueLocal`. Citeste intai `backup_pending`; daca
  este false, nu initializeaza controllerul cloud si nu cere metadata.
- Daca pending este true, reverifica sesiunea si apeleaza metoda automata,
  care aplica toggle-ul si regulile de ownership. Eroarea nu blocheaza gate-ul.
- Review-ul codului este read-only. Formatter, analyzer si teste: nerulate la
  cererea utilizatorului; scenariile de retry raman pe lista finala.
- Utilizatorul a decis sa nu adauge coordonare suplimentara pentru cazul rar
  in care un al doilea workout se incheie in timpul upload-ului celui dintai.
  In aceasta situatie, upload-ul vechi poate sterge pending-ul pentru datele
  mai noi; o salvare/backup manual ulterior le poate include. Costul unui
  guard in memorie ar fi aproximativ 10-20 de linii plus teste, fara garantie
  completa daca procesul se inchide intre operatii. Aceasta limita este
  acceptata pentru Backup 04, fara revizii sau coada de snapshot-uri.

**Urmatorul pas:** verificarea vizuala a flow-ului pe dispozitiv si
verificarile automate amanate cand utilizatorul le solicita.

### 2026-10-15 - Backup 04: pending setat inainte de cloud

- Utilizatorul a adaugat in `backupAutomatically()` citirea UID-ului local si
  setarea `backup_pending = true` inainte de asteptarea metadata-ului.
  Controllerul existent ramane responsabil de upload si stergerea pending-ului
  la succes.
- Review-ul a confirmat ordinea operatiilor din cod. Retry-ul la redeschidere
  inca nu este implementat.
- La cererea utilizatorului, formatter, analyzer si teste nu au fost rulate in
  acest pas; verificarea automata ramane pentru finalul flow-ului Backup 04.

**Urmatorul pas:** reincearca un pending la pornire numai dupa ce gate-ul
confirma `continueLocal` pentru acelasi UID. Daca flag-ul este false, nu
initializa controllerul cloud si nu cere metadata.

### 2026-10-15 - Backup 04: verificari amanate la cererea utilizatorului

- Utilizatorul a cerut ca, de acum pana la finalizarea flow-ului Backup 04,
  testele si verificarea automata sa fie rulate impreuna numai cand solicita el.
  Ultima verificare efectuata ramane 36/36 teste focalizate si analyzer fara
  probleme, inainte de urmatoarele schimbari.
- Verificarile de facut la final: pending este persistat inaintea asteptarii
  metadata/cloud; upload-ul reusit il sterge, iar exportul sau upload-ul esuat
  il pastreaza; toggle OFF, guest si email neverificat nu trimit date;
  finalizarea workout-ului nu asteapta upload-ul; retry-ul la redeschidere
  exporta baza curenta; ownership-ul diferit blocheaza upload-ul. Se ruleaza
  formatter pe fisierele
  Dart modificate, analyzer, testele relevante si apoi suita completa.
- In acest pas a fost actualizat numai planul. Formatter, analyzer si teste:
  nerulate la cererea utilizatorului.

**Urmatorul pas:** utilizatorul muta setarea pending inainte de asteptarea
metadata-ului din metoda automata; apoi implementam retry-ul la redeschidere.

### 2026-10-15 - Backup 04: backup pornit dupa workout

- Utilizatorul a apelat `backupAutomatically()` cu `unawaited` dupa salvarea
  sesiunii si a progresului saptamanal in `endSession()`.
- Un test SQLite cu backup controlat prin `Completer` confirma ca workout-ul
  devine `completed` si `endSession()` se incheie cat timp upload-ul asteapta.
- Formatter: 2 fisiere Dart verificate, testul nou reformatat.
- Analyzer: `No issues found`.
- Teste: 36/36 pentru lifecycle-ul workout-ului si controllerul cloud.
  Suita completa nu a fost rulata.
- Limita actuala: `backup_pending` este setat in `backupNow()`, dupa asteptarea
  metadata-ului din `backupAutomatically()`. O inchidere a aplicatiei in acel
  interval poate pierde cererea de backup; retry-ul la redeschidere inca lipseste.

**Urmatorul pas:** setarea pending imediat dupa salvarea workout-ului, inaintea
oricarui request cloud, apoi retry-ul pending la redeschiderea aplicatiei.

### 2026-10-15 - Backup 04: conditia metodei automate corectata

- Utilizatorul a corectat negatia din verificarea generatiei dupa `await future`.
  Metoda automata poate acum continua catre upload pentru sesiunea valida.
- Formatter: controllerul verificat, fara reformatare.
- Analyzer: `No issues found`.
- Teste controller: 35/35 trecute, inclusiv cele sapte cazuri automate.
  Suita completa nu a fost rulata.

**Urmatorul pas:** utilizatorul adauga apelul `unawaited(backupAutomatically())`
la sfarsitul `endSession()`, dupa finalizarea salvarilor locale. Legatura si
independenta finalizarii workout-ului fata de upload urmeaza sa fie testate.

### 2026-10-15 - Backup 04: review si teste pentru backupAutomatically

- Utilizatorul a adaugat metoda automata in controllerul existent. Review-ul
  a identificat o negatie lipsa dupa `await future`: conditia curenta iese
  cand generatia este valida. Corectia ramane de facut de utilizator.
- Sapte teste noi acopera toggle OFF, guest, email neverificat, upload permis,
  asteptarea initializarii, metadata esuata si eroarea upload-ului automat.
- Formatter: 2 fisiere Dart verificate, testul reformatat; logica utilizatorului
  nu a fost modificata.
- Analyzer: `No issues found`.
- Teste controller: 31 trecute, 4 esuate deoarece upload-ul automat nu porneste.
  Suita completa nu a fost rulata.

**Urmatorul pas:** utilizatorul corecteaza conditia la
`if (!_isCurrent(generation)) return;`, apoi rerulam testele inainte de a lega
metoda la finalizarea workout-ului.

### 2026-10-15 - Backup 04: pending in backupNow

- Utilizatorul a conectat flag-ul la metoda de upload existenta: pending se
  seteaza dupa verificarea ownership-ului, inainte de export, si se sterge
  dupa upload reusit si verificarea sesiunii curente.
- Testul nou controleaza exportul si upload-ul cu Completer si verifica
  pending in ambele faze, apoi stergerea la succes. Testele existente verifica
  acum pastrarea flag-ului la eroare de export/upload si la rezultate vechi
  dupa schimbarea sesiunii.
- Formatter: 2 fisiere Dart verificate, testul controllerului reformatat.
- Analyzer: `No issues found`.
- Teste: 29/29 pentru controller si pending SQLite. Suita completa nerulata.
- Declansarea automata dupa workout nu este inca implementata.

**Urmatorul pas:** metoda pentru incercarea automata, care respecta toggle-ul
si asteapta initializarea controllerului, apoi apelul fara asteptarea cloud-ului
la finalizarea workout-ului.

### 2026-10-15 - Backup 04: pending expus prin repository-ul local

- Utilizatorul a adaugat `loadBackupPending()` si `setBackupPending(bool)`
  in `LocalBackupRepository` si delegarea lor in adapterul SQLite existent.
- Fake-ul repository-ului pastreaza acum flag-ul in memorie. Testul SQLite
  existent trece prin adapter si verifica inclusiv propagarea erorilor cand
  lipseste randul singleton; nu au fost introduse layere sau provideri noi.
- Formatter: 4 fisiere Dart verificate, testul SQLite reformatat.
- Analyzer: `No issues found`.
- Teste: 28/28 pentru pending SQLite si controllerul de backup existent.
  Suita completa nu a fost rulata.

**Urmatorul pas:** utilizatorul conecteaza pending la incercarea de upload in
`backupNow()`, apoi legam declansarea de finalizarea workout-ului.

### 2026-10-15 - Backup 04: citirea si scrierea flag-ului pending

- Utilizatorul a implementat `loadBackupPending()` si `setBackupPending(bool)`
  in doua fisiere din `features/cloud_backup/data`. Review-ul confirma
  conversia SQLite 0/1 si erorile explicite cand lipseste randul singleton.
- A fost adaugat `backup_pending_test.dart`, cu SQLite real temporar, pentru
  valoarea initiala false, setarea true repetata, revenirea la false si erorile
  de citire/scriere cand lipseste randul `app_settings`.
- Varianta confirmata foloseste un singur pending si exporta baza curenta la
  fiecare incercare, fara versiuni sau UI nou pentru upload-ul automat.
- Functiile nu sunt inca legate de finalizarea workout-ului, upload sau retry.
  Gate-ul si regula fara metadata cloud pentru acelasi proprietar raman intacte.
- Formatter: 3 fisiere Dart verificate, comanda pending reformata.
- Analyzer: `No issues found`.
- Teste: 1/1 test SQLite focalizat trecut, cu toate scenariile de mai sus.
  Suita completa nu a fost rulata.

**Urmatorul pas:** conectarea flag-ului si a incercarii de backup la finalizarea
workout-ului, dupa salvarea locala completa si fara asteptarea cloud-ului in UI.

### 2026-10-12 - Backup 03: loading in continutul paginii

- S-a eliminat ecranul de loading care copia bara de navigare cu index fix.
  `SignInDataGate` transmite starea de verificare catre paginile existente si
  pastreaza bariera care blocheaza interactiunile in timpul verificarii.
- `MainShell` pastreaza propria bara de navigare si inlocuieste app bar-ul si
  continutul paginii cu un `CircularProgressIndicator` centrat. Pe ruta
  `Account & Backup`, care nu are bara de jos, se afiseaza doar indicatorul.
- Verificarea porneste la initializarea starii auth si la schimbarea contului.
  Cand UID-ul este deja proprietarul datelor locale, citirea markerului SQLite
  incheie evaluarea fara cerere de metadata catre cloud.
- Fisiere modificate: gate-ul, `MainShell`, pagina `Account & Backup`, testele
  gate-ului si acest plan.
- Formatter: 4 fisiere Dart verificate, 2 reformate; testul actualizat a fost
  verificat din nou fara reformatare.
- Analyzer: `No issues found`.
- Teste: 17/17 pentru gate; suita completa nu a fost rulata.

**Urmatorul pas:** verificare vizuala pe telefon la hot restart si dupa sign in
din pagina `Account & Backup`.

### 2026-10-12 - Backup 03: verificarea de la pornire nu mai deschide alert

- La hot restart providerii se recalculeaza. Pentru un UID deja proprietar,
  evaluarea citeste doar markerul SQLite si nu cere metadata din cloud.
- `SignInDataGate` nu mai arata dialogul generic `Checking local and cloud
  data...` in timpul verificarii initiale. Actiunile din spate raman blocate;
  daca verificarea dureaza peste 400 ms, apare o bara subtire sub status bar.
  Alerturile Cupertino raman pentru conflict, erori si aplicarea alegerii.
- Testele widget acopera pornirea cu sesiune existenta si o verificare cloud
  intarziata, inclusiv blocarea actiunilor locale.
- Fisiere modificate: gate-ul, testul lui si acest plan.
- Formatter: 2 fisiere Dart verificate, fara reformatare.
- Analyzer: `No issues found`.
- Teste: 15/15 pentru gate; suita completa nu a fost rulata.

**Urmatorul pas:** verificarea vizuala pe telefon la hot restart si la un
conflict real intre conturi.

### 2026-10-08 - Backup 03: dialogurile de conflict folosesc Cupertino

- `SignInDataGate` foloseste `CupertinoAlertDialog` si `CupertinoDialogAction`
  pentru alegeri, erori si loading, conform dialogului de restore manual.
  Loading-ul pastreaza bara liniara. Bariera modala are acum opacitatea
  `black54`, iar textele au fost scurtate pentru latimea unui alert Cupertino.
- Blocarea actiunilor din spatele dialogului, deciziile si retry-ul raman
  aceleasi. Testele widget verifica tipul dialogului, actiunile si bara de
  progres.
- Fisiere modificate: `sign_in_data_gate.dart`, testul widget al gate-ului si
  acest plan.
- Formatter: 2 fisiere Dart verificate, 1 reformat la prima trecere.
- Analyzer: `No issues found`.
- Teste: 18/18 pentru gate si sectiunea de backup.
- Aspectul pe telefon trebuie confirmat dupa aceasta modificare.

**Urmatorul pas:** verificarea pe telefon a alerturilor pentru backup gasit,
conflict cu alt cont, eroare si loading.

### 2026-10-08 - Backup 03: upload conditionat de ownership si sesiunea curenta

- `backupNow()` nu mai revendica datele cu `ownerUid == null`. Exportul si
  upload-ul sunt permise numai daca markerul SQLite este deja UID-ul curent,
  dupa rezolvarea flow-ului de autentificare. Un apel direct nu poate sari
  peste alegerea utilizatorului si nu poate suprascrie backup-ul existent cu
  date locale nerevendicate.
- Controllerul verifica sesiunea dupa asteptarile async si reciteste ownership-ul
  dupa export, imediat inainte de upload. Logout-ul, schimbarea contului,
  pierderea verificarii emailului sau schimbarea proprietarului opresc upload-ul
  daca acesta nu a inceput inca.
- Fiecare build are o generatie in memorie, invalidata prin `onDispose`.
  Operatiile din generatii vechi nu pot publica succesul sau eroarea peste
  starea sesiunii curente. Mecanismul acopera si iesirea din contul A urmata de
  revenirea in A inainte de finalizarea operatiei vechi.
- Aceeasi protectie se aplica citirii metadata din `build()` si actualizarii
  cache-ului pentru ultimul backup. Rezultatele cloud devenite vechi sunt
  ignorate inaintea actualizarii cache-ului; scrierile de cache deja incepute
  raman limitate la UID-ul initial.
- Limita explicita: un upload deja trimis catre repository poate termina
  pentru UID-ul initial; acest pas nu introduce anularea transferului Firebase.
  Rezultatul vechi nu actualizeaza starea noii sesiuni.
- Fisiere modificate in acest pas: `cloud_backup_controller.dart`, testele
  controllerului si acest plan.
- Formatter: 2 fisiere Dart verificate, 1 reformat.
- Analyzer: `No issues found`.
- Teste: 27/27 pentru controller si 54/54 pentru decizie, coordonator, gate,
  `BackupSection` si notice-uri. Suita completa nu a fost rulata.
- Backup 03 ramane `in progress` pana la verificarea manuala pe dispozitiv.

**Urmatorul pas:** smoke test pe dispozitiv cu doua conturi: `Keep local data`
nu schimba backup-ul cloud, transferul schimba proprietarul numai dupa alegere,
restore-ul actualizeaza istoricul si split-ul, logout-ul pastreaza datele, iar
repornirea aplicatiei cu un conflict nerezolvat afiseaza din nou dialogul.

### 2026-10-04 - Backup 03: verificare globala dupa autentificare si dialoguri

- `SignInDataGate` sta in `MaterialApp.builder`, deasupra navigatorului. Astfel,
  verifica atat sesiunea pastrata la pornirea aplicatiei, cat si autentificarea
  facuta pe o pagina deja deschisa din onboarding sau `Account & Backup`.
- Gate-ul urmareste sesiunea Firebase si evaluarea datelor pentru acelasi UID.
  Cand evaluarea este in curs, a esuat sau cere o alegere, o bariera modala
  blocheaza actiunile asupra bazei locale. Guest si conturile cu email
  neverificat continua fara evaluarea backup-ului.
- Evaluarea expune acum si UID-ul pentru care a fost calculata decizia; UI-ul
  ignora un raspuns vechi daca intre timp contul s-a schimbat. Atasarea sigura
  `attachLocal` porneste automat o singura data per UID; celelalte decizii au
  dialoguri in engleza pentru pastrarea datelor locale, transfer explicit,
  restore sau logout. Un backup disparut si erorile nu deblocheaza conflictul;
  utilizatorul poate reincerca sau alege actiunea locala permisa.
- Invalidarea dupa claim, transfer sau restore recalculeaza evaluarea, astfel
  incat bariera dispare numai cand datele locale sunt asociate UID-ului curent.
- Fisiere modificate in acest pas: `main.dart`, providerul evaluarii,
  controllerul rezolvarii, noul `sign_in_data_gate.dart`, testele widget ale
  gate-ului si acest plan.
- Formatter: 5 fisiere Dart verificate, 0 reformate.
- Analyzer: `No issues found`.
- Teste: 62/62 focalizate pentru decizie, coordonator, SQLite, restore, UI-ul
  manual si gate; verificarea vizuala pe dispozitiv ramane de facut.
- Backup 03 ramane `in progress`.

**Urmatorul pas:** intarirea lui `backupNow()` la schimbarea contului in timpul
operatiei si verificarea ca un apel direct nu poate revendica sau incarca date
cat timp alegerea de conflict este inca nerezolvata.

### 2026-10-04 - Backup 03: coordonarea rezolvarii conflictului

- `PostSignInDataResolutionController` aplica numai actiuni compatibile cu
  decizia afisata. Recalculeaza decizia din SQLite si metadata cloud, verifica
  UID-ul curent dupa asteptari si imediat inainte de modificarea proprietarului.
  Transferul datelor cu antrenamente cere actiunea explicita `transferLocal`;
  `signOut` nu consulta cloud-ul si nu schimba datele locale.
- Atasarea automata a unei baze atribuite altui UID foloseste un singur `UPDATE`
  SQLite conditionat de UID-ul asteptat si `NOT EXISTS(workout_sessions)`.
  Repository-ul local expune separat acest transfer sigur si transferul explicit.
- Coordonatorul refoloseste controllerul de restore. Invalidarea providerilor
  locali dupa un import reusit are loc acum in controllerul de restore, astfel
  incat orice intrare in restore primeste acelasi refresh.
- Fisiere modificate: controllerul de rezolvare si testele lui, contractul si
  adapterul repository-ului local, comenzile SQLite si testul lor, controllerul
  de restore, helperul de invalidare si testul lui, `BackupSection` si planul.
- Formatter: doar fisierele Dart modificate, fara erori.
- Analyzer: `No issues found`.
- Teste: 38/38 focalizate pentru rezolvare, decizie, restore, SQLite, invalidare
  si UI-ul manual; suita completa nu a fost rulata in acest pas.
- Coordonatorul nu este inca apelat din UI. Backup 03 ramane `in progress`.

**Urmatorul pas:** pornirea flow-ului la o sesiune autentificata, inclusiv la
deschiderea aplicatiei cu sesiune pastrata, si blocarea operatiilor locale pana
la rezolvarea unui conflict cu alt proprietar.

### 2026-10-01 - Backup 03: providerul deciziei urmareste schimbarea contului

- Providerul urmareste `authStateProvider` cu `watch` si verifica UID-ul curent
  dupa citirea metadata din cloud. Daca sesiunea s-a schimbat, opreste decizia
  veche cu `CloudBackupErrorCode.canceled`.
- Copia accidentala a providerului din `test/` a fost eliminata; sursa folosita
  de aplicatie ramane in `lib/features/cloud_backup/application/`.
- Fisiere modificate: providerul deciziei, testul lui si acest plan.
- Formatter: providerul Dart verificat, fara schimbari.
- Analyzer: `No issues found`.
- Teste: 7/7 focalizate; suita completa nu a fost rulata pentru aceasta corectie.

**Urmatorul pas:** aplicarea explicita a rezultatului `attachLocal` cu verificarea
UID-ului curent inainte de schimbarea markerului local. Apoi se pot lega
alegerile utilizatorului pentru cazurile cu date locale si backup cloud.

### 2026-10-01 - Backup 03: teste pentru providerul deciziei dupa sign in

- Providerul read-only scris de utilizator a fost mutat din `test/` in
  `lib/features/cloud_backup/application/`, cu importul functiei pure corectat.
- Testele acopera guest/unverified, UID local identic, backup prezent sau
  absent, eroare cloud si schimbarea contului in timpul citirii metadata.
- 6 din 7 teste trec. Testul de schimbare a contului ramane rosu: providerul
  citeste auth state fara dependenta reactiva si compara din nou UID-ul local
  cu UID-ul initial in loc sa citeasca UID-ul autentificat curent.
- Fisiere modificate: providerul, testul lui si acest plan.
- Formatter: 2 fisiere Dart verificate, 1 reformat la prima trecere.
- Analyzer: `No issues found`.
- Teste: 6/7 focalizate; suita completa nu a fost rulata cat timp testul nou
  ramane rosu.

**Urmatorul pas:** legarea providerului de `authStateProvider` prin `watch` si
verificarea UID-ului curent dupa asteptarea metadata, apoi rerularea testelor.

### 2026-10-01 - Backup 03: decizia pura dupa sign in

- `decideSignInData()` a fost mutata din `test/` in layer-ul application, astfel
  incat aplicatia sa o poata importa. Functia primeste UID-ul autentificat,
  proprietarul local, prezenta antrenamentelor si prezenta backup-ului remote;
  returneaza un `SignInDataDecision` fara acces la SQLite, Firebase sau UI.
- Opt teste acopera toate rezultatele si prioritatea UID-ului deja potrivit.
- Fisiere modificate: functia de decizie, testul ei si acest plan.
- Formatter: 2 fisiere Dart verificate, 1 reformat.
- Analyzer: `No issues found`.
- Teste: 8/8 focalizate; suita completa nu a fost rulata pentru functia pura.

**Urmatorul pas:** un coordonator care obtine cele patru valori din
repository-uri, aplica decizia si asteapta alegerea utilizatorului in cazurile
cu dialog. Integrarea UI trebuie sa acopere onboarding si `Account & Backup`.

### 2026-10-01 - Backup 03: repository pentru progres si transfer

- `LocalBackupRepository` si adapterul SQLite expun `hasWorkoutProgress()` si
  `reassignOwnerUid()` prin providerul local existent; nu a fost creat un
  provider nou.
- Fake-ul repository-ului simuleaza progresul local si transferul conditionat
  de UID-ul asteptat. Testul SQLite trece prin adapter si confirma citirea
  progresului, transferul si propagarea erorii pentru un UID invechit.
- Fisiere modificate in acest pas: interfata si adapterul utilizatorului,
  fake-ul de backup, testul SQLite si acest plan.
- Formatter: 4 fisiere Dart verificate, 0 reformate.
- Analyzer: `No issues found`.
- Teste: 1/1 focalizat; suita completa 196/196.

**Urmatorul pas:** definirea deciziei dupa autentificare din UID-ul local,
existenta antrenamentelor locale si existenta backup-ului cloud, apoi
coordonarea alegerii utilizatorului fara upload implicit.

### 2026-10-01 - Backup 03: transfer explicit al markerului local

- Utilizatorul a adaugat `reassignLocalDataOwnerUid()` ca update SQLite
  conditionat de UID-ul proprietarului observat anterior. `claimForUid()`
  pastreaza regula separata `NULL -> UID` si continua sa respinga alt cont.
- Testul SQLite verifica lipsa proprietarului, UID-ul asteptat gresit,
  transferul reusit, confirmarea invechita si argumentele invalide. Un update
  care nu afecteaza exact un rand lasa markerul neschimbat.
- Review-ul a identificat un mesaj intern `StateError` neclar; comportamentul
  este corect, iar textul poate fi simplificat inainte de folosirea in UI.
- Fisiere modificate in acest pas: comanda utilizatorului, testul SQLite nou
  si acest plan.
- Formatter: 1 fisier Dart de test verificat si reformatat; comanda
  utilizatorului nu a fost reformatata in timpul review-ului.
- Analyzer: `No issues found`.
- Teste: 1/1 focalizat; suita completa nu a fost rulata pentru acest pas local.

**Urmatorul pas:** expunerea query-ului de progres si a transferului prin
`LocalBackupRepository`, apoi coordonatorul de decizie dupa autentificare.

### 2026-10-01 - Backup 03: detectarea progresului local

- Query-ul `hasLocalWorkoutProgress()` verifica daca exista macar o sesiune in
  `workout_sessions`. Preseturile initiale nu sunt considerate progres local;
  un antrenament inceput este considerat progres care merita protejat.
- Testul SQLite verifica baza proaspata (`false`) si o sesiune activa (`true`).
  `EXISTS` intoarce 0/1, citit de `sqflite` ca `int`.
- Fisiere modificate in acest pas: query-ul utilizatorului, testul SQLite nou
  si acest plan.
- Formatter: 1 fisier Dart de test verificat, 0 reformat; query-ul utilizatorului
  nu a fost reformat in timpul review-ului.
- Analyzer: `No issues found`.
- Teste: 1/1 focalizat; suita completa nu a fost rulata pentru acest pas local.

**Urmatorul pas:** comanda explicita de transfer al `local_data_owner_uid`
pentru cazul in care utilizatorul decide sa foloseasca antrenamentele locale
cu un alt cont. `claimForUid()` continua sa respinga schimbarea tacita.

### 2026-09-30 - Backup 03: UID atomic la restore manual

- `LocalBackupRepository.importSnapshot()` primeste explicit `ownerUid`.
  Controllerul de restore transmite UID-ul verificat din sesiunea curenta dupa
  download si inainte de import.
- Comanda SQLite valideaza UID-ul si il scrie in `app_settings` in aceeasi
  tranzactie care inlocuieste planurile, exercitiile si istoricul. Preferintele
  locale de backup raman neatinse; UID-ul nu este citit din snapshot.
- Dialogul existent pastreaza alegerea explicita: `Keep local data` nu importa,
  iar `Restore backup` importa si atribuie datele UID-ului autentificat.
- Testele verifica transmiterea UID-ului, schimbarea proprietarului numai dupa
  succes si rollback-ul tuturor datelor cand scrierea UID-ului esueaza.
- Fisiere modificate: contractul si adapterul local, controllerul de restore,
  comanda de import, fake-ul, cele trei teste relevante si acest plan.
- Formatter: 8 fisiere Dart verificate, 0 reformate.
- Analyzer: `No issues found`.
- Teste: 16/16 focalizate; suita completa 194/194.

**Urmatorul pas:** detectarea conflictului local/cloud dupa sign in, atat in
onboarding, cat si in `Account & Backup`. Acest dialog automat nu este inca
implementat; restore-ul manual are confirmarea sa explicita.

### 2026-09-30 - Backup 03: ownership verificat in backupNow

- `backupNow()` citeste proprietarul local dupa validarea sesiunii. Datele cu
  acelasi UID pot fi exportate; datele nerevendicate sunt revendicate de UID-ul
  curent la actiunea manuala; un UID diferit blocheaza exportul si upload-ul.
- Adapterul SQLite asteapta comanda de revendicare si propaga erorile ei.
  Testul SQLite trece acum prin adapter, nu doar prin functiile SQL directe.
- Fisiere modificate in acest pas: controllerul de backup, adapterul SQLite,
  formatarea interfetei `LocalBackupRepository`, testul SQLite si acest plan.
- Formatter: 4 fisiere Dart verificate, 1 reformat.
- Analyzer: `No issues found`.
- Teste: 15/15 pentru controller, 1/1 pentru adapterul SQLite; suita completa
  194/194 inainte de ajustarea testului SQLite, care a trecut separat dupa.

**Urmatorul pas:** protejarea restore-ului la schimbarea contului si stabilirea
UID-ului local in aceeasi tranzactie cu importul snapshot-ului. Flow-ul de
conflict dupa sign in trebuie sa faca alegerea utilizatorului inainte de a
inlocui datele locale.

### 2026-09-30 - Backup 03: teste pentru ownership in backupNow

- Fake-ul pentru `LocalBackupRepository` poate citi si revendica UID-ul local,
  pastrand aceleasi reguli de revendicare ca implementarea SQLite.
- Au fost adaugate trei scenarii in testul controllerului: acelasi UID poate
  incarca backup-ul fara revendicare, UID-ul `NULL` este revendicat inainte de
  upload, iar un UID diferit blocheaza exportul si upload-ul.
- Testele noi sunt intentionat rosii pana la conectarea verificarii in
  `backupNow()`: 12 trecute si 3 esuate in fisierul focalizat.
- Review-ul adapterului SQLite a gasit ca `claimForUid()` nu returneaza inca
  `Future`-ul comenzii, deci apelantul nu ii asteapta finalizarea sau eroarea.
- Fisiere modificate in acest pas: testul controllerului, fake-ul de backup si
  acest plan.
- Formatter: 2 fisiere Dart verificate, 0 reformate.
- Analyzer: `No issues found`.
- Teste: 12/15 focalizate; suita completa nu a fost rulata, deoarece testele
  noi asteapta implementarea.

**Urmatorul pas:** returnarea `Future`-ului din adapterul SQLite si verificarea
ownership-ului in `backupNow()` inainte de `exportSnapshot()`.

### 2026-09-30 - Backup 03: test pentru local data ownership

- `local_data_owner_uid` este stocat in `app_settings`; query-ul citeste UID-ul
  local, iar comanda revendica o singura data datele nerevendicate. Repetarea
  cu acelasi UID este permisa; un UID diferit este respins fara schimbarea
  proprietarului. Aceste operatii nu sunt inca legate de sign in sau backup.
- Testul SQLite acopera UID gol, prima revendicare, repetarea si refuzul unui
  al doilea cont. Testul de import verifica faptul ca restore-ul pastreaza
  markerul local existent, in loc sa il ia din snapshot.
- Fisiere modificate in acest pas: cele doua teste din
  `test/features/cloud_backup/data/` si acest plan.
- Formatter: 2 fisiere Dart verificate, 0 reformate.
- Analyzer: `No issues found`.
- Teste: 2/2 focalizate; suita completa 192/192.

**Urmatorul pas:** conectarea verificarii ownership-ului la operatiile care
pot suprascrie backup-ul sau datele locale, incepand cu `backupNow()`.

### 2026-09-30 - Backup 03: notice temporar si refresh dupa restore

- Toate rezultatele terminale ale restore-ului (`restored`, `noBackup`, eroare)
  sunt sterse automat din controller dupa 8 secunde; un nou restore anuleaza
  timerul anterior. Loading-ul din notice foloseste o bara de progres
  nedeterminata pana la finalul operatiei.
- Dupa import reusit, flow-ul `Account & Backup` invalideaza providerii care
  citesc datele SQLite restaurate: istoric, planuri, exercitii, sesiune activa,
  progres, streak si setup. Providerii derivati se recalculeaza prin dependente.
- `completedWorkoutCountProvider` este invalidat si dupa finalizarea sau
  stergerea unui workout, astfel count-ul din `Back up now` se actualizeaza fara
  a astepta un restore.
- Testele acopera disparitia tuturor rezultatelor terminale, refresh-ul
  count-ului dupa import si recitirea istoricului si planului dupa invalidare.
- Formatter: 10 fisiere Dart verificate, 2 reformate.
- Analyzer: `No issues found`.
- Teste: 33/33 focalizate, suita completa 191/191.

**Urmatorul pas:** verificarea vizuala pe dispozitiv a finalizarii/stergerii
unui workout si a restore-ului pentru istoric, plan si sesiune activa. Apoi
detectarea conflictului dupa sign in. Backup 03 ramane `in progress`.

### 2026-09-30 - Backup 03: feedback pentru restore in Account & Backup

- `ProgressProtectionNotice` afiseaza starile restore-ului: loading cu spinner,
  backup absent, eroare si succes. Guest si emailul neverificat raman prioritare,
  iar feedback-ul restore-ului are prioritate fata de o eroare veche de backup.
- In `BackupSection`, apasarile suplimentare pe restore si pornirea upload-ului
  sunt ignorate cat timp restore-ul ruleaza. Dialogul existent cere confirmare
  inainte de apelul controllerului.
- Testele widget acopera tranzitiile notice-ului si verificarea ca alegerea
  `Keep local data` nu porneste download-ul, iar confirmarea produce importul.
- Formatter: 5 fisiere Dart verificate, 2 reformate.
- Analyzer: `No issues found`.
- Teste: 21/21 focalizate pentru notice si sectiunea backup; suita completa
  188/188.

**Urmatorul pas:** invalidarea sau reincarcarea providerilor locali dupa import,
apoi flow-ul de detectare a conflictului dupa sign in. Backup 03 ramane
`in progress`.

### 2026-09-29 - Backup 03: teste pentru controllerul de restore

- Testele `CloudRestoreController` acopera starea initiala fara download,
  restore-ul reusit, lipsa backup-ului, accesul guest si emailul neverificat,
  erorile de download/import, blocarea unui al doilea restore si schimbarea
  UID-ului in timpul download-ului. Fake-urile existente au fost extinse numai
  pentru a controla download-ul si importul in aceste scenarii.
- Nu a fost schimbat controllerul si nu a fost conectat UI-ul de restore.
- Formatter: cele doua fisiere Dart de test verificate, unul reformatat.
- Analyzer: `No issues found`.
- Teste: 9/9 pentru controllerul de restore; suita completa 185/185.

**Urmatorul pas:** dialog de confirmare in `BackupSection` inainte de apelul
`restoreNow()`, apoi feedback-ul UI si reincarcarea providerilor dupa import.

### 2026-09-29 - Backup 03: primul test al controllerului de restore

- A fost adaugat un test pentru `CloudRestoreController.restoreNow()` cu
  repository-uri fake: un utilizator verificat descarca backup-ul propriului UID,
  apoi importa exact snapshot-ul primit si ajunge in starea `restored`.
- Testul nu foloseste Firebase sau SQLite real. Cazurile fara backup, erorile,
  schimbarea contului in timpul download-ului si UI-ul raman pasi urmatori.
- Formatter: fisierul Dart de test a fost formatat.
- Analyzer: `No issues found`.
- Testul focalizat: 1/1 trecut.

**Urmatorul pas:** testeaza `noBackup`, unde repository-ul remote intoarce null
si importul local nu este apelat.

### 2026-09-29 - Backup 03: decizia pentru Keep local data

- Utilizatorul a confirmat ca alegerea `Keep local data` dupa sign in pastreaza
  atat datele locale, cat si backup-ul cloud existent. Sign in si alegerea nu
  sterg backup-ul si nu declanseaza un upload implicit care l-ar inlocui.
- Backup 03 a inceput cu stabilirea acestui comportament. Urmeaza restore-ul
  manual cu confirmare explicita, apoi detectarea conflictului dupa sign in.
- In acest pas s-a modificat numai planul; formatter-ul nu a fost necesar,
  analyzer-ul si testele nu au fost rulate.

**Urmatorul pas:** implementarea ghidata a restore-ului manual, incepand cu
coordonarea `downloadBackup()` -> `importSnapshot()` si starile operatiei.

### 2026-09-29 - Handoff Backup 02 -> Backup 03

- Backup 02 este `done` la nivel de implementare si verificari automate.
  `CloudBackupController.backupNow()` exporta snapshot-ul SQLite si il incarca
  prin `FirebaseCloudBackupRepository`; metadata-ul si ultima data cunoscuta
  sunt afisate in `BackupSection`, iar erorile apar in
  `ProgressProtectionNotice`. Endpoint-ul de download exista in repository,
  dar nu este inca legat de UI. Commitul de baza pentru etapa urmatoare este
  `a07cd25` (include si commiturile Backup 02 anterioare).
- Backup 03 incepe cu flow-ul de restore. `downloadBackup()` descarca,
  decomprima, decodeaza si valideaza snapshot-ul; `importSnapshot()` il scrie
  tranzactional in SQLite. Butonul `Restore from cloud backup` din
  `BackupSection` are momentan `onTap: () {}`. Lipsesc coordonarea operatiilor,
  confirmarea explicita, gestionarea conflictului date locale/cloud, starile UI
  si reincarcarea providerilor dupa import.
- Inainte de implementarea unui restore automat la login, trebuie clarificat
  ce inseamna `Keep local data`, cum se atribuie datele locale unui Firebase UID
  dupa schimbarea contului si cand se face primul backup. Planul actual cere
  alegerea utilizatorului cand exista si date locale, si backup remote; nu
  autorizeaza inlocuirea tacita a datelor locale.
- Verificarea offline pe dispozitiv dupa hot restart ramane un smoke test
  recomandat pentru Backup 02; timeout-ul si notice-ul au test widget. Regulile
  Storage sunt versionate in `storage.rules`, dar deploy-ul si testarea live a
  regulilor nu au fost confirmate. Aceste verificari nu schimba faptul ca
  restore-ul poate fi proiectat si inceput acum.
- Migrarea SQLite pentru coloanele `automatic_backup_enabled` si
  `backup_pending` pe instalari existente ramane restanta pentru etapa de
  backup automat (etapa 9); trebuie rezolvata inainte de verificarea completa
  a aplicatiei pe instalari vechi si inainte de release. Account deletion si
  stergerea backup-ului remote sunt in etapa 8, separat de Backup 03.
- Ultima verificare a codului Backup 02: formatter 5 fisiere Dart (0 schimbari),
  analyzer `No issues found`, suita Flutter 176/176 trecute. Acest handoff
  modifica doar documentatia; nu au fost rulate din nou verificari de cod.

**Urmatorul pas:** stabilirea deciziei pentru cazul local + cloud, apoi
implementarea ghidata a restore-ului in `Backup 03`.

### 2026-09-29 - Backup 02: notice la blocarea verificarii cloud offline

- `CloudBackupController.build()` opreste asteptarea metadata-ului dupa 15 secunde
  cu `retryLimitExceeded`. Retry-ul automat Riverpod este dezactivat pentru acest
  provider, astfel eroarea ramane vizibila in notice. Data cunoscuta din
  SharedPreferences ramane afisata ca informatie locala.
- Upload-ul pornit din `FirebaseCloudBackupRepository` are un deadline de 30 de
  secunde; la expirare incearca anularea taskului si intoarce aceeasi eroare
  tipizata. Textul existent recomanda verificarea conexiunii si reincercarea.
- Subtitlul din `BackupSection` afiseaza explicit `Checking cloud…` cat timp
  metadata-ul se incarca, inclusiv cand exista o data in cache. Testul widget
  reproduce apasarea pe `Back up now` in timpul verificarii blocate si confirma
  ca apare notice-ul dupa timeout.
- Fisiere: controller-ul cloud, repository-ul Firebase, sectiunea UI, fake-ul
  repository si testul widget. Restore-ul si backup-ul automat raman in progress.

**Urmatorul pas:** verificare offline pe device dupa hot restart si, separat,
migrarea SQLite necesara preferintelor automate.

### 2026-09-29 - Backup 02: data ultimului backup pastrata local

- Utilizatorul a ales SharedPreferences pentru data ultimului backup cunoscut.
  `SharedPreferencesLastBackupDateRepository` foloseste API-ul async deja folosit
  de rest timer si cate o cheie `cloud_backup.last_uploaded_at.v1.<Firebase UID>`.
  Nu este generat un UUID nou; cache-ul nu intra in snapshot si nu modifica
  `app_settings`.
- `CloudBackupController` actualizeaza cache-ul dupa citirea cu succes a
  metadata-ului si dupa upload reusit; un raspuns cloud valid fara backup sterge
  data veche. Eroarea de retea sau de upload lasa cache-ul neschimbat. Un esec la
  scrierea cache-ului nu transforma un backup cloud reusit intr-un esec.
- `BackupSection` afiseaza `Last known backup` din cache pentru UID-ul curent
  cat timp cloud-ul este in loading sau error. Dupa raspunsul cloud, afiseaza
  `Last successful backup` sau `No cloud backup yet`. Datele nu sunt prezentate
  ca verificate live in perioada offline.
- Testele controller-ului acopera actualizarea, stergerea, pastrarea la eroare
  si independenta succesului cloud fata de esecul cache-ului. Widget tests
  acopera afisarea pe loading/error si izolarea intre doua UID-uri.
- Formatter: 8 fisiere Dart modificate verificate, 4 reformate.
- Analyzer: `No issues found`.
- Teste focalizate controller + sectiune UI: 15/15 au trecut; suita completa:
  175/175 au trecut.

**Urmatorul pas:** test offline pe device dupa hot restart, apoi migrarea SQLite
pentru coloanele noi din `app_settings`. Backup 02 ramane in progress.

### 2026-09-29 - Backup 02: retry limitat si Storage Rules versionate

- La cererea utilizatorului, `firebaseStorageProvider` configureaza retry-ul SDK:
  15 secunde pentru operatii precum metadata si 30 secunde pentru upload. Aceste
  valori limiteaza retry-ul, nu reprezinta un deadline strict pentru tot request-ul.
- A fost adaugat `storage.rules`, cu regulile furnizate anterior pentru consola:
  numai proprietarul cu email verificat poate citi/crea/inlocui
  `users/{userId}/backups/latest.json.gz`; upload-ul trebuie sa fie nenul, maximum
  2 MiB si `application/gzip`. Listarea, stergerea si alte cai nu sunt permise.
- `firebase.json` referentiaza fisierul de reguli, pastrand configuratia Flutter.
  Nu s-a facut deploy si nici citirea regulilor live din consola in acest task.
  Pentru publicare ulterioara explicita, comanda din radacina proiectului este
  `firebase deploy --only storage --project lifting-tracker-dev`.
- Logout-ul actual inchide sesiunile Firebase/Google, fara sa stearga SQLite sau
  `app_settings`. Cache-ul metadata trebuie asociat UID-ului Firebase pentru a nu
  afisa timestamp-ul altui cont. UID nu inseamna un UUID nou generat de aplicatie.
- Pentru cache se recomanda SharedPreferences, deja dependenta a proiectului:
  metadata recuperabila, separata de snapshot si fara migrare SQLite. Salvarea in
  `app_settings` este posibila, dar necesita coloane/migrare si excluderea din
  snapshot. Alegerea si implementarea cache-ului raman de confirmat.
- Formatter: un fisier Dart verificat, fara modificari suplimentare.
- Analyzer: `No issues found`.
- Teste focalizate cloud backup + flow: 95/95 au trecut. Configuratia JSON si
  referinta fisierului de reguli au fost verificate. Security Rules nu au fost
  testate cu Emulator Suite; timeout-ul offline nu a fost masurat pe device.

**Urmatorul pas:** hot restart si verificare offline pe device; alegerea cache-ului
pentru metadata si implementarea migrarii SQLite ramase. Backup 02 este in progress.

### 2026-09-29 - Backup 02: checkpoint UI si diagnostic offline

- Backup-ul manual este conectat la `CloudBackupController.backupNow()`, iar
  sectiunea BACKUP afiseaza metadata, numarul local de workout-uri si preferinta
  persistenta pentru backup automat. Declansarea automata si restore-ul din UI
  raman neimplementate.
- Utilizatorul a raportat ca fara internet request-ul ramane in loading si
  Android logheaza `network unavailable, sleeping`. SDK-ul continua retry-ul;
  aceste mesaje nu reprezinta inca un `AsyncError` pentru notice. Provider-ul
  FirebaseStorage nu configureaza momentan alte durate de retry.
- S-a recomandat reducerea ferestrelor de retry la nivelul SDK-ului si, separat,
  un cache persistent al metadata-ului asociat UID-ului pentru afisare offline.
  Aceste propuneri nu au fost implementate sau confirmate in acest checkpoint.
  Un cache ar reprezenta ultima stare cunoscuta, nu o verificare live a cloud-ului.
- Storage Rules exista conform discutiei in consola, dar nu sunt inca versionate
  local. Pentru versionare: `storage.rules` la radacina si
  `"storage": {"rules": "storage.rules"}` in `firebase.json`. Publicarea prin CLI
  este separata de commit; nu s-a executat deploy in acest task.
- Suita completa a identificat un test SQLite neactualizat pentru coloanele
  locale `automatic_backup_enabled` si `backup_pending`. Testul verifica acum
  explicit pastrarea unor valori locale diferite de default in timpul importului,
  alaturi de round-trip-ul snapshot-ului si rollback-ul integral.
- Coloanele noi sunt prezente in schema de creare, dar versiunea bazei ramane 2:
  migrarea pentru instalari existente v2 trebuie implementata inainte de inchiderea
  etapei. Valoarea implicita actuala pentru automatic backup este 1.
- Formatter: 17 fisiere Dart din checkpoint verificate, 4 reformate.
- Analyzer: `No issues found`.
- Teste: suita completa a trecut, 169/169, dupa actualizarea testului SQLite.
- Commit-ul de checkpoint include UI-ul backup si dependentele sale; modificarile
  independente din pagina de verificare email, header-ul contului, week progress
  si `pubspec.lock` raman in working tree.

**Status:** Backup 02 ramane `in progress`, in special pentru comportamentul
offline, migrarea SQLite si versionarea/testarea Storage Rules.

### 2026-09-29 - Backup 02: notice-uri pentru erorile cloud

- Utilizatorul a confirmat upload-ul live dupa activarea Storage si configurarea
  regulilor. In acest task nu a fost repetat upload-ul live.
- `ProgressProtectionNotice` si selectorul sau au fost mutate din
  `features/authentication` in `flows/account_and_backup`; pagina foloseste noul
  import. Notice-ul combina acum autentificarea cu erorile cloud backup.
- Prioritatea ramane guest, email neverificat, apoi eroare de backup. Codul
  `emailNotVerified` reutilizeaza notice-ul cu actiunile existente de verificare.
- Mapper-ul `presentation/backup_error_message.dart` traduce toate codurile
  `CloudBackupErrorCode` si exceptiile neasteptate in titlu si descriere.
  Timeout-ul nu este prezentat drept dovada lipsei internetului, iar cota
  serviciului nu este descrisa ca spatiu personal epuizat.
- Layout-ul existent este reutilizat, cu descrieri fara trunchiere. Erorile
  cloud sunt afisate inline, fara SnackBar; dispar in timpul reincercarii si
  dupa succes. Absenta unui backup nu este tratata ca eroare.
- La cererea utilizatorului, controller-ul nu separa citirea metadata de
  upload. Textele sunt generale si notice-ul nu introduce un retry ambiguu.
  Subtitlurile loading/error din `BackupSection` au fost aliniate acestei alegeri.
- Testele widget au fost mutate in `test/flows/account_and_backup` si extinse:
  toate cele 15 teste focalizate au trecut, fara Firebase real.
- Formatter: 6 fisiere Dart verificate, 3 reformate.
- Analyzer: `No issues found`.
- Backup 02 ramane in progress; restore-ul si declansarea automata dupa workout
  nu au fost implementate in acest task.

**Urmatorul pas recomandat:** verificarea vizuala a notice-urilor in aplicatie
si continuarea verificarilor necesare inchiderii Backup 02, apoi flow-ul restore.

### 2026-09-22 - Backup 02: limite gzip confirmate

- Utilizatorul a confirmat limitele de 2 MiB comprimat si 20 MiB decomprimat.
- Implementarea ghidata continua cu adaptarea upload-ului inceput de utilizator:
  validare, verificarea limitei JSON, gzip, verificarea limitei gzip, upload si
  returnarea metadata-ului rezultat.
- A fost actualizat numai planul. Formatter: nenecesar. Analyzer si teste:
  nerulate in acest pas.

**Urmatorul pas recomandat:** finalizarea upload-ului gzip, apoi download cu
decomprimare limitata si teste pentru limitele de dimensiune.

### 2026-09-22 - Backup 02: compresie gzip confirmata

- Utilizatorul a ales gzip pentru snapshot-ul remote; implementarea compresiei
  urmeaza, fara schimbarea structurii JSON v1.
- Limitele comprimat/decomprimat raman in discutie. Propunerea de 2 MiB/20 MiB
  reduce plafonul fata de propunerea anterioara de 10 MiB/50 MiB.
- Limita fisierului comprimat trebuie impusa in Storage Rules, nu numai in
  client. Limita decomprimarii protejeaza resursele aplicatiei la restore;
  Storage Rules nu inspecteaza JSON-ul din gzip.
- Limita per obiect nu reprezinta protectie completa impotriva upload-urilor
  repetate sau a crearii multor conturi. App Check si masurile de control al
  abuzului raman necesare inainte de production.
- A fost actualizata numai documentatia; formatter-ul nu a fost necesar,
  analyzer-ul si testele nu au fost rulate.

**Urmatorul pas recomandat:** confirmarea limitelor de dimensiune, apoi
implementarea compresiei si decomprimarii cu limita de output.

### 2026-09-22 - Backup 02: contract remote si teste pentru mapper

- Utilizatorul a adaugat `CloudBackupRepository`, `CloudBackupMetadata`,
  `CloudBackupException` si mapper-ul erorilor Firebase Storage.
- Contractul expune upload, download si citirea metadata-ului pentru un UID.
  Download-ul si citirea metadata-ului permit `null` pentru un backup absent;
  tratarea efectiva a absentei va fi implementata in repository.
- A fost adaugat
  `test/features/cloud_backup/data/firebase_storage_error_mapper_test.dart`:
  zece cazuri de mapare si un caz de fallback pentru un cod necunoscut.
- Testele construiesc exceptii Firebase local, fara initializare Firebase,
  retea, emulator sau dependente noi.
- Formatter: fisierul de test verificat, fara modificari necesare.
- Analyzer: `No issues found`.
- Teste focalizate: toate cele 11 teste au trecut. Suita completa nu a fost
  rulata in acest pas.

**Urmatorul pas recomandat:** implementarea ghidata a repository-ului Firebase
Cloud Storage, incepand cu dependenta SDK si citirea metadata-ului.

### 2026-09-22 - Backup 02: un singur backup remote (in progress)

- Utilizatorul a confirmat ca produsul final pastreaza numai ultimul backup
  reusit per UID, destinat reinstalarii aplicatiei sau mutarii pe alt dispozitiv.
- Fiecare upload reusit inlocuieste snapshot-ul de la aceeasi cale fixa; nu
  exista istoric, selectie de versiuni sau politica de retention pentru mai
  multe snapshot-uri.
- A fost actualizat numai acest plan; implementarea Dart nu a fost modificata.
- Formatter: nu a fost necesar.
- Analyzer: nu a fost rulat, deoarece au fost modificate numai documente.
- Teste: nu au fost rulate, deoarece au fost modificate numai documente.

**Urmatorul pas recomandat:** definirea contractului repository-ului remote
pentru un singur backup per UID, apoi implementarea ghidata a transportului
Firebase Cloud Storage si a testelor aferente.

### 2026-09-22 - Backup 01: snapshot si import local (done)

- A fost definit formatul v1 al snapshot-ului pentru cele sapte tabele de date
  si randul singleton `app_settings`.
- Exportul citeste toate tabelele intr-o singura tranzactie SQLite si produce
  record-uri tipizate, apoi JSON-ul complet cu versiune si timestamp.
- Decoderul verifica structura si tipurile, iar validatorul verifica ID-urile
  duplicate, randul `app_settings` si toate relatiile dintre tabele, inclusiv
  `workout_sessions.day_id`, care poate fi null.
- Importul valideaza snapshot-ul inainte sa modifice baza, sterge si reintroduce
  datele in ordinea foreign key-urilor si actualizeaza `app_settings` in aceeasi
  tranzactie.
- Testul SQLite local verifica flow-ul complet
  `export -> encode -> decode -> validate -> import`, restaurarea tuturor
  tabelelor si rollback-ul complet la o eroare SQL aparuta spre finalul
  importului.
- Formatter: fisierele Dart modificate au fost formatate.
- Analyzer: `No issues found`.
- Teste cloud backup: toate cele 56 de teste au trecut.
- Suita completa: toate cele 133 de teste au trecut.

**Urmatorul pas recomandat:** incepe `Backup 02` cu deciziile pentru fisierul
remote, apoi implementeaza repository-ul Firebase Cloud Storage, controller-ul
si backup-ul manual.

### 2026-09-11 - Auth 04: Guest and account UX (done)

- Autentificarea a fost integrata la finalul onboarding-ului prin pagina
  `Protect your progress`, cu optiuni Google, email/parola si continuare ca guest.
- Flow-ul email/parola permite creare cont si sign in, valideaza local campurile
  obligatorii si confirmarea parolei si afiseaza erorile normalizate ale
  controller-ului.
- Au fost adaugate verificarea emailului, retrimiterea emailului de verificare,
  continuarea temporara cu email neverificat si modalul functional de resetare a
  parolei.
- Din aplicatie, `Account & Backup` afiseaza starea guest/account, providerii de
  sign-in, starea verificarii emailului si permite autentificarea si sign out.
- Change password este functional pentru conturile email/parola. Modalul
  valideaza campurile obligatorii si confirmarea, afiseaza erorile pe campul
  relevant, expune loading si succes, iar repository-ul face reautentificarea
  inainte de actualizarea parolei. Delete account ramane mock-up dezactivat si
  legat de stergerea backup-urilor remote.
- Componentele de feedback si actiunile de verificare au fost extrase pentru
  reutilizare intre onboarding si `Account & Backup`. Dependentele respecta
  directia `flow -> feature`.
- Flow-urile au fost verificate manual pe emulator. Smoke test-ul live pentru
  schimbarea parolei a confirmat integrarea Firebase, inclusiv reautentificarea
  cu parola curenta si autentificarea ulterioara cu parola noua.
- Widget tests acopera deciziile principale din Auth 04: starea guest si
  actiunile disponibile per provider, notice-ul de protectie, validarea si
  loading-ul paginii email/parola, precum si validarea, eroarea credentialului
  curent si succesul modalului de schimbare a parolei.
- Formatter: toate cele 51 de fisiere Dart modificate au fost verificate; trei
  fisiere de test au fost reformate.
- Analyzer: `No issues found` la verificarea din 2026-09-11.
- Suita completa: toate cele 77 de teste au trecut la verificarea din
  2026-09-11.
- Implementarea Auth 04 a fost salvata si publicata pe `main` in commit-ul
  `9bf31ab` (`feature(auth): add UI for logging or signing in from the onboarding
  or inside the app.`).

**Urmatorul pas recomandat:** incepe `Backup 01` cu auditarea datelor locale,
definirea contractului snapshot-ului si implementarea exportului/importului
local tranzactional, insotite de teste si fara UI de backup.

### 2026-08-09 - Auth 03: Google Sign-In and provider linking

- Providerul Google a fost activat in Firebase. Configuratia iOS include client
  ID-ul si URL scheme-ul Google in `Info.plist`, iar configuratia Android include
  clientii OAuth generati dupa adaugarea fingerprint-urilor SHA-1 si SHA-256.
  Aceste fisiere contin configuratie publica Firebase, nu secrete private.
- A fost adaugat `google_sign_in` 7.2.0. Adapterul `GoogleIdentityClient` izoleaza
  SDK-ul, iar `GoogleSignInClient` initializeaza clientul lazy, obtine ID token-ul
  si poate inchide sesiunea Google.
- `AuthUser` include un set read-only de provideri mapati din `providerData` prin
  tipurile proprii aplicatiei.
- `AuthRepository`, `FirebaseAuthRepository` si `AuthController` expun login si
  linking Google fara tipuri SDK. Linking-ul opereaza pe utilizatorul Firebase
  curent prin `linkWithCredential`, pastrand acelasi UID.
- Erorile Google, token-ul lipsa, lipsa utilizatorului curent si conflictele de
  linking sunt traduse la `AuthException` si `AuthErrorCode`.
- Fake-ul repository-ului si testele controller-ului acopera delegarea,
  anularea pastrata ca eroare tipizata si ignorarea unui al doilea submit cat
  timp login-ul Google este pending.
- Nu au fost folosite Firebase Auth live sau Auth Emulator. Smoke test-ul runtime
  Google este amanat pentru `Auth 04`, cand exista UI-ul de autentificare; va fi
  facut pe iOS mai intai si apoi pe Android. Tot atunci trebuie confirmat live si
  flow-ul Email/Password.
- Formatter: 18 fisiere Dart verificate; 1 fisier a fost reformatat.
- Analyzer: `No issues found`.
- Teste authentication: toate cele 43 de teste au trecut.
- Suita completa: toate cele 50 de teste au trecut.

**Urmatorul pas recomandat:** `Auth 04 - Guest and account UX`, urmat de smoke
testele live pentru Email/Password si Google Sign-In pe UI-ul rezultat.

### 2026-08-08 - Auth 02: Email and password

- Contractul `AuthRepository` a fost extins cu creare cont email/parola, login,
  trimitere email de verificare, reload utilizator, resetare parola si logout.
- `FirebaseAuthRepository` implementeaza toate operatiile si traduce numai
  `FirebaseAuthException` in erorile proprii aplicatiei; erorile neasteptate nu
  sunt ascunse.
- Lipsa unui utilizator curent la verificare sau reload produce
  `AuthErrorCode.noAuthenticatedUser`.
- Au fost adaugate validarea locala a campurilor obligatorii, verificarea
  confirmarii parolei si normalizarea emailului. Parolele sunt transmise fara
  modificari.
- `AuthController` coordoneaza operatiile prin `AsyncValue<void>`, captureaza
  erorile de validare si repository, expune loading si previne submit-urile
  duplicate.
- Fake-ul repository-ului este reutilizabil intre teste, inregistreaza
  apelurile si poate simula o eroare sau o operatie ramasa pending.
- Au fost testate regulile locale, maparea tuturor codurilor Firebase sustinute,
  starea controller-ului, normalizarea argumentelor, propagarea erorilor,
  blocarea submit-urilor duplicate si delegarea operatiilor.
- Operatiile nu au fost apelate live impotriva Firebase Auth si nu a fost folosit
  Auth Emulator. Activarea provider-ului Email/Password in Firebase Console
  trebuie confirmata inaintea smoke test-ului runtime din viitorul flow UI.
- Formatter: 11 fisiere Dart verificate; 3 fisiere au fost reformate.
- Analyzer: `No issues found`.
- Teste authentication: toate cele 29 de teste au trecut.
- Suita completa: toate cele 36 de teste au trecut.

**Urmatorul pas recomandat:** `Auth 03 - Google Sign-In and provider linking`,
pastrand acelasi contract fara tipuri SDK si reutilizand controller-ul de
operatii. Configurarea si smoke test-ul live pentru Email/Password trebuie
confirmate cel tarziu inainte de integrarea UI din `Auth 04`.

### 2026-08-07 - Auth 01: Firebase foundation

- Proiectul Flutter a fost conectat la proiectul Firebase
  `lifting-tracker-dev` prin FlutterFire CLI.
- Identificatorul Android a fost stabilit la `com.luca.liftingtracker`, iar
  configuratia Android si `MainActivity` au fost aliniate cu acesta.
- Au fost adaugate `firebase_core` si `firebase_auth`; Firebase este initializat
  inainte de `runApp` folosind optiunile generate de FlutterFire.
- Au fost definite modelul `AuthUser` si contractul `AuthRepository`, separate
  de tipurile SDK-ului Firebase.
- `FirebaseAuthRepository` adapteaza `FirebaseAuth.userChanges()` la
  `Stream<AuthUser?>`; `null` reprezinta starea guest.
- Starea de autentificare este detinuta in Riverpod prin providerii pentru
  `FirebaseAuth`, `AuthRepository` si stream-ul de auth state.
- Testele folosesc un `FakeAuthRepository` injectat prin provider override si nu
  apeleaza Firebase real.
- Au fost verificate doua scenarii: utilizator autentificat si utilizator guest.
- Aplicatia a pornit normal pe Android dupa initializarea Firebase. Celelalte
  platforme inregistrate de FlutterFire nu au fost validate runtime in acest
  task.
- Nu au fost implementate flow-uri email/parola, Google Sign-In, UI de cont,
  backup sau restore.
- Formatter: 7 fisiere Dart verificate, 0 modificari necesare.
- Analyzer: `No issues found`.
- Teste: toate cele 9 teste au trecut.

**Urmatorul pas recomandat:** `Auth 02 - Email and password`, incepand cu
contractele operatiilor si regulile de validare, inaintea UI-ului.

### 2026-08-04 - Plan initial

- Au fost definite scope-ul si principiile offline-first.
- A fost ales Firebase Authentication impreuna cu Firebase Cloud Storage.
- A fost ales planul Blaze si directia unui bucket european.
- Au fost stabilite metodele de autentificare planificate.
- A fost stabilita implementarea initiala a unui backup manual, urmata ulterior
  de backup automat cu pending flag si retry.
- Nu a fost modificat codul aplicatiei.
- Formatter: nu a fost necesar.
- Analyzer: nu a fost rulat, deoarece au fost modificate numai documente.
- Teste: nu au fost rulate, deoarece au fost modificate numai documente.

**Urmatorul pas recomandat:** inchiderea intrebarilor de arhitectura strict
necesare pentru `Auth 01 - Firebase foundation`, apoi configurarea ghidata a
proiectului Firebase si definirea ownership-ului starii de autentificare.
