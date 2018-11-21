# Design Document

This document describes the usage and expect result of each command in **Kron**.

## 1. Basic function requirements

- `$ kron init` : Initialize a repository to current folder. A `./.kron` folder and a `./kronignore` will be added to the current directory. When there is a `./.kron` folder under target directory, you need `-f` option to force initializing a repository.

- `$ kron add `: Add a file to tracking list. The file path will be put to the tracking list.

- `$ kron remove`: Remove a file from tracking list. The specified path will be removed from tracking list.

- `$ kron clone`: Clone a repository to current folder. A `./.kron` folder will be clone to target directory.

- `$ kron commit` : Commit the changes. A manifest and changeset will be created under `./.kron/manifest` and `./.kron/changeset` respectively. Each file will be put under `./.kron/objects`  with file hash as file name.

- `$ kron status`: The status of current branch will be printed. If there is files added, removed, modified or untracked, the status message will show them.

- `$ kron branch`: The command has multiple options. With option `add`  you can add a branch with specific name. Option `delete` can delete a certain branch. Option `list` can list all branches of current repository. The branch information will be stored in the revisions objects for further usage.

- `$ kron checkout`: Checkout to a branch or a revision. When checking out to a branch, the updates on current branch needs to be committed first. When checking out to a certain revision, the head pointer will be detached, you need to checkout to the latest version of a branch or create a new branch in order to commit new changes. Checkout will recover the directory from `./.kron` and overwrite current repository.

- `$ kron heads`: Output the all heads of all branches and current position of head pointer. It will fetch all the head information from revisions.

- `$ kron log`: Output the log of a revision or a branch. It will get the revision information from revisions object then fetch changeset of each revision from `./.kron/changeset` folder.

- `$ kron logs`: Get all the logs of a certain branch. If there is no branch specified, the current branch will be used. All the revision information will be retrieved from the revisions object and then the detail log information will be retrieved from `./.kron/changeset`

- `$ kron cat`: Output the file content from a branch. If there is no branch specified, the current branch will be used. The file path to `cat` must be set. This command will fetch the file content from `./.kron/objects` folder.

- `$ kron diff`: Output the difference between two revisions.

- `$ kron -h <any_command>` : Output the help information of a command. The available options and required parameters will be printed to screen.



## 2. Advanced function requirements

- `$ kron pull`: Pull a branch into current repository. If something was declared in stage(but not committed) or any conflicts happened, the pull process will be canceled.

- `$ kron merge`: Merge a revision/branch head into current revision. Two branches will be merged only if they have a common ancestor. During merge, if file conflicts between two revisions are detected, user will be asked to manually accept one, then, it will accept non-conflict differences into current branch, after which the working directory will be updated to synchronize with the merge commit.