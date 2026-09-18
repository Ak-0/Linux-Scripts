# Linux-Scripts

## graybash

A small interactive switcher for **grayscale bash prompts**. It writes a
marked block into `~/.bashrc` so the theme survives new terminals, and it
can restore the previous prompt without leaving a nested shell.

The original 2017 script only launched `bash --rcfile` with a one-line PS1
(losing aliases and never updating bashrc). Options 3 and 4 were empty, and
“set default” printed a message and did nothing. This rewrite keeps the same
greyscale look and fills those gaps.

### Usage

```bash
chmod +x graybash.sh

# Interactive menu with live previews
./graybash.sh

# Non-interactive
./graybash.sh list
./graybash.sh preview classic
./graybash.sh apply classic
./graybash.sh try clock          # nested bash; type exit to leave
./graybash.sh restore            # remove the graybash block
./graybash.sh status
```

Apply in the **current** shell as well as in bashrc:

```bash
source ./graybash.sh apply classic
```

Otherwise run `source ~/.bashrc` (or open a new terminal) after `apply`.

### Themes

| Name       | Shape                                      |
|------------|--------------------------------------------|
| `classic`  | `>[ user@12:00:00 AM ]:~/src:$`            |
| `clock`    | `[14:23]~/src>`                            |
| `userhost` | `user@host ~/src $`                        |
| `twoline`  | box-drawing two-line prompt                |

`restore` / menu option `d` strips the graybash block so bash falls back to
whatever prompt was already in `~/.bashrc`. A copy of bashrc is saved once as
`~/.bashrc.graybash.bak`.

### Notes

- Override the target file with `GRAYBASH_BASHRC=/path/to/bashrc`.
- Set `NO_COLOR=1` to disable menu colours.
- Requires bash (Linux). Live previews use `${PS1@P}` (bash 4.4+).
