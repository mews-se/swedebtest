# swedebtest

[![License: Unlicense](https://img.shields.io/badge/license-Unlicense-blue.svg)](http://unlicense.org/)
[![ShellCheck](https://github.com/mews-se/swedebtest/actions/workflows/shellcheck.yml/badge.svg)](https://github.com/mews-se/swedebtest/actions/workflows/shellcheck.yml)
[![Bash](https://img.shields.io/badge/language-bash-green.svg)]()
[![Version](https://img.shields.io/badge/version-v2026.07.31-orange.svg)]()
[![Status: Deprecated](https://img.shields.io/badge/status-deprecated-red.svg)]()

> **⚠️ Deprecated:** This project has been superseded by
> **[geodebtest](https://github.com/mews-se/geodebtest)** and will be
> archived. geodebtest does everything swedebtest does, but works in any
> country: it autodetects your location, fetches the current official
> Debian mirror list (no hardcoded mirrors that go stale), and can apply
> the mirror you pick straight to your APT sources. No further updates
> will be made here.

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
