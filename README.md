# TrainTribe

## Testing

Esegui i test unit e widget:

```
flutter test
```

Con coverage:

```
flutter test --coverage
```

Script PowerShell helper (dalla cartella `train_tribe`):

```
pwsh ./scripts/run_tests.ps1
```

Integration tests:

```
flutter test integration_test
```

Best practice:
- Mantieni i widget con Key per interazioni critiche (campi form / bottoni)
- Evita dipendenze Firebase dirette nei widget test usando adapter/mocking
- Aggiungi nuovi test per ogni bug fix (regressione)