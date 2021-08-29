
---
title: "Readline and Fuzzy Finder"
date: 2021-08-26
tags: ["bash", "fzf", "readline", "cli"]
author: Kevin M. Counts
draft: false
---

In my bioinformatics work, I often find myself maintaining a text file with commands, options, and paths relevant to the tasks I am working on.
I have a workflow to yank a selection from this text file into an intermediate file and then use the `fc` builtin to copy the selection onto my command prompt.
This workflow works well but I wanted to improve it even more increasing efficiency.

After some experimentation I was inspired by the [fzf](https://github.com/junegunn/fzf) (Fuzzy Finder) project and it's use of [readline bindings](https://github.com/junegunn/fzf#key-bindings-for-command-line) for looking up your shell history. [Readline](https://en.wikipedia.org/wiki/GNU_Readline) is a GNU library providing line-editing capability for shells such as Bash.
It provides a mechanism to bind keystrokes to custom functions with which you can manipulate your shell's command line.

---

My idea was:
- Maintain a text file, `~/terms.txt`  with relevant commands, options, and paths
- Define a readline binding (e.g. `Ctrl-l`) which calls a custom function (e.g. `bind_terms()`)
- In the function use fzf to select the appropriate line from `~/terms.txt` I want to insert
- Modify the command line inserting the selected text

---

As I previously outlined, I picked the key sequence `Ctrl-l` to call a bash function called `bind_terms()`.

To achieve this, I added the following to my `~/.bashrc` configuration file:
```bash {linenos=false}
bind -x '"\C-l":bind_terms'
```

It took me a minute reading the readline manual and googling some examples to get the quotations correct.

---

Now all we need is to define a function which allows us to select the text and pass it back to readline:

```bash
bind_terms() {
  local fname=~/terms.txt
  local selected=$(cat ${fname} | fzf)
  READLINE_LINE="${READLINE_LINE:0:$READLINE_POINT}${selected}${READLINE_LINE:$READLINE_POINT}"
  READLINE_POINT=$(( READLINE_POINT + ${#selected} ))
}
```

Lets break this down line by line...

Line 2:
```bash {linenos=false}
local fname=~/terms.txt
```

We define the file which will contain the paths, command line invocations, etc. This can be in your `$HOME` or somewhere else under version control. BTW note we use the `local` keyword when defining the variable so it does not "leak" outside the function.

---

Line 3:

```bash {linenos=false}
local selected=$(cat ${fname} | fzf)
```

This is where we send the terms file into fuzzy finder so we can select what we want to paste into the command line.
The selected line will be copied into the variable `${selected}`.

---

Line 4:

```bash {linenos=false}
READLINE_LINE="${READLINE_LINE:0:$READLINE_POINT}${selected}${READLINE_LINE:$READLINE_POINT}"
```

This is the most complicated line.

Readline will have set 2 global variables when you invoke the binding (e.g. `Ctrl-l`):
- `${READLINE_LINE}` contains what was already on the command (empty if starting on a blank line)
- `${READLINE_POINT}` contains a number indicating where your cursor was (0 if starting on a blank line)

We are going to re-define these two global variables (using their current information) to manipulate the command line at the time of the binding invocation and paste our selected term at the appropriate point.

Lets imagine we typed the following on the command line:
`head | sort --version-sort`

Now we reposition the cursor to be on top of the pipe (`|`). We want to insert a filename right before this pipe so we type `Ctrl-l` invoking our binding.

Upon entering the function `bind_terms()`, `${READLINE_LINE}` will be set to `head | sort --version-sort` and `${READLINE_POINT}` will be set to `6`.

Fzf will fire up and lets imagine we select the term `/data/project-alpha/samples/XYZ123.csv` popping it into the variable `${selected}`.

We now edit the `${READLINE_LINE}` by revising it with 3 concatenated sections:
1. `${READLINE_LINE:0:$READLINE_POINT}` - Everything left of the cursor before invoking the binding
2. `${selected}` - The text to add
3. `${READLINE_LINE:${READLINE_POINT}` - Everything right of the cursor before invoking the binding

---

Line 5:
```bash {linenos=false}
READLINE_POINT=$(( READLINE_POINT + ${#selected} ))
```

Finally we want to put the cursor after the selected text we have added so update `${READLINE_POINT}` by adding the number of characters contained in `${selected}`.

---

The function exits and readline reads back the global variables `${READLINE_LINE}` and `${READLINE_POINT}` and the line now reads:

Before pressing Ctrl-l:
```bash {linenos=false}
head | sort --version-sort
     ^
     (cursor)
```

After pressing Ctrl-l and selecting term:
```bash {linenos=false}
head /data/project-alpha/samples/XYZ123.csv| sort --version-sort
                                           ^
                                           (cursor)
```
