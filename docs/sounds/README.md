# Game sounds (HRHTA-105)

`make_sounds.py` synthesises the game sounds. It has no dependencies beyond
Python 3 and `ffmpeg`. It makes three families: **A "marimba"**, **B "pop"**
(the first set in the app) and **C "paper & bell"**. Since 2026-11-09 the app
uses **C**, picked by the owner sound by sound.

| Sound      | When                                   | Sound in set C                | Length | Peak     |
|------------|----------------------------------------|-------------------------------|--------|----------|
| `correct`  | right answer, "knew it", matched pair  | one soft bell "ding"          | 600 ms | −3 dBFS  |
| `wrong`    | wrong answer, mismatch; "again" plays it at about half the volume | two wooden knocks going down | 300 ms | −5 dBFS  |
| `tap`      | Sounds switch sample, pick a tile      | very short paper tick         | 50 ms  | −10 dBFS |
| `flip`     | turn a flashcard over                  | soft paper swish              | 150 ms | −6 dBFS  |
| `complete` | end of the whole quiz / session / matching round | swish into a bell chord | 1.2 s  | −3 dBFS  |
| `batch`    | end of a batch with more still to come  | short swish and one bell     | 0.6 s  | −3 dBFS  |

Wins are bells, misses are soft wood, touches are paper. The app plays each
sound at its own volume (`GameFeedback.volumes`), scaled by the Profile volume
slider: the slider starts at 70% (the volumes above as tuned) and goes up to
each file's full level.

## Rebuild

```bash
mkdir -p /tmp/ppyong-sounds && python3 docs/sounds/make_sounds.py /tmp/ppyong-sounds
```

```bash
for n in correct wrong tap flip complete batch; do d=$(ffprobe -v error -show_entries format=duration -of csv=p=0 /tmp/ppyong-sounds/C_$n.wav); ffmpeg -y -loglevel error -i /tmp/ppyong-sounds/C_$n.wav -af "afade=t=out:st=$(python3 -c "print(max(0,$d-0.012))"):d=0.012" -ac 1 -ar 44100 -b:a 96k app/assets/sounds/$n.mp3; done
```

Encoding settings: mono, 44.1 kHz, 96 kbps, 12 ms fade-out, no silence at the
start. After the next `flutter build web`, check that
`build/web/assets/assets/sounds/` isn't empty.
