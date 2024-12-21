# subcmd.sh

A simple subcommand dispatcher. Like how `git commit` runs `git-commit`

## Usage

```bash
$ alias mycmd="bin/subcmd.sh mycmd"
$ mycmd sub cmd -f whatever.txt
```

Will check for the following commands, and run them if they exist:

```bash
mycmd-sub-cmd -f whatever.txt
mycmd-sub cmd -f whatever.txt
mycmd sub cmd -f whatever.txt
```

## License

WTFPL with 1 additional clause: don't blame me.

