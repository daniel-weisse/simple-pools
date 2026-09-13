import '../data/repository.dart';
import '../domain/backup.dart';
import '../domain/engine.dart';
import '../domain/models.dart';

class TournamentService {
  final TournamentRepository repository;
  TournamentService(this.repository);
  Future<List<Tournament>> load() async {
    await repository.archiveExpired(DateTime.now());
    return repository.all();
  }

  Future<void> save(Tournament t) {
    Backup.validate(t);
    return repository.save(t);
  }

  Tournament previewScore(Tournament t, String id, int a, int b) =>
      TournamentEngine.corrected(t, id, a, b);
  Future<void> restore(List<Tournament> tournaments) async {
    for (final t in tournaments) {
      Backup.validate(t);
    }
    await repository.importAll(tournaments);
  }
}
