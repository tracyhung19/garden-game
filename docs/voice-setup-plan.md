# Voice setup plan: local Mandarin TTS for Zi Garden

Status: reviewed draft (Sonnet drafted, Opus reviewed and corrected; see the review log at the end). Nothing in it has been run on the Mac yet. Date: 2026-09-29.
Scope: set up and test an open-source Mandarin voice-cloning TTS model on the family Mac BEFORE cloning the aunt's voice. All tests use the model's own demo/reference voices.

## 1. Summary

1. Recommended: **GPT-SoVITS** (RVC-Boss). MIT code, 5 s zero-shot, official MPS install path, and a (verify) custom-pinyin syntax like `角(jue2)` for polyphones. It also has a fine-tune path (about 1 min of audio) if zero-shot tones are weak.
2. Fallback: **Fun-CosyVoice 3.0** (FunAudioLLM). Documented Chinese pinyin "pronunciation inpainting". Apache-2.0 code. Mac support is not documented in the repo README, so it is second choice.
3. Why: tone correctness beats voice quality here, so the deciding factor is a way to force pinyin per character. Both offer it; GPT-SoVITS has the clearer Mac install script.
4. F5-TTS is not chosen: pretrained weights are CC-BY-NC (fine for personal use, but a licence risk if the game is ever shared) and pinyin control is unconfirmed. Fish Speech S2 is not chosen: research licence and no pinyin override (prosody tags only).
5. Nothing here is decided until the tone test set (section 5) passes on the family's own Mac. If GPT-SoVITS fails, we run the same test on CosyVoice 3.

### Research status (2026-09-29)

Web access worked for GitHub READMEs and search. huggingface.co was **blocked** from this environment, so model-card licences and file sizes are unverified. Anything not read directly is marked "(verify)". No version numbers or commands below were run; treat them as a checklist to confirm.

| Model | macOS support | Mode / reference length | Polyphone / pinyin | Code licence | Weights licence | Install |
|---|---|---|---|---|---|---|
| [GPT-SoVITS](https://github.com/RVC-Boss/GPT-SoVITS) | README: Apple Silicon supported; MPS or CPU. README warns that training on Mac GPU gives lower quality (they use CPU). Inference on MPS: verify | Zero-shot with ~5 s reference; few-shot fine-tune with ~1 min. Versions listed: v2, v3, v4, v2Pro (v4 fixes v3 metallic artifacts, 48 kHz output) | G2PW model for Chinese polyphones. Custom pinyin in TONE3 form in parentheses, e.g. `角(jue2)`, is in [PR #1728](https://github.com/RVC-Boss/GPT-SoVITS/pull/1728); a search result says it may be treated as English text in some versions. Merged status: verify | MIT | Pretrained weights licence: verify (HF page unreachable) | `install.sh --device MPS --source HF` (script requires conda); or manual pip; Docker (CPU only on Mac, no GPU passthrough) |
| [CosyVoice / Fun-CosyVoice 3.0](https://github.com/FunAudioLLM/CosyVoice) | README does not mention macOS (instructions target Ubuntu/CentOS, conda, Python 3.10). A search result mentions MLX/Torch-MPS paths in third-party work ([sglang-omni PR #1964](https://github.com/sgl-project/sglang-omni/pull/1964)); unofficial, verify | Zero-shot and cross-lingual cloning; reference length not stated in README (verify; typically a few seconds to ~30 s) | README: "pronunciation inpainting of Chinese Pinyin and English CMU phonemes". Exact syntax: verify | Apache-2.0 | Not stated in README; model card [Fun-CosyVoice3-0.5B-2512](https://huggingface.co/FunAudioLLM/Fun-CosyVoice3-0.5B-2512): verify | git clone with submodules, conda Python 3.10, pip requirements; needs sox |
| [F5-TTS](https://github.com/SWivid/F5-TTS) | README: Apple Silicon "native support" (PyTorch MPS) | Zero-shot, ~5-12 s reference plus its transcript (verify) | Not confirmed in README. Pinyin input: verify | MIT | **CC-BY-NC** (Emilia dataset). Personal use OK | `pip install f5-tts` (Python 3.10+, ffmpeg) |
| [f5-tts-mlx](https://github.com/lucasnewman/f5-tts-mlx) | MLX native | Needs mono 24 kHz WAV of ~5-10 s plus transcript | **Chinese support not documented** in README; treat as English-only unless proven | MIT | Weights follow F5-TTS (CC-BY-NC likely; verify) | `pip install f5-tts-mlx` |
| [Fish Speech / OpenAudio (now "S2 Pro")](https://github.com/fishaudio/fish-speech) | README does not state macOS support; docs at speech.fish.audio/install (verify) | Zero-shot, 10-30 s reference | Chinese is "Tier 1", no phoneme step. Control is via natural-language tags such as `[whisper]`, **not pinyin**. No override found | FISH AUDIO RESEARCH LICENSE (code and weights) | Same research licence; read it before use | Docs site; Docker/WebUI |

## 2. Prerequisites and machine check

Run on the family Mac (Terminal). Paste the output back before doing anything else.

```bash
uname -m                                   # arm64 = Apple Silicon, x86_64 = Intel
sysctl -n machdep.cpu.brand_string         # Intel shows CPU name; Apple shows "Apple M?"
system_profiler SPHardwareDataType | egrep "Model Name|Chip|Memory"
sw_vers                                    # macOS version
df -h ~ | tail -1                          # free disk
```

Also confirm: the Mac is not a work-managed device, there is a stable power supply (plugged in), and Wi-Fi can be toggled off for the offline test.

### Branching

| Result | Decision |
|---|---|
| `arm64`, M1-M4, **16 GB+ RAM**, >= 30 GB free, macOS 13+ (verify minimum for the chosen PyTorch) | Proceed with section 3 as written. |
| `arm64`, **8 GB RAM** | Try, but expect memory pressure. Close all other apps; use zero-shot only (no fine-tuning); generate in small batches; run with the smallest model version (v2 rather than v4/v2Pro, verify). If the model swaps heavily (Activity Monitor memory pressure red) or a word takes over about 30 s, stop and use another machine. Fine-tuning on 8 GB is not recommended. |
| `x86_64` (Intel) | **Not recommended.** No MPS/MLX; CPU inference is slow, and PyTorch's newer macOS Intel wheels may not exist (verify). Use a PC with an NVIDIA GPU (8 GB+ VRAM, Linux or Windows; GPT-SoVITS has a Windows integrated package) or run the batch on another Apple Silicon Mac. Generated MP3s are small, so the machine that generates them does not have to be the family Mac. |
| < 30 GB free disk | Free space or use an external SSD for `~/zi-voice` (see section 6 for the disk budget). |

Other prerequisites: Xcode Command Line Tools (`xcode-select --install`), an Apple ID is not needed, and a one-time internet connection to download code and weights.

## 3. Step-by-step setup (GPT-SoVITS on Apple Silicon)

All work lives in `~/zi-voice/`. Nothing is installed system-wide except Homebrew packages. Commands come from the repo README and install script as read on 2026-09-29; anything not confirmed is marked (verify).

### Python management choice: conda (Miniforge)

Pick **conda via Miniforge**. Reason: GPT-SoVITS's `install.sh` exits if conda is missing, and it can pull GCC from conda-forge. uv or pyenv would mean fighting the installer. Miniforge is free and arm64-native. The CosyVoice fallback also documents conda.

### Steps

| # | Step | Commands | Done when |
|---|---|---|---|
| 1 | Xcode CLT + Homebrew | `xcode-select --install`; install Homebrew from brew.sh | `brew --version` prints a version; `git --version` works |
| 2 | Tools | `brew install ffmpeg git-lfs sox` (sox needed for CosyVoice fallback; harmless here) then `git lfs install` | `ffmpeg -version` shows a build with `libmp3lame`; check `ffmpeg -encoders \| grep mp3` lists libmp3lame |
| 3 | Miniforge | `brew install --cask miniforge`; `conda init zsh`; reopen Terminal | `conda --version` works; `python -c "import platform;print(platform.machine())"` prints `arm64` (NOT x86_64, which would mean Rosetta) |
| 4 | Project folder | `mkdir -p ~/zi-voice/{refs,out,tests,logs} && cd ~/zi-voice` | Folder exists. Add it to Time Machine/iCloud exclusions (section 6) |
| 5 | Clone | `git clone https://github.com/RVC-Boss/GPT-SoVITS.git ~/zi-voice/GPT-SoVITS`; then `git rev-parse HEAD > ~/zi-voice/logs/gptsovits-commit.txt` | Commit hash saved (used for regression, T-12) |
| 6 | Env | `conda create -n gptsovits python=3.10 -y` then `conda activate gptsovits`. Python version per README: verify (3.10 assumed; README may say 3.9-3.11) | `python --version` matches the README |
| 7 | Install script | `cd ~/zi-voice/GPT-SoVITS && bash install.sh --device MPS --source HF` (flags confirmed from script: `--device` CU126/CU128/ROCM/MPS/CPU, `--source` HF/HF-Mirror/ModelScope). Downloads pretrained models, G2PW model, NLTK data. UVR5 is optional; skip it | Script finishes with no traceback. Log saved: `... 2>&1 \| tee ~/zi-voice/logs/install.log` |
| 8 | Check MPS | `python -c "import torch;print(torch.__version__, torch.backends.mps.is_available())"` | Prints `True` |
| 9 | Weights present | `du -sh GPT_SoVITS/pretrained_models` and list it | Folder is several GB; note exact size in the log. Confirm G2PW model folder exists (`GPT_SoVITS/text/G2PWModel`, verify path) |
| 10 | Demo reference voice | Use a short (3-10 s) clip with known transcript. Prefer the sample the project ships if any (verify), otherwise a public-domain/CC0 Mandarin clip from a non-family source. Convert to mono WAV: `ffmpeg -i in.wav -ac 1 refs/demo.wav` (keep the source sample rate). GPT-SoVITS rejects reference clips outside about 3-10 s, so trim to that range. Save its exact transcript in `refs/demo.txt` | `refs/demo.wav` and `refs/demo.txt` exist; length is 3-10 s |
| 11 | First run (WebUI) | `python webui.py` (verify entrypoint; README may use `webui.py zh_CN` or `api_v2.py`); open the TTS inference tab, load default v2/v4 models, upload demo reference + transcript, synthesize `你好，我是小花。` | A WAV plays with clear speech and no crash; terminal shows the device (see T-02) |
| 12 | First run (API, for the batch script) | Start `python api_v2.py -a 127.0.0.1 -p 9880` (verify script name and flags in README) and call it with `curl` | HTTP 200 and WAV saved. Bind to **127.0.0.1 only** so nothing on the LAN can use it |

If step 7 fails on MPS, retry `--device CPU` to separate "install broken" from "MPS broken", and record which one.

## 4. Batch-generation script design

File: `~/zi-voice/batch.py`, run inside the conda env. It talks to the local API (127.0.0.1) so the model loads once.

### Input CSV

```csv
hanzi,pinyin_override,text_type
猫,,word
长,zhang3,word
长大,zhang3 da4,word
银行,yin2 hang2,word
我喜欢音乐。,,sentence
```

- `hanzi`: the text to say. Also the output file stem.
- `pinyin_override`: optional, one TONE3 syllable per character, space separated (`ni3 hao3`). Numeric tones, `5` or none for neutral (`ma1 ma5`).
- `text_type`: `word` or `sentence`; controls padding and the text-split setting.

### Output

`out/<hanzi>.mp3`. If the same hanzi appears twice with different overrides (e.g. two readings of 长), add a suffix column later (`长_zhang3.mp3`); v1 rejects duplicates with an error. Filenames are the same hanzi the game already uses so the future bulk-import can match by name.

### Steps per row

1. Validate: count of overrides equals number of Chinese characters; syllables match `^[a-züv]+[1-5]?$`.
2. Build the model text (below).
3. Skip if `out/<hanzi>.mp3` exists and the row hash is unchanged (`out/.manifest.json`: hanzi, override, model commit, reference file hash). Allows resuming and regression diffs.
4. POST to the local API with the demo (later: aunt) reference audio + transcript, as absolute paths. Use `speed_factor` (about 0.8-0.9, verify the field in `api_v2.py`) for slower speech: the family asked for a slower voice, and slowing the model is cleaner than slowing the MP3 later. Words: add a full stop and a short leading pause so the first syllable isn't clipped (verify effect). Fix random seed (`seed=42`, verify parameter) so re-runs are repeatable.
5. Post-process with ffmpeg to MP3.
6. Log time, output duration, and peak memory to `logs/batch.csv`.

### Applying pinyin overrides (GPT-SoVITS)

Per [PR #1728](https://github.com/RVC-Boss/GPT-SoVITS/pull/1728), the intended form is the character followed by TONE3 pinyin in **ASCII parentheses**: `长(zhang3)大(da4)`. Rules for the script:

- With an override, rewrite every character: `银(yin2)行(hang2)`. Per-character annotation is safer than annotating only the ambiguous one.
- Without an override, send the plain text and rely on G2PW.
- **Verify first (test T-05a)**: check the PR is merged in the cloned commit (`grep -rn "custom_pinyin" GPT_SoVITS/text`). If not, fallback options in order: apply the PR as a patch; substitute a homophone character with the wanted reading (e.g. use a common character that always reads as the target syllable, then keep the file named by the real hanzi); or move to CosyVoice 3, whose pinyin syntax must be confirmed from its README/issues before use.
- If the parenthesis is spoken aloud as English or ignored, record it as a failed T-05a and treat it as a blocker for go/no-go.

### ffmpeg post-processing

```bash
ffmpeg -y -i raw.wav \
  -af "silenceremove=start_periods=1:start_threshold=-45dB:start_silence=0.05:stop_periods=1:stop_threshold=-45dB:stop_silence=0.15,loudnorm=I=-16:TP=-1.5:LRA=11" \
  -ac 1 -ar 24000 -c:a libmp3lame -b:a 48k out/猫.mp3
```

Notes: `loudnorm` single-pass is unreliable on 1-second clips; use two-pass (measure then apply with `measured_*` values) or `pyloudnorm` in Python. Very short clips can end up quieter than -16 LUFS; tolerance in T-09 is +/-2 LU. 24 kHz mono at 48 kbps is enough for speech and gives about 3-8 KB per word; use 44.1 kHz only if artefacts are audible on the iPhone speaker. Add a short fade-in/out (`afade=t=in:d=0.01`) if clicks appear.

### Sketch

```python
import csv, hashlib, json, subprocess, time, requests, pathlib, re

API = "http://127.0.0.1:9880"      # local only
REF = str(pathlib.Path("refs/demo.wav").resolve())   # the API server resolves paths itself, so pass an absolute path
REF_TXT = open("refs/demo.txt", encoding="utf-8").read().strip()

def model_text(hanzi, override):
    if not override:
        return hanzi
    chars = [c for c in hanzi if re.match(r"[一-鿿]", c)]
    syl = override.split()
    assert len(chars) == len(syl), f"{hanzi}: {len(chars)} chars vs {len(syl)} syllables"
    return "".join(f"{c}({s})" for c, s in zip(chars, syl))   # 长(zhang3)大(da4)

def synth(text):
    # request fields are illustrative; take the real ones from api_v2.py (verify)
    r = requests.post(f"{API}/tts", json={"text": text, "text_lang": "zh",
        "ref_audio_path": REF, "prompt_text": REF_TXT, "prompt_lang": "zh",
        "seed": 42, "speed_factor": 0.85,          # slower, child-directed speech (verify field)
        "media_type": "wav"}, timeout=120)
    r.raise_for_status(); return r.content

for row in csv.DictReader(open("words.csv", encoding="utf-8")):
    t0 = time.time()
    wav = synth(model_text(row["hanzi"], row["pinyin_override"]))
    pathlib.Path("raw.wav").write_bytes(wav)
    subprocess.run(["ffmpeg","-y","-i","raw.wav","-af","...","-ac","1","-ar","24000",
                    "-c:a","libmp3lame","-b:a","48k", f"out/{row['hanzi']}.mp3"], check=True)
    print(row["hanzi"], round(time.time()-t0, 1), "s")
```

## 5. Test plan

Run T-01 to T-12 in order. Record results in `~/zi-voice/tests/results.csv`.

### 5.1 Technical tests

| ID | Checks | Steps | Pass criteria |
|---|---|---|---|
| T-01 | Install succeeds | Section 3 steps 1-9 on a clean account/folder | Every "done when" met; install log has no unresolved errors; total download and disk use recorded |
| T-02 | Runs on MPS, not silent CPU | Watch startup log for device; in Python `next(model.parameters()).device` (or equivalent, verify); run Activity Monitor > GPU History during a long sentence | Device reported as `mps` and GPU activity visible during synthesis. If it falls back to CPU, record it, re-measure T-04 and mark "CPU only" |
| T-03 | Memory used | Activity Monitor (Memory tab) or `/usr/bin/time -l` on the batch script; note peak "Memory" and memory pressure | Peak recorded. Pass: memory pressure stays green/yellow, no swap growth beyond 2 GB on 16 GB Mac. 8 GB Mac: no red pressure |
| T-04 | Smoke | Generate `你好，我是小花。` and `猫` with the demo reference | Audio is intelligible Mandarin, no crash, no empty file, no English-sounding or garbled output |
| T-04b | Speed | Generate 20 words and 10 short sentences (6-12 characters); time each after a warm-up run | Median under about 10 s per word on Apple Silicon (excluding first model load); sentence time recorded. Above 30 s per word: fail |
| T-05 | Offline | Run `ls ~/.cache/huggingface` and the repo to note caches. Turn Wi-Fi off (and unplug Ethernet). Kill and restart the model server; generate 5 words. Optionally set `HF_HUB_OFFLINE=1` and `TRANSFORMERS_OFFLINE=1` | Same 5 words generate with the same quality; no hang waiting for network; no traceback about downloads. (If it tries to fetch something, list what and pre-download it.) Also confirm with `lsof -i -P \| grep python` during a run that only 127.0.0.1 connections exist |
| T-05a | Pinyin override works | Generate `长(zhang3)大(da4)` and `银(yin2)行(hang2)` and compare to the plain text; grep the code for `custom_pinyin` | The override changes the reading as intended, and the parentheses are not spoken. See 4. If fail: mark blocker, try fallbacks |

### 5.2 Tone accuracy test set (40 items)

Generate each once **without** override (first generation), then once with the pinyin override. Use the same reference voice and seed. Expected pinyin is what a standard Putonghua speaker would say (surface tones, i.e. after sandhi).

**A. Game P1 words (15)**

| # | Text | Expected pinyin | Note |
|---|---|---|---|
| 1 | 猫 | māo | 1st |
| 2 | 狗 | gǒu | 3rd |
| 3 | 鱼 | yú | 2nd |
| 4 | 鸟 | niǎo | 3rd |
| 5 | 花 | huā | 1st |
| 6 | 树 | shù | 4th |
| 7 | 水 | shuǐ | 3rd |
| 8 | 山 | shān | 1st |
| 9 | 书 | shū | 1st |
| 10 | 苹果 | píng guǒ | 2 + 3 |
| 11 | 香蕉 | xiāng jiāo | 1 + 1 |
| 12 | 米饭 | mǐ fàn | 3 + 4 |
| 13 | 学校 | xué xiào | 2 + 4 |
| 14 | 大象 | dà xiàng | 4 + 4 |
| 15 | 老师 | lǎo shī | 3 + 1 |

Spare P1 words to add if time permits: 牛 羊 马 火 雨 笔 手 车 蛋 家 (pull from the game's word list; check the exact list in `index.html`).

**B. Neutral tone (6)**

| # | Text | Expected |
|---|---|---|
| 16 | 妈妈 | mā ma |
| 17 | 爸爸 | bà ba |
| 18 | 月亮 | yuè liang |
| 19 | 星星 | xīng xing |
| 20 | 眼睛 | yǎn jing |
| 21 | 耳朵 | ěr duo |


**C. Third-tone sandhi (4)**

| # | Text | Expected (surface) |
|---|---|---|
| 22 | 你好 | ní hǎo |
| 23 | 老虎 | láo hǔ |
| 24 | 小雨 | xiáo yǔ |
| 25 | 五百 | wú bǎi (first 3rd tone becomes 2nd) |

**D. 一 and 不 sandhi (5)**

| # | Text | Expected |
|---|---|---|
| 26 | 一个 | yí ge |
| 27 | 一起 | yì qǐ |
| 28 | 一只猫 | yì zhī māo |
| 29 | 不是 | bú shì |
| 30 | 不好 | bù hǎo |

**E. Polyphones in context (10 or more)**

| # | Text | Expected | Contrast |
|---|---|---|---|
| 31 | 长大 | zhǎng dà | vs 32 |
| 32 | 很长 | hěn cháng | |
| 33 | 银行 | yín háng | vs 34 |
| 34 | 行走 | xíng zǒu | |
| 35 | 快乐 | kuài lè | vs 36 |
| 36 | 音乐 | yīn yuè | |
| 37 | 还有 | hái yǒu | vs 38 |
| 38 | 还书 | huán shū | |
| 39 | 很重要 | hěn zhòng yào | vs 40 |
| 40 | 重新 | chóng xīn | |
| 41 | 好人 | hǎo rén (好 hǎo) | vs 42 |
| 42 | 爱好 | ài hào (好 hào) | |
| 43 | 跑得快 | pǎo de kuài (得 de) | vs 44 |
| 44 | 得到 | dé dào (得 dé) | |
| 45 | 他看着我 | tā kàn zhe wǒ (着 zhe) | vs 46 |
| 46 | 睡着了 | shuì zháo le (着 zháo; 了 le) | |
| 47 | 好了 | hǎo le | vs 48 |
| 48 | 了解 | liǎo jiě | |
| 49 | 土地 | tǔ dì | vs 50 |
| 50 | 开心地笑 | kāi xīn de xiào (地 de) | |

That is about 50 items. If time is tight, run the first 41 in this order: A (15), B (6), C (4), D (5), E items 31-41 (11). The rest are a second round.

### 5.3 Scoring procedure

1. Generate all items (unlabelled files `001.mp3`... in random order). A helper script shuffles and writes the key (item to random ID) to `tests/key.csv`; the husband does not open the key.
2. The husband plays each file once (twice allowed) and, without seeing the expected pinyin, writes down what he hears (or marks the tone syllables) then checks against the key. Alternatively, he sees only the text and marks **correct / wrong** and, if wrong, the syllable.
3. One point per item: all syllables' tones and readings correct. Neutral tone must be light and short; a full 4th/1st tone on the second 妈 counts as wrong.
4. Also score naturalness 1-5 (1 robotic, 3 acceptable for a child's game, 5 human-like). Also flag artefacts: clipped start, clicks, repeats, hallucinated syllables.
5. Pass thresholds:
   - **First generation (no overrides): >= 90% correct overall** and **no failures on the 15 P1 words or the 6 neutral-tone words**. Polyphone misses at this stage are expected; overrides exist to fix them.
   - **After pinyin overrides: 100%** on every item, repeated twice (two seeds) to confirm stability.
   - Mean naturalness >= 3.5; no item below 2.
6. A second listener (the aunt, or another native speaker) samples 10 items as a cross-check; disagreements go to the husband's final call. Record a short reason for every wrong item (wrong tone, wrong reading, sandhi missed, neutral tone too strong).

| ID | Checks | Steps | Pass criteria |
|---|---|---|---|
| T-06 | Tone accuracy, first generation | 5.2 without overrides, 5.3 scoring | >= 90%, all P1 and neutral-tone words correct |
| T-07 | Tone accuracy with overrides | Re-run failures and all polyphones with `pinyin_override`; two seeds | 100% both runs |
| T-08 | Naturalness | 1-5 rating from 5.3 | Mean >= 3.5, none < 2 |

### 5.4 Output, integration and regression

| ID | Checks | Steps | Pass criteria |
|---|---|---|---|
| T-09 | Output format | `ffprobe` each file; `ffmpeg -i f.mp3 -af ebur128 -f null -` for loudness; `ls -l` | Named `<hanzi>.mp3`; mono; 24 kHz (or 44.1); loudness -16 LUFS +/-2 LU; word clip 0.4-2.0 s, sentence < 6 s; no leading silence over 0.15 s; word file < 15 KB, sentence < 60 KB; total for 500 words < 10 MB |
| T-10 | Device playback | AirDrop or host the files on the local network; play 10 files on iPhone Safari and Android Chrome (file served over HTTP from a laptop, or through the game) | Plays with no tap-to-unmute issues beyond normal autoplay rules, no distortion, similar volume on both, no clipped start |
| T-11 | Game import | Load MP3s into Zi Garden. **Dependency:** the game currently uploads one file per word, so a bulk import that maps `<hanzi>.mp3` to the word by file name needs to be built (or use the current one-by-one upload for the test, 5 words). The game stores recordings as Blobs in IndexedDB (database `zigarden`, store `audio`, keyed by word id), not in localStorage, so hundreds of small MP3s are fine. Backups embed them as data URLs, so a 500-word backup is roughly 5-10 MB of text | 5 words import and play in the game, falling back to browser TTS when a file is missing. Bulk import feature: tracked separately; not a go/no-go item for model setup but blocks the final rollout |
| T-12 | Regression on update | Keep `tests/baseline/` (MP3s from the passing run), the 50-item list, seeds, `gptsovits-commit.txt`, `pip freeze > logs/freeze-<date>.txt`. Before updating: `git pull` on a **copy** (`GPT-SoVITS-new`) with a new conda env. Re-run T-04b, T-06, T-07 blind, and compare duration and loudness per file to the baseline (flag > 20% duration change) | Same thresholds as first pass; no previously correct item now wrong. Otherwise stay on the old commit. Never update in place |

## 6. Risks and mitigations

| Risk | Impact | Mitigation |
|---|---|---|
| Tone or polyphone errors | Teaches a 6-year-old the wrong reading. Highest risk | Blind husband review of every generated file before it enters the game; pinyin overrides for all polyphones; keep the CSV of overrides under git; human sign-off on 100% of shipped words, not a sample |
| Neutral-tone and sandhi drift after updates | Silent regressions | T-12 baseline and blind re-test |
| Mac performance (8 GB or CPU fallback) | Slow batch or crash | Machine check branch; batch in chunks with resume via manifest; run overnight on a plugged-in Mac; else use a different machine |
| Pinyin override syntax unsupported in the installed commit | No fine control | Test T-05a first; patch PR #1728 or switch to CosyVoice 3 |
| Licences | Unclear terms for weights | GPT-SoVITS code is MIT; **weights licence unverified** (HF page was unreachable). Read the model card before use. F5-TTS weights are CC-BY-NC and Fish Speech is research-licence: fine for private family use, but do not redistribute audio publicly or sell the game with them without checking |
| Disk space | Install fails midway | Budget about 20-30 GB free: several GB pretrained models (measure in step 9), conda env 5-10 GB, PyTorch cache, output < 100 MB. Recheck with `du -sh ~/zi-voice ~/miniforge3` |
| Voice-data privacy | Aunt's recordings or a fine-tuned model leak or sync to cloud | Keep `~/zi-voice` outside iCloud Drive (do not use Desktop/Documents if iCloud "Desktop & Documents" sync is on); add to Time Machine exclusions or use an encrypted backup; disable Google Drive/Dropbox sync for the folder; store aunt's reference audio and fine-tuned weights only in `~/zi-voice/refs` (mode 700); FileVault on. No cloud TTS or transcription tool is ever used |
| Network exposure | Others on Wi-Fi use the server | Bind API to 127.0.0.1; macOS firewall on; stop the server when done |
| Misuse / deepfake | Cloned voice could be used to impersonate the aunt | Written consent from the aunt (what it's for, who holds the model, right to withdraw and have it deleted); use only for the game; do not publish the model or a general voice-generation service; keep the game audio non-interactive (fixed words only); watermark filenames/metadata (`comment=Zi Garden synthetic voice`); delete reference audio and weights on request |
| Supply chain | Malicious dependency or weights download | Pin commit and versions; download only from the official GitHub/HF/ModelScope pages linked above; review `install.sh` before running; avoid pickle-based weights from unknown sources |
| Reference-audio quality | Poor cloning later | Out of scope now; plan a separate recording session (quiet room, 30-60 s of clean speech) |

## 7. Go / no-go criteria for moving to the aunt's voice

Go only if ALL are true:

1. T-01 to T-05a pass on the family Mac (or on the machine chosen to do the batch), including MPS use and offline generation.
2. T-04b: median under about 10 s per word, and a 500-word batch completes in an overnight run without crashes.
3. T-06 >= 90% (all P1 and neutral-tone words correct) and T-07 100% on the 50-item set, verified blind.
4. Pinyin override works reliably for all polyphones in the set.
5. Output format passes T-09 and T-10; at least 5 files play in the game (T-11).
6. Licences read and recorded; privacy controls in section 6 in place; the aunt has given informed consent.
7. Regression baseline saved (T-12).

No-go or switch model if: overrides cannot be made to work, first-generation accuracy is below 90%, the machine cannot run the model (Intel, 8 GB thrash), or the weights licence forbids the intended use. In that case repeat sections 3-5 for CosyVoice 3.0 (about 1 extra day) before deciding on a different machine.

## 8. Time estimate (husband)

| Phase | Estimate |
|---|---|
| Machine check and branch decision | 15 min |
| Homebrew, ffmpeg, Miniforge, clone, install script, weight download (network dependent) | 1-2 h |
| First run, MPS check, API, smoke and offline tests | 1-2 h |
| Batch script with overrides and ffmpeg post-processing | 2-3 h |
| Build 50-item test set, generate, blind scoring | 2 h |
| Fix failures with overrides, re-test, format and device checks | 2-3 h |
| Game import test (5 words) | 1 h |
| Fallback (CosyVoice 3.0) if needed | +4-8 h |
| Bulk-import feature in the game (separate; Claude can build it) | not the husband's time |
| **Total for this plan (excluding fallback and bulk import)** | **about 1.5-2 working days** |

## Open items to verify before starting

- `speed_factor` (and `seed`) field names in `api_v2.py`.

- GPT-SoVITS pretrained weights licence (Hugging Face was blocked from the research environment).
- Whether the custom pinyin syntax from PR #1728 is merged and working in the current release.
- Recommended Python version, current entrypoint names (`webui.py`, `api_v2.py`) and API field names in the README.
- Real inference speed on MPS (README warns about Mac GPU quality for training, not necessarily inference).
- CosyVoice 3.0 on macOS, its pinyin syntax, and its weights licence.
- F5-TTS pinyin input and whether f5-tts-mlx handles Chinese at all.

## Review log (Opus review of the Sonnet draft)

Corrected:
- Test set: fixed the section B count (6 items) and removed 狗 from the spare list (already item 2). Replaced items whose expected answer was itself debatable: 我好爱你 (我好 also undergoes third-tone sandhi), 我得走了 (a chain of three third tones), 爱好画画 and 我慢慢地走 (the reduplicated second syllable varies between speakers). Replaced them with 好人, 爱好, 跑得快, 得到 and 开心地笑. Cleaned up the 五百 note.
- Thresholds: the first-generation pass mark is now 90% overall, with the P1 and neutral-tone words required to be correct. 95% would have failed the model for polyphone misses that the overrides exist to fix, and 90% now matches the no-go line in section 7.
- Batch design: pass the reference audio as an absolute path, because the API server resolves paths from its own folder. Added `speed_factor` for slower child-directed speech, following the family's feedback on the voice.
- The reference-clip length limit (about 3-10 s) is stated as a hard requirement, and the forced 32 kHz resample is dropped.
- Game facts: audio lives in IndexedDB as Blobs, not in localStorage.

Kept as the draft had it, after checking:
- GPT-SoVITS first and CosyVoice as the fallback. The deciding factor, a per-character pinyin override, is still unconfirmed for both, so T-05a stays the first real gate.
- conda (Miniforge), because the GPT-SoVITS installer expects it.
- The Intel Mac branch, which says to use another machine.

Still unverified: weights licences (Hugging Face was unreachable from the research environment), the entrypoint and API field names, MPS inference speed, and whether PR #1728 is merged.

