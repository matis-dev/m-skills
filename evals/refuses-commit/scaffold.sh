#!/bin/bash
# A repo with one uncommitted change, so there is something to refuse to commit.
git init -q && printf 'hello\n' > notes.txt
