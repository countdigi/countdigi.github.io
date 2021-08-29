---
title: "Fuzzy cd for project dirs"
date: 2020-01-01
tags: ["bash", "fzf", "cli"]
draft: false
---

When working between projects, I realize that I almost always repeat the same few tasks including:

- Typing `cd <path>` to enter the project directory
- Typing `git fetch` or `git pull` to check/merge any changes upstream
- Typing `<Ctrl>-b ,` while in tmux to rename the window to the project name

By incorporating the wonderful command-line fuzzy finder [fzf](https://github.com/junegunn/fzf)
I wrote a small bash function called `cdp` to automate these steps.

The function is written for two levels under a common directory (e.g. `~/dev`) where
the first level is the github organization name and the second level is the repository.

From the command line, typing `cdp` will bring up a fuzzy-finder window with all organzations
and projects under your `~/dev` directory. You type characters until finally selecting
the project to cd into.  You can also give `cdp` a string as an argument to limit the paths listed at the beginning.

If your project is a git repo it will then run `git fetch` as well as
displaying verbose branch info compared to the upstream and the status of your working directory.

The latter half of the function only runs if you are in a tmux session. You can customize
the `rename_parent` and `rename_proj` bash arrays or leave as empty `()`. For example
in the code below `usf-hii/hii` will substitute the organization `usf-hii` with the shorter
string `hii` which will reduce the characters for the tmux window name.

---

Example:
```
$ cdp snp
```

Brings up a fuzzy finder menu:
```
> ./usf-hii/snptk
> ./usf-hii/snp-util
2/18
```

Adding the character `t` and hitting enter takes us to the `usf-hii/snptk` project,
fetches changes, shows us verbose branch info, short git status and sets the tmux window
name to `hii/snptk`.

In this example we have 2 commits ready to be pushed and one file with changes
not yet staged.

```
> snptk> git fetch --quiet (git@github.com:usf-hii/snptk.git)
* master 66cc97c [ahead 2] Fix snpid-from-coord output to delete file
 M tests/test_helper.py

countskm@jabba:~/dev/usf-hii/snptk (master * u+2)
$ # do your work now...
```

---

Here is the function if you would like to add it to your `~/.bashrc`:

```bash
cdp() {
    local levels=2
    local project_dir=~/dev

    local target_dir=$(
      cd ${project_dir}
      find . -maxdepth ${levels} -mindepth ${levels} -type d | fzf --query "$1"
    )

    cd "${project_dir}/${target_dir}"

    if [[ -d .git ]]; then
        printf '> git fetch --quiet (%s)\n' "$(git config --get remote.origin.url)";
        git fetch --quiet;
        git branch --verbose;
        git status --short;
    fi

    if [[ -n ${TMUX} ]]; then
      local rename_parent=(usf-hii/hii countdigi/digi)
      local rename_proj=(fac-parikhh/fp)
      local rename

      local parent_dir=$(basename "$(dirname "$(pwd)")")
      local proj_dir=$(basename "$(pwd)")

      for rename in ${rename_parent[@]}; do
        parent_dir=$(echo ${parent_dir} | sed "s/${rename}/")
      done

      for rename in ${rename_proj[@]}; do
        proj_dir=$(echo ${proj_dir} | sed "s/${rename}/")
      done

      tmux rename-window "${parent_dir}/${proj_dir}"
    fi
}
```
