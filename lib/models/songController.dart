import 'package:audio_session/audio_session.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_media_notification/flutter_media_notification.dart';
import 'package:just_audio/just_audio.dart';
import 'package:musicPlayer/models/playListDB.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SongController extends ChangeNotifier {
  SongController() {
    init();
  }
  AudioPlayer player;
  Duration duration;
  int currentTime = 0;
  int songLenght = 0;
  int currentSongIndex;
  String timeLeft = '';
  String timePlayed = '';
  String playlistName; // this is assigned from playlist screen
  List allSongs; // this is assigned from playlist screen
  static bool isFavourite = false;
  bool isShuffled = false;
  bool isRepeat = false;
  bool isPlaying = false;
  Map nowPlaying = {};
  AppLifecycleState state;
  PlayListDB playListDB = PlayListDB();

  void init() async {
    await SharedPreferences.getInstance().then((pref) {
      isShuffled = pref.getBool('shuffle') ?? false;
      isRepeat = pref.getBool('repeat') ?? false;
    });
    notifyListeners();
  }

  void setIsPlaying(bool val) {
    isPlaying = val;
    notifyListeners();
  }

  Future<void> setUp(dynamic song) async {
    nowPlaying = song;
    isFavourite = await playListDB.isFavourite(nowPlaying);
    playListDB.saveNowPlaying(nowPlaying);
    currentSongIndex =
        allSongs.indexWhere((element) => element['path'] == nowPlaying['path']);
    player = AudioPlayer();
    duration = await player.setFilePath(nowPlaying['path']);
    songLenght = duration.inSeconds;
    timeLeft = '${duration.inMinutes}:${duration.inSeconds % 60}';
    getPosition();
    play();
    handleInterruptions();
  }

  void getPosition() {
    player.getPositionStream().listen(
      (event) async {
        currentTime = event.inSeconds;
        timePlayed = '${event.inMinutes}:${event.inSeconds % 60}';
        if (currentTime >= songLenght) {
          await skip(next: true);
          // refresh notification
          showNotification();
        }
        notifyListeners();
      },
    ).onError((error) => print('hmmmmm: $error'));
  }

  Future<void> play() async {
    setIsPlaying(true);
    player.play();
  }

  Future<void> pause() async {
    setIsPlaying(false);
    player.pause();
  }

  Future<void> seek({bool forward = false, bool rewind = false}) async {
    if (forward)
      await player.seek(Duration(seconds: currentTime + 10));
    else
      await player.seek(Duration(seconds: currentTime - 10));
  }

  Future<void> skip(
      {bool next = false, bool prev = false, BuildContext context}) async {
    currentSongIndex =
        allSongs.indexWhere((element) => element['path'] == nowPlaying['path']);
    List shuffled = [...allSongs];
    await disposePlayer();
    try {
      if (isRepeat) {
        nowPlaying = nowPlaying;
      } else if (isShuffled) {
        shuffled.shuffle();
        currentSongIndex = shuffled
            .indexWhere((element) => element['path'] == nowPlaying['path']);
        nowPlaying = next
            ? shuffled[currentSongIndex += 1]
            : shuffled[currentSongIndex -= 1];
      } else {
        nowPlaying = next
            ? allSongs[currentSongIndex += 1]
            : allSongs[currentSongIndex -= 1];
      }
    } on RangeError catch (e) {
      nowPlaying = allSongs.first;
      debugPrint(e.toString());
    } finally {
      await setUp(nowPlaying);
      notifyListeners();
    }
  }

  Future<void> playlistControlOptions(dynamic playlistNowPlaying) async {
    // if nothing is currently playing
    if (nowPlaying['path'] == null) {
      await setUp(playlistNowPlaying);
      setIsPlaying(true);
      // if the song currently playing is taped on
    } else if (nowPlaying['path'] == playlistNowPlaying['path']) {
      isPlaying ? pause() : play();
      // if a different song is selected
    } else if (nowPlaying['path'] != playlistNowPlaying['path']) {
      disposePlayer();
      await setUp(playlistNowPlaying);
      setIsPlaying(true);
    }
  }

  Future<void> stop() async {
    await player.stop();
  }

  Future<void> disposePlayer() async {
    if (player.playbackState == AudioPlaybackState.playing ||
        player.playbackState == AudioPlaybackState.paused) {
      await player.dispose();
    }
    setIsPlaying(false);
    currentTime = 0;
    timeLeft = '';
    timePlayed = '';
    notifyListeners();
  }

  void settings({bool repeat = false, bool shuffle = false}) {
    isShuffled = shuffle;
    isRepeat = repeat;
    notifyListeners();
  }

  void showNotification() {
    if (state != AppLifecycleState.paused)
      return;
    else
      MediaNotification.showNotification(
        title: nowPlaying['title'],
        author: nowPlaying['artist'],
        isPlaying: isPlaying,
      );
  }

  void handleInterruptions() {
    AudioSession.instance.then((session) async {
      player.playbackStateStream.listen((event) {
        // Activate session only if a song is playing
        if (event == AudioPlaybackState.playing) {
          session.setActive(true);
        }
      }).onError((e) => print(e));
      session.interruptionEventStream.listen((event) {
        if (event.begin) {
          // Another app started playing audio and we should pause.
          switch (event.type) {
            case AudioInterruptionType.duck:
            case AudioInterruptionType.pause:
            // online media like youtube false under unknown
            case AudioInterruptionType.unknown:
              pause();
              // refresh notification
              showNotification();
              break;
            default:
          }
        } else {
          // else block runs at the end of an interruption
          switch (event.type) {
            default:
          }
        }
      });
      session.becomingNoisyEventStream.listen((_) {
        // earphones unpluged
        pause();
      });
    });
  }
}
