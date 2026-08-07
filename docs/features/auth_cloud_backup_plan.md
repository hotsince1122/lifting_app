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

**Ultima actualizare:** 2026-08-07

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
- Securitatea si controlul costurilor fac parte din feature, nu sunt pasi
  optionali de final.

## In afara scopului

- sincronizare live intre dispozitive;
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
- Proiectul Firebase va folosi planul Blaze.
- Cloud Storage va folosi un bucket aflat intr-o regiune europeana.
- Aplicatia poate fi folosita fara cont.
- Autentificarea va fi oferita in onboarding, dar pozitia exacta din onboarding
  nu este inca stabilita.
- Un utilizator care continua ca guest se poate autentifica ulterior din
  setari. Flow-ul UX exact nu este inca stabilit.
- Metodele planificate sunt:
  - email si parola;
  - Google Sign-In;
  - Sign in with Apple.
- Primele metode implementate vor fi email/parola si Google.
- Sign in with Apple va fi implementat ulterior. Configurarea si testarea live
  necesita Apple Developer Program si acces la macOS/Xcode.
- Providerii suplimentari trebuie legati contului existent prin provider
  linking, nu folositi pentru a crea accidental un al doilea Firebase UID.
- Utilizatorul isi va putea sterge contul din aplicatie.

### Backup si restore

- Prima iteratie va avea backup manual.
- Actiunea manuala va fi expusa initial printr-un control cu sensul
  `Sync with cloud`; textul final din UI ramane de stabilit.
- Backup-ul va fi un snapshot JSON.
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

### Continutul snapshot-ului

Lista exacta trebuie stabilita dupa auditarea completa a schemei. Directia este
sa includem datele necesare reconstruirii progresului:

- planurile si zilele configurate de utilizator;
- ordinea exercitiilor din planuri;
- exercitiile custom, daca exista;
- workout-urile finalizate;
- seturile salvate;
- preferintele persistente care fac parte din progres sau configurare.

Date temporare sau derivate, precum starea unui rest timer activ, notificari
programate sau cache-uri, nu ar trebui incluse implicit.

Pentru ca restore-ul este complet si nu exista merge, ID-urile locale existente
pot fi pastrate in snapshot si reintroduse la import. Nu este necesara migrarea
generala la UUID doar pentru acest feature.

### Forma conceptuala a metadata-ului

```json
{
  "backupFormatVersion": 1,
  "createdAt": "2026-08-04T00:00:00Z",
  "appVersion": "0.1.0",
  "installationId": "to-be-decided",
  "data": {}
}
```

Campurile finale si structura sectiunii `data` nu sunt inca stabilite.

## Securitate si controlul costurilor

Masurile planificate includ:

- Storage Rules care permit accesul numai cand `request.auth.uid` corespunde
  UID-ului din calea obiectului;
- cai de backup controlate de aplicatie, nu nume arbitrare nelimitate;
- limita maxima pentru dimensiunea unui backup, impusa si prin Storage Rules;
- un numar limitat de snapshot-uri per utilizator;
- validarea content type-ului si a metadata-ului permis de Storage Rules;
- Firebase App Check inainte de lansarea production;
- alerte de buget si monitorizarea usage-ului in Google Cloud;
- evitarea Phone Auth, care nu este necesara si are costuri SMS;
- email verification pentru conturile email/parola; momentul exact in care
  backup-ul devine permis ramane de confirmat;
- testarea regulilor cu Firebase Emulator Suite, daca flow-ul de dezvoltare o
  permite;
- stergerea backup-urilor asociate atunci cand este sters contul.

Configuratia publica generata de FlutterFire este pastrata in repository pentru
ca un clone nou sa poata construi aplicatia. Cheile private, service accounts,
keystore-urile si alte credentiale secrete nu se salveaza in repository.

## Intrebari deschise

Aceste puncte nu trebuie tratate drept decizii pana cand utilizatorul nu le
confirma:

1. Autentificarea apare la inceputul sau la finalul onboarding-ului?
2. Cum arata entry point-ul de Account/Backup din aplicatia deja configurata?
3. Care este textul final: `Sync with cloud`, `Back up now` sau alta formulare?
4. Ce inseamna exact `Keep local data` pentru backup-ul remote existent?
5. Se face automat un prim backup dupa autentificare sau numai la apasarea
   explicita a butonului?
6. Ce tabele si ce chei din SharedPreferences intra in primul format de backup?
7. Sunt incluse sesiunile active/neterminate sau numai workout-urile finalizate?
8. Snapshot-ul JSON este comprimat cu gzip din prima iteratie?
9. Cate snapshot-uri sunt pastrate: unul, doua sau trei?
10. Folosim sloturi fixe sau fisiere timestamped cu o politica de retention?
11. Care este dimensiunea maxima permisa pentru un backup?
12. Care este regiunea europeana exacta a bucket-ului?
13. Cum marcam local ownership-ul bazei pentru a preveni asocierea ei cu un UID
    diferit dupa logout/login?
14. Ce se intampla cu datele locale cand utilizatorul isi sterge contul?
15. Cum tratam un telefon vechi care incearca sa faca backup dupa ce datele au
    fost restaurate pe un telefon nou?
16. Care sunt momentele exacte de retry pentru un backup pending?
17. Unde si cum afisam `last successful backup` si starea `backup pending`?
18. Cand introducem Sign in with Apple in raport cu publicarea pe iOS?

## Roadmap si status

Statusurile permise sunt `not started`, `in progress`, `blocked`, `deferred` si
`done`.

| Etapa | Continut | Status |
| --- | --- | --- |
| 0 | Plan general, delimitarea scope-ului si deciziile initiale | done |
| 1 | Firebase foundation si contractele de autentificare | done |
| 2 | Email/parola: signup, verify, login, reset si logout | not started |
| 3 | Google Sign-In si provider linking | not started |
| 4 | UX guest/account in onboarding si settings | not started |
| 5 | Contractul snapshot-ului si export/import local tranzactional | not started |
| 6 | Upload/download manual in Cloud Storage | not started |
| 7 | Restore la login si restore manual dupa login | not started |
| 8 | Account deletion si stergerea datelor remote asociate | not started |
| 9 | Backup automat, pending flag si retry | not started |
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
6. `Backup 02 - Manual Cloud Storage backup`
7. `Backup 03 - Restore flows and account deletion`
8. `Backup 04 - Automatic backup and hardening`
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
