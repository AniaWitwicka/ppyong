# Game sounds (HRHTA-105)

`make_sounds.py` synthesises the game sounds. It has no dependencies beyond
Python 3 and `ffmpeg`. It makes two families: **A "marimba"** and **B "pop"**.
The owner picked **B**, and it's the set in `app/assets/sounds/`.

| Sound      | When                                   | Length | Peak     |
|------------|----------------------------------------|--------|----------|
| `correct`  | right answer, "knew it", matched pair  | 260 ms | −3 dBFS  |
| `wrong`    | wrong answer, "again", mismatch        | 280 ms | −5 dBFS  |
| `tap`      | flip a card, pick a tile               | 50 ms  | −10 dBFS |
| `complete` | end of a batch / quiz / matching round | 1.2 s  | −3 dBFS  |

Correct goes up in pitch and wrong comes down. Wrong stays at 250 Hz or higher,
because phone speakers barely play anything lower.

## Rebuild

```bash
mkdir -p /tmp/ppyong-sounds && python3 docs/sounds/make_sounds.py /tmp/ppyong-sounds
```

```bash
for n in correct wrong tap complete; do d=$(ffprobe -v error -show_entries format=duration -of csv=p=0 /tmp/ppyong-sounds/B_$n.wav); ffmpeg -y -loglevel error -i /tmp/ppyong-sounds/B_$n.wav -af "afade=t=out:st=$(python3 -c "print(max(0,$d-0.012))"):d=0.012" -ac 1 -ar 44100 -b:a 96k app/assets/sounds/$n.mp3; done
```

Encoding settings: mono, 44.1 kHz, 96 kbps, 12 ms fade-out, no silence at the
start. After the next `flutter build web`, check that
`build/web/assets/assets/sounds/` isn't empty.
