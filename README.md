# swedebtest

[![License: Unlicense](https://img.shields.io/badge/license-Unlicense-blue.svg)](http://unlicense.org/)
[![Bash](https://img.shields.io/badge/language-bash-green.svg)]()
[![Version](https://img.shields.io/badge/version-v2026.07.31-orange.svg)]()

Simple benchmark tool for Debian mirrors, with focus on Swedish mirrors.

## Features

- Compare multiple mirrors
- Measures ping, TTFB and download speed
- Ranks mirrors from best to worst
- Shows best overall and best Swedish mirror

## Usage

```bash
chmod +x swedebtest.sh
./swedebtest.sh
```

Optional:

```bash
./swedebtest.sh --runs 5
./swedebtest.sh --suite bookworm
```

## Example output

```
RANK SCORE HOST                           PING      TTFB      SPEED
1    780   deb.debian.org                 1.0 ms    0.016 s   84.76 MiB/s
```

## License

This project is released under The Unlicense.
