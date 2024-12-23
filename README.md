# dotfiles

My dotfiles, managed by chezmoi

## Install Chezmoi

> Install chezmoi and your dotfiles on a new machine with a single command
> chezmoi's install script can run chezmoi init for you by > passing extra arguments to the newly installed chezmoi binary. If your dotfiles repo is github.com/$GITHUB_USERNAME/dotfiles then installing chezmoi, running chezmoi init, and running chezmoi apply can be done in a single line of shell:

```shell
$ sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply $GITHUB_USERNAME
```

> If your dotfiles repo has a different name to dotfiles, or if you host your dotfiles on a different service, then see the reference manual for chezmoi init.

> For setting up transitory environments (e.g. short-lived Linux containers) you can install chezmoi, install your dotfiles, and then remove all traces of chezmoi, including the source directory and chezmoi's configuration directory, with a single command:

```shell
$ sh -c "$(curl -fsLS get.chezmoi.io)" -- init --one-shot 
```

 -- [Chezmoi Init (with my dotfiles)](https://www.chezmoi.io/user-guide/daily-operations/#install-chezmoi-and-your-dotfiles-on-a-new-machine-with-a-single-command)
