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

**Ultima actualizare:** 2026-09-22

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
- Actiunea manuala va fi expusa initial printr-un control cu sensul
  `Sync with cloud`; textul final din UI ramane de stabilit.
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

1. Care este textul final: `Sync with cloud`, `Back up now` sau alta formulare?
2. Ce inseamna exact `Keep local data` pentru backup-ul remote existent?
3. Se face automat un prim backup dupa autentificare sau numai la apasarea
   explicita a butonului?
4. Care este regiunea europeana exacta a bucket-ului?
5. Cum marcam local ownership-ul bazei pentru a preveni asocierea ei cu un UID
    diferit dupa logout/login?
6. Ce se intampla cu datele locale cand utilizatorul isi sterge contul?
7. Cum tratam un telefon vechi care incearca sa faca backup dupa ce datele au
    fost restaurate pe un telefon nou?
8. Care sunt momentele exacte de retry pentru un backup pending?
9. Care sunt textele finale si prioritatea vizuala pentru `last successful
    backup`, backup pending, backup esuat si restore in progres?
10. Cand introducem Sign in with Apple in raport cu publicarea pe iOS?

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
| 6 | Upload/download manual, controller/status si UI pentru backup manual | in progress |
| 7 | Detectare backup, conflicte, restore si UI-ul aferent | not started |
| 8 | Account lifecycle ramas: account deletion si stergerea datelor remote | not started |
| 9 | Backup automat, pending/retry si starile UI aferente | not started |
| 10 | Storage Rules, App Check, bugete si hardening | not started |
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
7. `Backup 03 - Restore flows, conflict UI and account lifecycle`
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
